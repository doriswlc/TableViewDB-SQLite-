import UIKit
//定義單筆的學生資料結構
struct Student {
    var no = ""
    var name = ""
    var gender = 0
    var picture:Data?
    var phone = ""
    var address = ""
    var email = ""
    var myclass = ""
}

class MyTableViewController: UITableViewController {
    //紀錄單筆資料
    var structRow = Student()
    //宣告學生陣列，存放從資料庫查詢到的資料（此為離線資料集）
    var arrTable = [Student]()
    
    //MARK: - Target Action
    //由下拉更新元件所觸發的事件
    @objc func handleRefresh() {
        //設定下拉更新元件的文字
        self.tableView.refreshControl?.attributedTitle = NSAttributedString(string: "更新中...")
        //從資料庫讀取資料（to do）
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
        //準備離線資料集
        arrTable = [Student(no: "S101", name: "王大富", gender: 1, picture: UIImage(named: "default.jpg")?.jpegData(compressionQuality: 0.7), phone: "0800001234", address: "台北市新生北路一段121號", email: "abc@xyz.com", myclass: "手機程式設計"),Student(no: "S102", name: "李小英", gender: 0, picture: UIImage(named: "default.jpg")?.jpegData(compressionQuality: 0.7), phone: "0988123456", address: "宜蘭縣礁溪鄉健康路77號", email: "abc@xyz.com", myclass: "網頁程式設計"),Student(no: "S103", name: "吳天勝", gender: 1, picture: UIImage(named: "default.jpg")?.jpegData(compressionQuality: 0.7), phone: "0988123456", address: "台北市新生北路一段121號", email: "abc@xyz.com", myclass: "手機程式設計"),Student(no: "S104", name: "田麗莉", gender: 0, picture: UIImage(named: "default.jpg")?.jpegData(compressionQuality: 0.7), phone: "0988123456", address: "台北市新生北路一段121號", email: "abc@xyz.com", myclass: "網頁程式設計"),Student(no: "S105", name: "邱大同", gender: 1, picture: UIImage(named: "default.jpg")?.jpegData(compressionQuality: 0.7), phone: "0988123456", address: "台北市新生北路一段121號", email: "abc@xyz.com", myclass: "智能裝置開發")]
        
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
        cell.imgPicture.image = UIImage(data: arrTable[indexPath.row].picture!)
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
    //========<方法一>儲存格刪除（舊版）========
    //事件一：處理滑動刪除（或新增<--不建議）
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //Step1.先刪除資料庫中對應這個儲存格的資料(to do)
        //Step2.刪除離線資料集的資料
        arrTable.remove(at: indexPath.row)
        //Step3.刪除介面上的儲存格
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    //事件二：改刪除按鈕文字
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "不要了！"
    }
    //===============以上舊版結束===================
    
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
            //Step1.先刪除資料庫中對應這個儲存格的資料(to do)
            
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
