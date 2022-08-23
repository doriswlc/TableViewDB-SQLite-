import UIKit

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    private let cities = ["台北","台中","高雄"]
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    //即將由換頁線換頁<儲存格被點選的第一事件>
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //紀錄點選到的row和section
        let indexPath = self.tableView.indexPathForSelectedRow!
        let city = cities[indexPath.row]
        print("prepare for segue:\(city)")
    }
    
    //MARK: - UITableViewDataSource
    //表格有幾段
    func numberOfSections(in tableView: UITableView) -> Int {
        //表格只有一段
        return 1
    }
    //每一段表格有幾列
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("詢問第\(section)段表格有幾列")
        switch section {
            case 0:
                return cities.count
            default:
                return 1
        }
    }
    //準備每一個位置的儲存格
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("詢問儲存格位於Section:\(indexPath.section)，Row:\(indexPath.row)")
        
        //let cell = self.tableView.dequeueReusableCell(withIdentifier: "MyCell")!
        //以儲存格ID來準備儲存格
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath)
        //填寫儲存格主要內容
        cell.textLabel?.text = cities[indexPath.row]
        //製作儲存格圖片
        cell.imageView?.image = UIImage(systemName: "pencil.circle")
        //填寫儲存格附屬內容
        cell.detailTextLabel?.text = "詳細說明\(indexPath.row+1)"
        //回傳儲存格
        return cell
    }

    //MARK: - UITableViewDelegate
    //哪一個儲存格被點選<儲存格被點選的第二事件>
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt:\(cities[indexPath.row])")
    }
}

