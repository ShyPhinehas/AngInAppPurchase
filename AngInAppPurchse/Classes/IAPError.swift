
import Foundation

public enum IAPError: Error{
    
    public enum ReceiptError: Int {
        case noError = 0
        case e21000 = 21000
        case e21002 = 21002
        case e21003 = 21003
        case e21004 = 21004
        case e21005 = 21005
        case e21006 = 21006
        case e21007 = 21007
        case e21008 = 21008
        case e21010 = 21010
        case etc = -1
        case noPurchasedProduct = 1
        
        public var desc: String{
            switch self {
            case .noError:
                return ""
            case .noPurchasedProduct:
                return "there are no purchased products"
            case .e21000:
                return "The App Store could not read the JSON object you provided."
            case .e21002:
                return "The data in the receipt-data property was malformed or missing."
            case .e21003:
                return "The receipt could not be authenticated."
            case .e21004:
                return "The receipt server is not currently available."
            case .e21005:
                return "This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response.Only returned for iOS 6 style transaction receipts for auto-renewable subscriptions."
            case .e21006:
                return "This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead."
            case .e21007:
                return "This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead."
            case .e21008:
                return "This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead."
            case .e21010:
                return "This receipt could not be authorized. Treat this the same as if a purchase was never made."
            case .etc:
                return "Internal data access error."
            }
        }
        
        public var isNoError: Bool{
            return self == .noError
        }
    }
    
    case product_code_error
    case user_prevent_iap
    case not_exist_productid
    case restore_erroretc(errorDesc: String?)
    case purchase_error_etc(errorDesc: String?)
    case receipt_error(reason: ReceiptError)
    
    public var desc: String{
        switch self {
        case .product_code_error:
            return "product_code_error"
        case .user_prevent_iap:
            return "user_prevent_iap"
        case .not_exist_productid:
            return "not_exist_productid"
        case .restore_erroretc(let errorDesc):
            return errorDesc ?? "restore_erroretc"
        case .purchase_error_etc(let errorDesc):
            return errorDesc ?? "purchase_error_etc"
        case .receipt_error(let reason):
            return reason.desc
        }
    }
}
