import UIKit
import SQLite3  //匯入C語言撰寫的SQLite函式庫
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    //紀錄資料庫所在路徑
    private var path: String?
    //紀錄由C語言所開啟的資料庫指標
    private var db:OpaquePointer?
    //提供其他頁面取得資料庫連線的方法
    func getDB() -> OpaquePointer {
        return db!
    }
    //應用程式啟動完成時
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //取得來源資料庫在使用者設備中捆包的路徑
        let sourceDB = Bundle.main.path(forResource: "mydb", ofType: "sqlite3")!
        
        print("資料庫來源路徑：\(sourceDB)")
        print("App的家目錄：\(NSHomeDirectory())")
        //準備App中可讀可寫的目的地資料庫路徑
        let destinationDB = NSHomeDirectory() + "/Documents/mydb.sqlite3"
        //檢查目的地資料庫路徑是否"不存在"
        if !FileManager.default.fileExists(atPath: destinationDB) {
            //從來源資料庫將DB拷貝一份到目的地資料庫
            try! FileManager.default.copyItem(atPath: sourceDB, toPath: destinationDB)
        }
        //開啟資料庫連線，並且將連線存入db所在的記憶體位置
        if sqlite3_open(destinationDB, &db) == SQLITE_OK {
            print("資料連線成功")
        } else {
            print("資料連線失敗")
        }
        return true
    }
    //應用程式結束時
    func applicationWillTerminate(_ application: UIApplication) {
        if db != nil {
            //關閉資料庫連線
            sqlite3_close(db!)
        }
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
