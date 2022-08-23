import UIKit

class MyCell: UITableViewCell
{
    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var lblNo: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblGender: UILabel!
    //當儲存格從StoryBoard被製作完成時
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
        //<方法二>在準備儲存格時給儲存格的預設大頭照樣式
        //給每一個儲存格預設大頭照
        
        self.imgPicture.image = UIImage(named: "default.jpg")
        //將大頭照取為正圓形（圓角為寬度或高度的一半）
        self.imgPicture.layer.cornerRadius = self.imgPicture.frame.size.height / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
