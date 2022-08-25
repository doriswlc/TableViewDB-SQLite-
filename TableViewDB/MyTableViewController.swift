import UIKit
import SQLite3
import AVFoundation
//定義單筆的學生資料結構
struct Student {
    var no = ""
    var name = ""
    var gender = 0
    var picture: Data?
    var phone = ""
    var address = ""
    var email = ""
    var myclass = ""
}

class MyTableViewController: UITableViewController {
    //記錄由C語言所開啟的資料庫指標
    private var db: OpaquePointer?
    //紀錄單筆資料
    var structRow = Student()
    //宣告學生陣列，存放從資料庫查詢到的資料（此為離線資料集）
    var arrTable = [Student]()
    //MARK: - 自定函式
    //查詢資料庫，存放在離線資料集
    func getDataFromTable() {
        //先清空離線資料集
        arrTable.removeAll()
        //準備查詢用的sql指令
        let sql = "select no,name,gender,picture,phone,address,email,myclass from student order by no"
        //將SQL指令轉換成C語言的字元陣列
        let cSql = sql.cString(using: .utf8)!
        //宣告儲存查詢結果的指標(連線資料集)
        var statement: OpaquePointer?
        //準備查詢(第三個參數若為正數則限定SQL指令的長度，若為負數則不限SQL指令的長度。第四個參數和第六個參數為預留參數，目前沒有作用。第五個參數會儲存SQL指令的執行結果。)
        if sqlite3_prepare_v3(db!, cSql, -1, 0, &statement, nil) == SQLITE_OK {
            print("資料庫查詢指令執行成功")
            //往下讀取一筆「連線陽料集」中的資料
            while sqlite3_step(statement!) == SQLITE_ROW {
                //讀取當筆資料的每一欄
                let no = sqlite3_column_text(statement!, 0)!
                let strNo = String(cString: no) //將C語言的字元陣列轉回String型別
                structRow.no = strNo
                
                let name = sqlite3_column_text(statement!, 1)!
                let strName = String(cString: name)
                structRow.name = strName
                
                let gender = Int(sqlite3_column_int(statement!, 2))
                structRow.gender = gender
                
                //準備當筆的圖檔資料
                var imgData: Data!
                //如果有讀到檔案的位元資料
                if let totalBytes = sqlite3_column_blob(statement!, 3) {
                    //讀取檔案長度
                    let fileLengeth = sqlite3_column_bytes(statement!, 3)
                    //檔案的位元資料和檔案長度，還原Data實體
                    imgData = Data(bytes: totalBytes, count: Int(fileLengeth))
                    //將大頭照欄位的Data記錄在當筆結構
                    structRow.picture = imgData
                    //注意：如果大頭照為nil，由準備每一個儲存格的代理事件來準備預設大頭照
                } else {    //如果沒有圖檔，則使用預設大頭照的圖檔
                    structRow.picture = UIImage(named: "default.jpg")?.jpegData(compressionQuality: 0.7)
                }
                structRow.phone = String(cString: sqlite3_column_text(statement!, 4))
                structRow.address = String(cString: sqlite3_column_text(statement!, 5))
                structRow.email = String(cString: sqlite3_column_text(statement!, 6))
                structRow.myclass = String(cString: sqlite3_column_text(statement, 7))
                //將整筆資料加入陣列(離線資料集
                arrTable.append(structRow)
            }
            //關閉連線資料集
            if statement != nil {
                sqlite3_finalize(statement)
            }
        } else {
            print("資料庫查詢指令執行失敗")
        }
    }
    
    //MARK: - Target Action
    //由下拉更新元件所觸發的事件
    @objc func handleRefresh() {
        //設定下拉更新元件的文字
        self.tableView.refreshControl?.attributedTitle = NSAttributedString(string: "更新中...")
        //從資料庫讀取資料(準備離線資料集) 注意：此處必須以私有佇列確定離線資料集已經完成更新，才能更新表格
        DispatchQueue(label: "data").sync {
            self.getDataFromTable()
        }
        //更新表格資料
        self.tableView.reloadData()
        
        //資料更新完成後將表格恢復原位置
        self.tableView.refreshControl?.endRefreshing()
    }
    //由導覽列『新增按鈕』所觸發的事件
    @objc func buttonAddAction(_ sender:UIBarButtonItem) {
        print("新增按鈕被按下")
        //從StoryBoard取得新增畫面
        if let addVC = self.storyboard?.instantiateViewController(withIdentifier: "AddViewController") as? AddViewController {
            //將資料傳遞到新增畫面
            addVC.myTableViewController = self
            //顯示新增畫面
            self.show(addVC, sender: nil)
        }
        
    }
    //由導覽列『編輯按鈕』所觸發的事件
    @objc func buttonEditAction(_ sender:UIBarButtonItem) {
        print("編輯按鈕被按下")
        //如果表格不是編輯中
        if !self.tableView.isEditing {
            //讓表格進入編輯狀態
            //self.isEditing = true
            self.tableView.isEditing = true
            //更改按鈕文字
            self.navigationItem.rightBarButtonItem?.title = "完成"
        } else {    //如果表格在編輯中
            //讓表格結束編輯狀態
            self.tableView.isEditing = false
            //更改按鈕文字
            self.navigationItem.rightBarButtonItem?.title = "編輯"
        }
    }
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        //取得App的db連線
        db = (UIApplication.shared.delegate as? AppDelegate)?.getDB()
        //準備離線資料集
        DispatchQueue(label: "data").sync {
            self.getDataFromTable()
            self.tableView.reloadData()
        }
        //arrTable = [Student(no: "S101", name: "王大富", gender: 1, picture: UIImage(named: "default.jpg")?.jpegData(compressionQuality: 0.7), phone: "0800001234", address: "台北市新生北路一段121號", email: "abc@xyz.com", myclass: "手機程式設計"),Student(no: "S102", name: "李小英", gender: 0, picture: UIImage(named: "default.jpg")?.jpegData(compressionQuality: 0.7), phone: "0988123456", address: "宜蘭縣礁溪鄉健康路77號", email: "abc@xyz.com", myclass: "網頁程式設計"),Student(no: "S103", name: "吳天勝", gender: 1, picture: UIImage(named: "default.jpg")?.jpegData(compressionQuality: 0.7), phone: "0988123456", address: "台北市新生北路一段121號", email: "abc@xyz.com", myclass: "手機程式設計"),Student(no: "S104", name: "田麗莉", gender: 0, picture: UIImage(named: "default.jpg")?.jpegData(compressionQuality: 0.7), phone: "0988123456", address: "台北市新生北路一段121號", email: "abc@xyz.com", myclass: "網頁程式設計"),Student(no: "S105", name: "邱大同", gender: 1, picture: UIImage(named: "default.jpg")?.jpegData(compressionQuality: 0.7), phone: "0988123456", address: "台北市新生北路一段121號", email: "abc@xyz.com", myclass: "智能裝置開發")]
        
        self.navigationItem.title =
        NSLocalizedString("navigationItem.title", tableName: "InfoPlist", bundle: Bundle.main, value: "", comment: "")
        //self.navigationItem.titleView = UIImageView(image: UIImage(systemName: "pencil.tip"))
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        //在導覽列右側設定編輯按鈕<方法一>自動切換
        //self.navigationItem.rightBarButtonItem = self.editButtonItem
        //在導覽列右側設定編輯按鈕<方法二>自行切換
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("edit", tableName: "InfoPlist", bundle: Bundle.main, value: "", comment: ""), style: .plain, target: self, action: #selector(buttonEditAction(_:)))
        
        //在導覽列左側設定新增按鈕
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("add", tableName: "InfoPlist", bundle: Bundle.main, value: "", comment: ""), style: .plain, target: self, action: #selector(buttonAddAction(_:)))
        //初始化下拉更新元件
        let refreshControl = UIRefreshControl()
        //下拉更新元件綁定valueChanged事件觸發handleRefresh函式
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        //將下拉更新元件設定給tableView
        self.tableView.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("畫面1出現")
        //由下一頁返回時，更新表格介面為新資料
        //self.tableView.reloadData()
    }

    // MARK: - Table view data source
    //表格有幾段
    override func numberOfSections(in tableView: UITableView) -> Int {
        //表格只有一段
        return 1
    }
    //每一段表格有幾列
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //回傳離線資料集的筆數
        return arrTable.count
    }

    //準備每一個位置的儲存格
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath) as! MyCell
        //<方法一>在準備儲存格時給儲存格的預設大頭照樣式
        //給每一個儲存格預設大頭照
        if let photoData = arrTable[indexPath.row].picture {
            cell.imgPicture.image = UIImage(data: photoData)
        }
        //將大頭照取為正圓形（圓角為寬度或高度的一半）
        //cell.imgPicture.layer.cornerRadius = cell.imgPicture.frame.size.height / 2
        
        cell.lblNo.text = arrTable[indexPath.row].no
        cell.lblName.text = arrTable[indexPath.row].name
        if arrTable[indexPath.row].gender == 0 {
            cell.lblGender.text = "女"
        } else {
            cell.lblGender.text = "男"
        }
        return cell
    }
    /*
    //設定表格區段的標題
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "這裡是Header"
    }
     */
    
    /*
    //設定表格區段的註腳
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "這裡是Footer"
    }
     */
 
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
     */
    
    //=============儲存格拖移相關作業=============
    //哪一個儲存格可以拖動
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        //允許所有儲存格都可以拖動
        return true
    }
    //儲存格拖移時
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("原位置：\(sourceIndexPath.row)，新位置：\(destinationIndexPath.row)")
        //Step1.調整資料表的順序（如果資料表有紀錄特定順序）
        
        //Step2.依照表格的順序調動陣列的順序
        //Step2_1.刪除原來位置的陣列元素
        //let tmp = arrTable[sourceIndexPath.row]
        //arrTable.remove(at: sourceIndexPath.row)
        let tmp = arrTable.remove(at: sourceIndexPath.row)
        //Step2_2.在新位置安插已經被刪除的元素
        arrTable.insert(tmp, at: destinationIndexPath.row)
    }
    //==========================================
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
     */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
     */
    
    // MARK: - Table View Delegate
    //========<方法二>儲存格刪除（新版）========
    //定義儲存格的右側按鈕（左滑觸發）
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        //產生第一個按鈕
        let buttonDelete = UIContextualAction(style: .normal, title: "刪除") { action, view, complete
            in
            print("刪除按鈕被按下！")
            //Step1.先刪除資料庫中對應這個儲存格的資料
            //準備刪除用的sql指令
            let sql = "delete from student where no=?"
            //將SQL指令轉換成C語言的字元陣列
            let cSql = sql.cString(using: .utf8)!
            //宣告儲存異動結果的指標
            var statement: OpaquePointer?
            //準備異動資料(第三個參數若為正數則限定SQL指令的長度，若為負數則不限SQL指令的長度。第四個參數和第六個參數為預留參數，目前沒有作用。第五個參數會儲存SQL指令的執行結果。)
            if sqlite3_prepare_v3(self.db!, cSql, -1, 0, &statement, nil) == SQLITE_OK {
                //準備要綁定到第一個問號的資料
                let no = self.arrTable[indexPath.row].no.cString(using: .utf8)!
                //將資料綁定到update指令<參數一>的第一個問號<參數二>，指定介面上的資料<參數三>，且不指定資料長度<參數四為負數>，參數五為預留參數。
                sqlite3_bind_text(statement, 1, no, -1, nil)
                
                //執行資料庫異動，如果執行不成功
                if sqlite3_step(statement!) != SQLITE_DONE {
                    //產生提示視窗
                    let alert = UIAlertController(title: "資料處理", message: "資料刪除失敗", preferredStyle: .alert)
                    //產生提示視窗內用的按鈕
                    let okAction = UIAlertAction(title: "確定", style: .destructive)
                    //將按鈕加入提示視窗
                    alert.addAction(okAction)
                    //顯示提示視窗
                    self.present(alert, animated: true)
                    //關閉連線資料集
                    if statement != nil {
                        sqlite3_finalize(statement)
                    }
                    //直接離開
                    return
                }
                //關閉連線資料集
                if statement != nil {
                    sqlite3_finalize(statement)
                }
            }
            
            //Step2.刪除離線資料集的資料
            self.arrTable.remove(at: indexPath.row)
            //Step3.刪除介面上的儲存格
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        //設定按鈕的背景色（可以隨深色模式和淺色模式調整的背景色）
        buttonDelete.backgroundColor = .systemBlue
        //產生第二個按鈕
        let buttonMore = UIContextualAction(style: .destructive, title: "更多") { action, view, complete in
            print("更多按鈕被按下！")
        }
        
        //組合要顯示的右側按鈕
        let config = UISwipeActionsConfiguration(actions: [buttonDelete,buttonMore])
        //設定重頭滑到尾會觸發第一個按鈕（預設值為true，如果不需要此功能，設定為false）
        //config.performsFirstActionWithFullSwipe = true
        //回傳按鈕組合
        return config
    }
    //處理右滑事件（未實作）
    //===============以上新版結束===================

    //哪一個儲存格被點選<儲存格被點選的第二事件>
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt:\(arrTable[indexPath.row])")
    }

    // MARK: - Navigation
    //即將由換頁線換頁<儲存格被點選的第一事件>
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //紀錄點選到的row和section
        let detailVC = segue.destination as! DetailViewController
        //通知第二頁第一頁的所在位置
        detailVC.myTableViewController = self
        //讓第二頁紀錄第一頁點選的索引值
        detailVC.currentRow = self.tableView.indexPathForSelectedRow!.row
    }
}
