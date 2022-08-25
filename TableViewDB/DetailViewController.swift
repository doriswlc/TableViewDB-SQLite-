import UIKit
import PhotosUI     //使用PHPickerViewController須引入此框架
import MapKit       //引入導航需要使用的framework
import SQLite3

class DetailViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,PHPickerViewControllerDelegate {
    @IBOutlet weak var lblNo: UILabel!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtGender: UITextField!
    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var txtAddress: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtMyclass: UITextField!
    //記錄由C語言所開啟的資料庫指標
    private var db: OpaquePointer?
    //接收上一頁的執行實體
    weak var myTableViewController:MyTableViewController!
    //紀錄目前處理中資料在離線資料集中的索引值
    var currentRow = 0
    //紀錄目前處理中的學生資料
    var currentData = Student()
    //提供性別滾輪以輸入資料
    var pkvGender:UIPickerView!
    //提供班別滾輪以輸入資料
    var pkvMyclass:UIPickerView!
    //提供性別滾輪可選取的資料陣列
    let arrGender = ["女","男"]
    //提供班別滾輪可選取的資料陣列
    let arrMyclass = ["手機程式設計","網頁程式設計","智能裝置開發"]
    //紀錄目前輸入元件的Y軸底緣位置
    var currentObjectBottomYPosition:CGFloat = 0
    
    
    //MARK: - Target Action
    //虛擬鍵盤的return鍵要可以收起鍵盤必須連結did end on exit事件
    @IBAction func didEndOnExit(_ sender: Any) {
        //不需實作按下return鍵即可收起鍵盤
    }
    //文字輸入框開始編輯時
    @IBAction func editingDidBegin(_ sender: UITextField) {
        switch sender.tag {
        //電話欄位編輯時
        case 4:
            //使用數字鍵盤
            sender.keyboardType = .numberPad
        //Email欄位編輯時
        case 6:
            sender.keyboardType = .emailAddress
        //其他欄位編輯時
        default:
        //使用預設鍵盤
            sender.keyboardType = .default
        }
        //紀錄Y軸底緣位置(輸入元件原點的Y軸位置＋輸入元件的高度)
        currentObjectBottomYPosition = sender.frame.origin.y+sender.frame.size.height
    }
    //底面的點擊事件
    @IBAction func viewOnClick(_ sender: UITapGestureRecognizer) {
        //讓搶去第一回應權的輸入物件收起鍵盤
        self.view.endEditing(true)
    }
    
    //由通知中心在鍵盤彈出時呼叫的函式
    @objc func keyboardWillShow(_ notification:Notification) {
        print("鍵盤彈出：\(notification.userInfo!)")
        
        //將上移的畫面回歸原點（此行程式若不執行，當在別的輸入元件鍵盤未收合時，直接跳至另一個輸入元件時，位置計算會有問題！）
        self.view.frame.origin.y = 0
        
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
            //計算扣除鍵盤遮擋範圍之後的剩餘"可視高度"
            let visiableHeight = self.view.bounds.height - keyboardHeight
            print("鍵盤高度：\(keyboardHeight)，可視高度：\(visiableHeight)")
            //計算被遮擋的部分，處理畫面的上移
            //如果可視高度小於輸入元件的Y軸底緣位置，表示輸入元件被鍵盤遮擋
            if visiableHeight < currentObjectBottomYPosition {
                //處理被遮擋部分的上移"Y軸底緣位置"和"可視高度"的差值
                self.view.frame.origin.y -= currentObjectBottomYPosition - visiableHeight
            }
        }
    }
    
    //由通知中心在鍵盤收合時呼叫的函式
    @objc func keyboardWillHide() {
        print("鍵盤收合！！！")
        //將上移的畫面回歸原點
        self.view.frame.origin.y = 0
    }
    //相機按鈕
    @IBAction func buttonCamera(_ sender: UIButton) {
        //當設備沒有支援相機功能時
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("無法使用相機")
            return
        }
        //宣告影像挑選控制器
        let imagePicker = UIImagePickerController()
        //影像挑選控制器設定為相機畫面
        imagePicker.sourceType = .camera
        //影像挑選控制器實作在此類別
        imagePicker.delegate = self
        //顯示相機畫面
        self.show(imagePicker, sender: nil)
    }
    //相簿按鈕
    @IBAction func buttonPhotoAlbum(_ sender: UIButton) {
        //初始化相簿相關的設定
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = PHPickerFilter.images
        config.preferredAssetRepresentationMode = .current
        config.selection = .ordered
        //設定可以多選照片（0不限張數，1為預設）
        //config.selectionLimit = 0
        //初始化照片挑選控制器
        let photoPicker = PHPickerViewController(configuration: config)
        photoPicker.delegate = self
        //顯示相簿
        self.show(photoPicker, sender: nil)
    }
    //打電話按鈕
    @IBAction func buttonPhoneCall(_ sender: UIButton) {
        if let phoneNumber = txtPhone.text {
            if let url = URL(string: "tel://\(phoneNumber)") {
                UIApplication.shared.open(url)
            }
        }
    }
    //導航按鈕
    @IBAction func buttonNavi(_ sender: UIButton) {
        //初始化地理資訊編碼器
        let geoCoder = CLGeocoder()
        //<#[CLPlacemark]?#>
        //讓地理資訊編碼器將地址轉換成經緯度
        geoCoder.geocodeAddressString(txtAddress.text!) { placemarks, error in
            //如果地址編碼失敗
            guard error == nil
            else {
                //print("地址錯誤！")
                //產生提示視窗
                let alert = UIAlertController(title: "轉換問題", message: "地址錯誤！", preferredStyle: .alert)
                //產生提示視窗內用的按鈕
                let okAction = UIAlertAction(title: "確定", style: .destructive)
                //將按鈕加入提示視窗
                alert.addAction(okAction)
                //顯示提示視窗
                self.present(alert, animated: true)
                //離開函式
                return
            }
            //如果轉換經緯度失敗
            guard placemarks != nil
            else {
                //print("地址轉換經緯度失敗！")
                //產生提示視窗
                let alert = UIAlertController(title: "轉換問題", message: "地址轉換經緯度失敗！", preferredStyle: .alert)
                //產生提示視窗內用的按鈕
                let okAction = UIAlertAction(title: "確定", style: .destructive)
                //將按鈕加入提示視窗
                alert.addAction(okAction)
                //顯示提示視窗
                self.present(alert, animated: true)
                //離開函式
                return
            }
            //print("編碼完成")
            //當回傳的經緯度不是空陣列時
            if !placemarks!.isEmpty {
                //Step1.取得(第一層)由地址轉換而成的經緯度位置標示
                let toPlacemark = placemarks!.first!
                
                //Step2.(第二層)將第一層的經緯度位置標示轉換成地圖上的位置標示
                let toPin = MKPlacemark(placemark: toPlacemark)
                print("經度：\(toPin.coordinate.longitude)，緯度：\(toPin.coordinate.latitude)")
                
                //Step3.(第三層)產生導航地圖上導航終點的大頭針
                let destMapItem = MKMapItem(placemark: toPin)
                
                //Step4.開啟導航地圖
                //Step4_1.設定以開車模式導航
                let option = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                //Step4_2.以導航終點的大頭針來開啟導航地圖（從目前位置導航）
                destMapItem.openInMaps(launchOptions: option)
            } else {
                //print("沒有取得導航用的經緯度")
                //產生提示視窗
                let alert = UIAlertController(title: "轉換問題", message: "沒有取得導航用的經緯度！", preferredStyle: .alert)
                //產生提示視窗內用的按鈕
                let okAction = UIAlertAction(title: "確定", style: .destructive)
                //將按鈕加入提示視窗
                alert.addAction(okAction)
                //顯示提示視窗
                self.present(alert, animated: true)
            }
        }
    }
    //修改資料按鈕
    @IBAction func buttonUpdate(_ sender: UIButton) {
        //Step1.更新資料庫資料
        //準備修改用的sql指令
        let sql = "update student set name=?,gender=?,picture=?,phone=?,address=?,email=?,myclass=? where no=?"
        //將SQL指令轉換成C語言的字元陣列
        let cSql = sql.cString(using: .utf8)!
        //宣告儲存異動結果的指標
        var statement: OpaquePointer?
        //準備異動資料(第三個參數若為正數則限定SQL指令的長度，若為負數則不限SQL指令的長度。第四個參數和第六個參數為預留參數，目前沒有作用。第五個參數會儲存SQL指令的執行結果。)
        if sqlite3_prepare_v3(db!, cSql, -1, 0, &statement, nil) == SQLITE_OK {
            //準備要綁定到第一個問號的資料
            let name = txtName.text!.cString(using: .utf8)!
            //將資料綁定到update指令<參數一>的第一個問號<參數二>，指定介面上的資料<參數三>，且不指定資料長度<參數四為負數>，參數五為預留參數。
            sqlite3_bind_text(statement, 1, name, -1, nil)
            
            //準備要綁定到第二個問號的資料
            let gender = pkvGender.selectedRow(inComponent: 0)
            //將資料綁定到update指令<參數一>的第二個問號<參數二>，指定介面上的資料<參數三>
            sqlite3_bind_int(statement, 2, Int32(gender))
            
            //準備要綁定到第三個問號的資料
            let imgData = imgPicture.image!.jpegData(compressionQuality: 0.7)!
            //將資料綁定到update指令<參數一>的第三個問號<參數二>，指定介面上圖檔的位元資料<參數三>，以及檔案長度<參數四>，參數五為預留參數。
            sqlite3_bind_blob(statement, 3, (imgData as NSData).bytes, Int32(imgData.count), nil)
            
            //準備要綁定到第四個問號的資料
            let phone = txtPhone.text!.cString(using: .utf8)!
            //將資料綁定到update指令<參數一>的第四個問號<參數二>，指定介面上的資料<參數三>，且不指定資料長度<參數四為負數>，參數五為預留參數。
            sqlite3_bind_text(statement, 4, phone, -1, nil)
            
            //準備要綁定到第五個問號的資料
            let address = txtAddress.text!.cString(using: .utf8)!
            //將資料綁定到update指令<參數一>的第五個問號<參數二>，指定介面上的資料<參數三>，且不指定資料長度<參數四為負數>，參數五為預留參數。
            sqlite3_bind_text(statement, 5, address, -1, nil)
            
            //準備要綁定到第六個問號的資料
            let email = txtEmail.text!.cString(using: .utf8)!
            //將資料綁定到update指令<參數一>的第六個問號<參數二>，指定介面上的資料<參數三>，且不指定資料長度<參數四為負數>，參數五為預留參數。
            sqlite3_bind_text(statement, 6, email, -1, nil)
            
            //準備要綁定到第七個問號的資料
            let myclass = txtMyclass.text!.cString(using: .utf8)!
            //將資料綁定到update指令<參數一>的第七個問號<參數二>，指定介面上的資料<參數三>，且不指定資料長度<參數四為負數>，參數五為預留參數。
            sqlite3_bind_text(statement, 7, myclass, -1, nil)
            
            //準備要綁定到第八個問號的資料
            let no = lblNo.text!.cString(using: .utf8)!
            //將資料綁定到update指令<參數一>的第八個問號<參數二>，指定介面上的資料<參數三>，且不指定資料長度<參數四為負數>，參數五為預留參數。
            sqlite3_bind_text(statement, 8, no, -1, nil)
            
            //執行資料庫異動，如果執行不成功
            if sqlite3_step(statement!) != SQLITE_DONE {
                //產生提示視窗
                let alert = UIAlertController(title: "資料處理", message: "資料更新失敗", preferredStyle: .alert)
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
        //Step2.更新上一頁的離線資料集對應的當筆資料
        myTableViewController.arrTable[currentRow] = Student(no: lblNo.text!, name: txtName.text!, gender: pkvGender.selectedRow(inComponent: 0), picture: imgPicture.image!.jpegData(compressionQuality: 0.7), phone: txtPhone.text!, address: txtAddress.text!, email: txtEmail.text!, myclass: txtMyclass.text!)
        //Step3.直接更新上一頁的表格資料
        myTableViewController.tableView.reloadData()
        //print("上一頁離線資料集對應的當筆資料：\(myTableViewController.arrTable[currentRow])")
        //Step4.通知使用者資料更新成功
        //產生提示視窗
        let alert = UIAlertController(title: "資料處理", message: "資料更新成功", preferredStyle: .alert)
        //產生提示視窗內用的按鈕
        let okAction = UIAlertAction(title: "確定", style: .default)
        //將按鈕加入提示視窗
        alert.addAction(okAction)
        //顯示提示視窗
        self.present(alert, animated: true)
    }
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        //取得App的db連線
        db = (UIApplication.shared.delegate as? AppDelegate)?.getDB()
        //抄錄一份上一頁離線資料集中的當筆資料
        currentData = myTableViewController.arrTable[currentRow]
        //將資料顯示在介面上
        lblNo.text = currentData.no
        txtName.text = currentData.name
        if currentData.gender == 0 {
            txtGender.text = "女"
        } else {
            txtGender.text = "男"
        }
        
        if let dataPicture = currentData.picture {
            imgPicture.image = UIImage(data: dataPicture)
        }
        
        txtPhone.text = currentData.phone
        txtAddress.text = currentData.address
        txtEmail.text = currentData.email
        txtMyclass.text = currentData.myclass
        
        //準備性別的滾輪
        pkvGender = UIPickerView()
        pkvGender.tag = 2      //此處的tag編碼與性別的textField的tag編碼相同
        pkvGender.dataSource = self
        pkvGender.delegate = self
        //將性別輸入欄位的鍵盤替換為性別滾輪
        txtGender.inputView = pkvGender
        //選定目前所在的性別滾輪
        pkvGender.selectRow(currentData.gender, inComponent: 0, animated: false)
        
        //準備班別的滾輪
        pkvMyclass = UIPickerView()
        pkvMyclass.tag = 7
        //此處的tag編碼與班別的textField的tag編碼相同
        pkvMyclass.dataSource = self
        pkvMyclass.delegate = self
        //將班別輸入欄位的鍵盤替換為班別滾輪
        txtMyclass.inputView = pkvMyclass
        //比對班別陣列中符合現在班別的索引值
        for (index,item) in arrMyclass.enumerated() {
            if item == txtMyclass.text {
                //比對班別符合時，以陣列索引值選定滾輪
                pkvMyclass.selectRow(index, inComponent: 0, animated: false)
                break   //直接離開迴圈
            }
        }
        //取得此App通知中心的實體
        let notificationCenter = NotificationCenter.default
        //註冊虛擬鍵盤彈出通知
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        //註冊虛擬鍵盤收合通知
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //MARK: - UIPickerViewDataSource
    //滾輪有幾段
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        //滾輪只有一段
        return 1
    }
    //每一段滾輪有幾資料
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        //性別滾輪
        case 2:
            return arrGender.count
        //班別滾輪
        case 7:
            return arrMyclass.count
        default:
            return 1
        }
    }

    //MARK: - UIPickerViewDelegate
    //準備每一個位置的滾輪資料
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        //性別滾輪
        case 2:
            return arrGender[row]
        //班別滾輪
        case 7:
            return arrMyclass[row]
        default:
            return "X"
        }
    }
    //滾輪滾動到特定位置時
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        //性別滾輪
        case 2:
            txtGender.text = arrGender[row]
        //班別滾輪
        case 7:
            txtMyclass.text = arrMyclass[row]
        default:
            break
        }
    }
    
    //MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //print("相機info：\(info)")
        if let image = info[.originalImage] as? UIImage {
            //直接顯示拍攝的大頭照
            imgPicture.image = image
            //退掉相機畫面（注意:無法使用pop退掉相機畫面）
            picker.dismiss(animated: true)
        }
    }
    
    //MARK: - PHPickerViewControllerDelegate
    //從相簿挑選相片完成時
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        print("挑選到的照片：\(results)")
        if let itemProvider = results.first?.itemProvider {
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error
                    in
                    guard let photoData = data
                    else { return }
                    //轉回主要執行緒更新畫面
                    DispatchQueue.main.async {
                    //顯示選取的相片
                    self.imgPicture.image = UIImage(data: photoData)
                    }
                }
            }
        }
        //退掉相簿畫面（注意:無法使用dismiss退掉相簿畫面）
        self.navigationController?.popViewController(animated: true)
    }
}
