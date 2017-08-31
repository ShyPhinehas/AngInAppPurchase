
import UIKit
import StoreKit

public enum ValidateReciepMode{
    case development
    case release
    
    public var URL_Str : String {
        switch self {
        case .development:
            return "https://sandbox.itunes.apple.com/verifyReceipt"
        case .release:
            return "https://buy.itunes.apple.com/verifyReceipt"
        }
    }
}

open class IAP: NSObject {
    
    public var validateReciepMode: ValidateReciepMode = .development
    
    public typealias RequestProductsCompletied = (_ success: Bool,_ error:IAPError?) -> Void
    public typealias PurchaseCompleted = (_ success : Bool,_ transaction_id : String?, _ errorDesc : IAPError?) -> Void
    public typealias RestoreCompleted = (_ success : Bool,_ transaction_ids : [String]?, _ errorDesc : IAPError?) -> Void
    public typealias ReceiptInfoCallback = (_ subscriptionInfo: [String : PurchasedProdcutInfo]? ,_ error: IAPError?) -> Swift.Void

    open static let helper: IAP = {
        let instance = IAP()
        SKPaymentQueue.default().add(instance)
        return instance
    }()
    
    public var products = [String : SKProduct]()
    fileprivate var requestProductsCompletied: RequestProductsCompletied?    /*초기에 상품정포를 가져왔을 때 호출되는 클로져*/
    fileprivate var purchaseCompleted: PurchaseCompleted?
    fileprivate var restoreCompleted: RestoreCompleted?
    fileprivate var receiptInfoCallback: ReceiptInfoCallback?
    fileprivate var isNeedRefreshingReceipt = false     /*영수증 초기화가 필요함을 알려줌*/
    
    public var shared_Secret: String?

    public func requestProductsWithCompletionHandler(productIdentifiers: NSSet, _ handler: @escaping RequestProductsCompletied){
        
        guard let pi = productIdentifiers as? Set<String> else{
            handler(false,IAPError.product_code_error)
            return
        }
        
        requestProductsCompletied = handler
        let productsRequest = SKProductsRequest(productIdentifiers: pi)
        productsRequest.delegate = self
        productsRequest.start()
    }
    
    public func purchase(withProductID productIDString: String, completed: PurchaseCompleted?) {
        
        guard SKPaymentQueue.canMakePayments() else {
            completed?(false, productIDString, .user_prevent_iap)
            return
        }
        
        guard let product: SKProduct = products[productIDString] else {
            completed?(false, productIDString, .not_exist_productid)
            return
        }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        self.purchaseCompleted = completed
    }
    
    public func restore(completed: RestoreCompleted? = nil) {
        restoreCompleted = completed
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
  
}

extension IAP: SKProductsRequestDelegate {
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse){
        for product in response.products {
            products[product.productIdentifier] = product
        }
        
        print("self.products \(self.products)")
        
        requestProductsCompletied?(true,nil)
        requestProductsCompletied = nil
    }
    
    public func requestDidFinish(_ request: SKRequest){
        if self.isNeedRefreshingReceipt{
            self.isNeedRefreshingReceipt = false
            self.receiptValidation(completd: self.receiptInfoCallback)
        }
    }
}

extension IAP: SKPaymentTransactionObserver{
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]){
        for transaction in transactions{
            
            switch (transaction.transactionState){
            case .purchased:
                print("updatedTransactions state is Purchased \(transaction.payment.productIdentifier)")
                purchaseCompleteTransaction(transaction)
                break
            case .failed:
                print("updatedTransactions state is Failed")
                failedTransaction(transaction)
                break
            case .restored:
                print("updatedTransactions state is Restored")
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            case .deferred:
                print("updatedTransactions state is Deferred")
                break
            case .purchasing:
                print("updatedTransactions state is Purchasing")
                break
            }
        }
    }

    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error){
        print("restoreCompletedTransactionsFailedWithError")
        
        self.restoreCompleted?(false, nil, .restore_erroretc(errorDesc: error.localizedDescription))
        self.restoreCompleted = nil
        
        for transaction in queue.transactions{
            SKPaymentQueue.default().finishTransaction(transaction)
        }
    }

    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue){
        print("paymentQueueRestoreCompletedTransactionsFinished")
        
        var restoredProductIds = [String]()
        
        for transaction in queue.transactions{
            let id = transaction.payment.productIdentifier
            if restoredProductIds.index(of: id) == nil{
                restoredProductIds.append(id)
            }
            SKPaymentQueue.default().finishTransaction(transaction)
        }
        
        self.restoreCompleted?(true, restoredProductIds, nil)
        self.restoreCompleted = nil
    }
    
    func purchaseCompleteTransaction(_ transaction : SKPaymentTransaction){
        self.purchaseCompleted?(true, transaction.payment.productIdentifier, nil)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func failedTransaction(_ transaction: SKPaymentTransaction){
        purchaseCompleted?(false,nil, .purchase_error_etc(errorDesc: transaction.error?.localizedDescription))
        purchaseCompleted = nil
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
}

extension IAP{
    
    public func receiptValidation(completd: ReceiptInfoCallback? = nil) {
        
        guard let shared_Secret = self.shared_Secret else {
            fatalError("must set shared_Secret code")
        }
        
        if let recepipUrl = Bundle.main.appStoreReceiptURL , let receiptData = try? Data(contentsOf: recepipUrl) {
            
            let receiptDictionary = ["receipt-data" : receiptData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)), "password" : shared_Secret]
            let requestData = try! JSONSerialization.data(withJSONObject: receiptDictionary, options: .prettyPrinted)
            let url = URL(string: self.validateReciepMode.URL_Str)!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.httpBody = requestData
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: req, completionHandler: { (data, res, error) in
                let json = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
                print("dataString \(String(describing: json))")

                var infos: [String : PurchasedProdcutInfo]? = nil
                var error: IAPError? = nil
                
                do{
                    infos = try  self.parsingReceipt(receiptedJson: json)
                }catch let e{
                    error = e as? IAPError
                }
                
                DispatchQueue.main.async {
                    completd?(infos, error)
                }
            })
            task.resume()
        }else{
            self.isNeedRefreshingReceipt = true
            let request = SKReceiptRefreshRequest(receiptProperties: nil)
            request.delegate = self
            request.start()
            
            self.receiptInfoCallback = completd
        }
    }
    
    fileprivate func parsingReceipt(receiptedJson: Any?) throws -> [String : PurchasedProdcutInfo]?{
        
        let status : IAPError.ReceiptError = IAPError.ReceiptError(rawValue: (receiptedJson as? NSDictionary)?.object(forKey: "status") as? Int ?? -1) ?? IAPError.ReceiptError.etc
        if !status.isNoError{
            throw IAPError.receipt_error(reason: status)
        }
        
        var purchasedProductInfos = [String : PurchasedProdcutInfo]()
        var pendingRenewalInfos = [String : PendingRenewalInfo]()
        
        
        if let pending_renewal_infos = (receiptedJson as? NSDictionary)?.object(forKey: "pending_renewal_info") as? NSArray{
            for pri in pending_renewal_infos{
                let auto_renew_status = ((pri as? NSDictionary)?.object(forKey: "auto_renew_status") as? String) ?? "5"
                let enum_auto_renew_status = PendingRenewalInfo.AutoRenewStatus(rawValue: auto_renew_status) ?? .unknown
                let expiration_intent = ((pri as? NSDictionary)?.object(forKey: "expiration_intent") as? String) ?? "5"
                let enum_expiration_intent = PendingRenewalInfo.SubscriptionExpirationIntent(rawValue: expiration_intent) ?? .unknown
                let is_in_billing_retry_period = ((pri as? NSDictionary)?.object(forKey: "is_in_billing_retry_period") as? String) ?? "5"
                let enum_is_in_billing_retry_period = PendingRenewalInfo.SubscriptionRetryFlag(rawValue: is_in_billing_retry_period) ?? .unknown
                
                if let auto_renew_product_id = (pri as? NSDictionary)?.object(forKey: "product_id") as? String{
                    pendingRenewalInfos[auto_renew_product_id] = PendingRenewalInfo(auto_renew_status: enum_auto_renew_status,
                                                                                      expiration_intent: enum_expiration_intent,
                                                                                      is_in_billing_retry_period: enum_is_in_billing_retry_period)
                }
            }
        }

        let receipt = (receiptedJson as? NSDictionary)?.object(forKey: "receipt") as? NSDictionary
        if let in_apps = receipt?.object(forKey: "in_app") as? NSArray, in_apps.count > 0{
            for in_app in in_apps{
                if let ppi = PurchasedProdcutInfo(jsonData: in_app as? NSDictionary){
                    if !ppi.is_auto_renewable_subscriptions{
                        purchasedProductInfos[ppi.product_id] = ppi
                    }
                }
            }
        }
        
        func isExistProductIDInReceipt(ppi: PurchasedProdcutInfo) -> Bool{
            let purchasedProductInfos_copy = purchasedProductInfos
            for (_,notAutoRenewableSubscription) in purchasedProductInfos_copy{
                if notAutoRenewableSubscription.product_id == ppi.product_id{
                    return true
                }
            }
            
            return false
        }

        if let latest_receipt_info = (receiptedJson as? NSDictionary)?.object(forKey: "latest_receipt_info") as? NSArray{
            var autoRenewalSubscriptionPurchasedProductInfos = [PurchasedProdcutInfo]()
            
            for in_app in latest_receipt_info{
                if let ppi = PurchasedProdcutInfo(jsonData: in_app as? NSDictionary){
                    if ppi.is_auto_renewable_subscriptions{
                        autoRenewalSubscriptionPurchasedProductInfos.append(ppi)
                    }else{
                        if !isExistProductIDInReceipt(ppi: ppi){
                            purchasedProductInfos[ppi.product_id] = ppi
                        }
                    }
                }
            }
            
            var autoInfoDic = [String:PurchasedProdcutInfo]()
            for autoInfo in autoRenewalSubscriptionPurchasedProductInfos{
                autoInfoDic[autoInfo.product_id] = autoInfo
            }
            
            for (key, value) in autoInfoDic{
                purchasedProductInfos[key] = value
                
                if let pendingRenewalInfo = pendingRenewalInfos[key]{
                    purchasedProductInfos[key]?.pendingRenewalInfo = pendingRenewalInfo
                }
            }
        }
        
        if purchasedProductInfos.count > 0 {
            return purchasedProductInfos
        }else{
            throw IAPError.receipt_error(reason: IAPError.ReceiptError.noPurchasedProduct)
        }
    }
}

