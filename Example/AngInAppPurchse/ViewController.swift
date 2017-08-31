//
//  ViewController.swift
//  IAP
//
//  Created by skyphinehas@hanmail.net on 08/28/2017.
//  Copyright (c) 2017 skyphinehas@hanmail.net. All rights reserved.
//

import UIKit
import AngInAppPurchse

public enum Products : Int {
    case a_month_auto = 0
    case a_week_auto
    case a_month
    case possession
    case possession_sep
    
    public var id: String {
        switch self {
        case .a_month_auto:
            return "com.littlefox.storybook.TomSawyer.AutoSubscription.1month"
        case .a_week_auto:
            return "com.littlefox.storybook.TomSawyer.AutoSubscription.1week"
        case .a_month:
            return "com.littlefox.storybook.TomSawyer.Subscription.1month"
        case .possession:
            return "lf_sb_taots_all"
        case .possession_sep:
            return "lf_sb_taots_1"
        }
    }
    
    static public var set: NSSet {
        let productsArray = (Products.a_month_auto.rawValue...Products.possession_sep.rawValue).map { (rawValue) -> String in
            return Products(rawValue: rawValue)!.id
        }
        return NSSet(array: productsArray)
    }
}

class ViewController: UIViewController {
    
    var spinner: UIActivityIndicatorView?
    
    @IBOutlet weak var auto1WeekBtn: UIButton!
    @IBOutlet weak var auto1MonthBtn: UIButton!
    @IBOutlet weak var non1MonthBtn: UIButton!
    @IBOutlet weak var possessionBtn: UIButton!
    @IBOutlet weak var possessionSepBtn: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("Products.set \(Products.set)")
        IAP.helper.requestProductsWithCompletionHandler(productIdentifiers: Products.set) { (success) in
            self.auto1WeekBtn.setTitle("1주 자동결제 : \(IAP.helper.products[Products.a_week_auto.id]?.priceString ?? "")", for: .normal)
            self.auto1MonthBtn.setTitle("1달 자동결제 : \(IAP.helper.products[Products.a_month_auto.id]?.priceString ?? "")", for: .normal)
            self.non1MonthBtn.setTitle("1달 결제 : \(IAP.helper.products[Products.a_month.id]?.priceString ?? "")", for: .normal)
            self.possessionBtn.setTitle("단품 결제 : \(IAP.helper.products[Products.possession.id]?.priceString ?? "")", for: .normal)
            self.possessionSepBtn.setTitle("낱 결제 : \(IAP.helper.products[Products.possession_sep.id]?.priceString ?? "")", for: .normal)
        }
    }
    
    @IBAction func autoPurchaseAWeekBtn(_ sender: Any) {
        
        self.addSpinner()
        
        IAP.helper.purchase(withProductID: Products.a_week_auto.id) { (success, id, error) in
            if success {
                self.refreshBtn(UIButton())
            }else{
                print("purchase completed : \(String(describing: id)), error : \(String(describing: error?.desc))")
            }
            
            self.removeSpinner()
        }
    }

    @IBAction func autoPurchaseBtn(_ sender: Any) {
        
        self.addSpinner()
        
        
        IAP.helper.purchase(withProductID: Products.a_month_auto.id) { (success, id, error) in
            if success {
                self.refreshBtn(UIButton())
            }else{
                print("purchase completed : \(String(describing: id)), error : \(String(describing: error?.desc))")
            }
            
            self.removeSpinner()
        }
    }
    
    @IBAction func nonAutoPurchaseBtn(_ sender: Any) {
        IAP.helper.purchase(withProductID: Products.a_month.id) { (success, id, error) in
            print("purchase completed : \(String(describing: id))")
        }
    }
    
    @IBAction func possessionPurchaseBtn(_ sender: Any) {
        
        self.addSpinner()
        
        IAP.helper.purchase(withProductID: Products.possession.id) { (success, id, error) in
            if success {
                self.possessionBtn.setTitle("단품 결제 구매됨", for: .normal)
            }else{
                print("purchase completed \(success): \(String(describing: id)) error \(String(describing: error?.desc ?? ""))")
            }
            
            self.removeSpinner()
        }
    }
    
    @IBAction func possessionSepPurchaseBtn(_ sender: Any) {
        
        self.addSpinner()
        
        IAP.helper.purchase(withProductID: Products.possession_sep.id) { (success, id, error) in
            if success{
                self.possessionSepBtn.setTitle("낱 결제 구매됨", for: .normal)
            }else{
                print("purchase completed \(success): \(String(describing: id)) error \(String(describing: error?.desc ?? ""))")
            }
            
            self.removeSpinner()
        }
    }
    
    @IBAction func refreshBtn(_ sender: Any) {
        
        self.addSpinner()
        
        IAP.helper.shared_Secret = "9edbb8e7d8ac46c58f5ce1ca8e5eeaf5"
        IAP.helper.receiptValidation { (subscriptionInfo, error) in
            
            self.removeSpinner()
            
            if let e = error {
                print("e : \(e.desc)")
                return
            }
            
            if let si = subscriptionInfo{
                for (key,value) in si{
                    
                    print("\(key) \n \(value) \n")
                    
                    switch key{
                    case Products.a_week_auto.id:
                        if let expires_date = value.expires_date{
                            if expires_date.isExpired{
                                self.auto1WeekBtn.setTitle("1주 자동결제 : \(IAP.helper.products[key]?.priceString ?? "")", for: .normal)
                            }else{
                                self.auto1WeekBtn.setTitle(expires_date.toString(), for: .normal)
                            }
                        }
                        break
                    case Products.a_month_auto.id:
                        if let expires_date = value.expires_date{
                            if expires_date.isExpired{
                                self.auto1MonthBtn.setTitle("1달 자동결제 : \(IAP.helper.products[key]?.priceString ?? "")", for: .normal)
                            }else{
                                self.auto1MonthBtn.setTitle(expires_date.toString(), for: .normal)
                            }
                        }
                        break
                    case Products.a_month.id:
                        break
                    case Products.possession.id:
                        self.possessionBtn.setTitle("단품 결제 구매됨", for: .normal)
                        break
                    case Products.possession_sep.id:
                        self.possessionSepBtn.setTitle("낱 결제 구매됨", for: .normal)
                        break
                    default:
                        break
                    }
                    
                }
            }
            
            
        }
    }
    
    @IBAction func restoreBtn(_ sender: Any) {
        IAP.helper.restore { (success, ids, error) in
            print("restore success \(success) : ids \(String(describing: ids)) : error \(String(describing: error?.desc))")
        }
    }
}


extension ViewController{
    func addSpinner() {
        
        removeSpinner()
        
        spinner = UIActivityIndicatorView(frame: self.view.frame)
        spinner?.activityIndicatorViewStyle = .gray
        spinner?.startAnimating()
        
        self.view.addSubview(spinner!)
    }
    
    func removeSpinner() {
        spinner?.removeFromSuperview()
        spinner = nil
    }
}

