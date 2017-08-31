
import UIKit
import StoreKit

extension SKProduct{
    public var priceString: String {
        return (self.priceLocale.currencyCode ?? "") + " " + "\(self.price)"
    }
}

extension Date{
    public var isExpired: Bool{
        return self < Date()
    }
    
    public func toString(format: String = "yyyy-MM-dd HH:mm:ss VV") -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: self)
    }
}

extension String{
    public var dateWithReceiptFormat: Date?{
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
        return dateFormat.date(from: self)
    }
}


//extension UIView{
//    public func toast(_ str: String){
//        let width = self.bounds.size.width / 3.0
//        let height = width / 2.0
//        let toastview = UILabel(frame: CGRect(origin: CGPoint(), size: CGSize(width: width, height: height)))
//        toastview.layer.cornerRadius = 5
//        toastview.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
//        toastview.alpha = 0
//
//        self.addSubview(toastview)
//    }
//}
