
import UIKit

public struct PendingRenewalInfo{
    
    public enum AutoRenewStatus : String{
        case will_renew = "1"
        case customer_turned_off_automatic_renewal = "0"
        case unknown = "5"
        
        public var desc: String{
            switch self {
            case .will_renew:
                return "Subscription will renew at the end of the current subscription period."
            case .customer_turned_off_automatic_renewal:
                return "Customer has turned off automatic renewal for their subscription."
            case .unknown:
                return "unknown"
            }
        }
    }
    
    public enum SubscriptionExpirationIntent : String{
        case customer_canceled = "1"
        case billing_error = "2"
        case customer_canceled_not_agree_price_increas = "3"
        case not_available_at_time_enewal = "4"
        case unknown = "5"
        
        public var desc: String{
            switch self {
            case .customer_canceled:
                return "Customer canceled their subscription."
            case .billing_error:
                return "Billing error; for example customer’s payment information was no longer valid."
            case .customer_canceled_not_agree_price_increas:
                return "Customer did not agree to a recent price increase."
            case .not_available_at_time_enewal:
                return "Product was not available for purchase at the time of renewal"
            case .unknown:
                return "unknown"
            }
        }
    }
    
    public enum SubscriptionRetryFlag : String{
        case still_attempting = "1"
        case stopped_attempting = "0"
        case unknown = "5"
        
        public var desc: String{
            switch self {
            case .still_attempting:
                return "App Store is still attempting to renew the subscription."
            case .stopped_attempting:
                return "App Store has stopped attempting to renew the subscription."
            case .unknown:
                return "unknown"
            }
        }
    }
    
    
    public var auto_renew_status: AutoRenewStatus
    public var expiration_intent: SubscriptionExpirationIntent
    public var is_in_billing_retry_period: SubscriptionRetryFlag
}


public struct PurchasedProdcutInfo{
    public var is_trial_period: String?
    public var expires_date: Date?
    public var original_purchase_date: Date
    public var purchase_date: Date
    public var original_transaction_id: String
    public var transaction_id: String
    public var product_id: String
    public var isCanceled: Bool
    public var pendingRenewalInfo: PendingRenewalInfo?
    
    init?(jsonData: NSDictionary?) {
        guard let jd = jsonData else {
            return nil
        }
        
        let is_trial_period = jd.object(forKey: "is_trial_period") as? String
        let expires_date: Date? = (jd.object(forKey: "expires_date") as? String)?.dateWithReceiptFormat
        let original_purchase_date_str = jd.object(forKey: "original_purchase_date") as? String
        let purchase_date_str = jd.object(forKey: "purchase_date") as? String
        let original_transaction_id = jd.object(forKey: "original_transaction_id") as? String
        let transaction_id = jd.object(forKey: "transaction_id") as? String
        let product_id = jd.object(forKey: "product_id") as? String
        let cancellation_date = jd.object(forKey: "cancellation_date")
        let isCanceled : Bool = {
            if let _ = cancellation_date{
                return true
            }
            return false
        }()
        
        if let _ = original_purchase_date_str, let _ = purchase_date_str, let _ = original_transaction_id, let _ = transaction_id, let _ = product_id{
            
            let original_purchase_date = original_purchase_date_str!.dateWithReceiptFormat!
            let purchase_date = purchase_date_str!.dateWithReceiptFormat!
            
            self.is_trial_period = is_trial_period
            self.expires_date = expires_date
            self.original_purchase_date = original_purchase_date
            self.purchase_date = purchase_date
            self.original_transaction_id = original_transaction_id!
            self.transaction_id = transaction_id!
            self.product_id = product_id!
            self.isCanceled = isCanceled
            
        }else{
            return nil
        }
    }
    
    public var isExistTrial: Bool{
        if let itp = is_trial_period{
            return itp == "true"
        }
        return false
    }
    
    public var is_auto_renewable_subscriptions: Bool{
        if let _ = expires_date{
            return true
        }
        return false
    }
}
