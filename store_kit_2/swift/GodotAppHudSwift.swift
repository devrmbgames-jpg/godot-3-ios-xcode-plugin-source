//
//  GodotAppHudSwift.swift
//  godot_plugin_lib
//
//  Created by Admin on 13.09.2024.
//

import Foundation
import ApphudSDK
import StoreKit
import AmplitudeSwift

@objc(GodotAppHudSwift)
public class ObjCGodotAppHudSwift: NSObject, ApphudDelegate {
    
    override init() {
        super.init()
    }
    
    @objc
    public static let shared = ObjCGodotAppHudSwift()
    
    private var _inited = false
    
    @objc
    public var godot_inited = false
    
    public var _apphudUser: ApphudUser? = nil
    public var _products: [String: ApphudProduct] = [:]
    public var _nativeProducts: [String: Product] = [:]
    
    @objc
    public func erase() {
        _inited = false
        godot_inited = false
    }
    
    
    @objc
    public func start(apiKey: String, userID: String?, observerMode: Bool, callback:((Bool) -> Void)? = nil) {
        _inited = true

        startMannualy(
            apiKey: apiKey,
            userID: UIDevice.current.identifierForVendor?.uuidString,
            deviceID: UIDevice.current.identifierForVendor?.uuidString,
            observerMode: observerMode,
            callback:callback)

    }
    
    @objc
    public func startMannualy(apiKey: String, userID: String?, deviceID: String?, observerMode: Bool, callback:((Bool) -> Void)? = nil) {
        _inited = true
        Task { @MainActor [weak self] in
            guard let self = self else { return }
                
                Apphud.startManually(
                    apiKey: apiKey,
                    userID: UIDevice.current.identifierForVendor?.uuidString,
                    deviceID: UIDevice.current.identifierForVendor?.uuidString,
                    observerMode: observerMode,
                    callback: { apphudUser in
                        guard callback != nil else {
                            return
                        }
                        self._apphudUser = apphudUser
                        print("[AppHud] user id: %@", apphudUser.userId)
                        print("[AppHud] is observer mode: %@", observerMode)
                        guard self._inited else { return }
                        guard self.godot_inited != false else {
                            return
                        }
                        guard let callback = callback else { return }
                        callback(true)
                    }
                )
                
                Apphud.setDeviceIdentifiers(idfa: UIDevice.current.identifierForVendor?.uuidString, idfv: UIDevice.current.identifierForVendor?.uuidString)
        }
    }
    
    public func apphudDidChangeUserID(_ userID: String) {
        
    }
    
    
    @objc
    public func restore() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            await Apphud.restorePurchases()
        }
    }
    
    @MainActor
    public func parseProduct(product: ApphudProduct) async -> [String: Any] {
        
        do {
            if let nativeProduct = try await product.product() {
                _nativeProducts[product.productId] = nativeProduct
                var typeProduct: String = ""
                switch nativeProduct.type {
                case .nonConsumable :
                    typeProduct = "non_consumable"
                case .autoRenewable :
                    typeProduct = "auto_renewable"
                case .consumable :
                    typeProduct = "consumable"
                case .nonRenewable :
                    typeProduct = "non_renewable"
                default:
                    typeProduct = "unknow"
                }
                
                let price = nativeProduct.price as NSDecimalNumber
                
                var discounts: [[String: String]] = []
                if nativeProduct.subscription != nil {
                    for offer in nativeProduct.subscription!.promotionalOffers {
                        let typeDiscount: String = offer.type.rawValue
                        let paymentMode: String = offer.paymentMode.rawValue
                        let priseDiscount: String = "\(offer.price)"
                        let displayPrice: String = offer.displayPrice
                        let skuDiscount: String = offer.id ?? "ERROR"
                        let period: String = "\(offer.period.value)"
                        let periodCount: String = "\(offer.periodCount)"
                        
                        let dict: [String : String] = [
                            "sku": skuDiscount,
                            "type": typeDiscount,
                            "payment_mode": paymentMode,
                            "price": priseDiscount,
                            "display_price" : displayPrice,
                            "period" : period,
                            "period_count" :periodCount,
                        ]
                        
                        discounts.append(dict)
                    }
                }
                
                let dict: [String : Any] = [
                    
                    "display_name" : nativeProduct.displayName,
                    "description" : nativeProduct.description,
                    "display_price" : nativeProduct.displayPrice,
                    "price" : "\( price.floatValue)",
                    "currency": "\(nativeProduct.priceFormatStyle)",
                    "discounts":discounts,
                    "currency_code" : nativeProduct.priceFormatStyle.currencyCode,
                    "sku" : nativeProduct.id,
                    "product_id": product.productId,
                    "paywall_id": product.paywallIdentifier ?? "",
                    "apphud_name" : product.name ?? "",
                    "type_raw": nativeProduct.type.rawValue,
                    "type" : typeProduct,
                    "is_family" : nativeProduct.isFamilyShareable ? "yes" : "no",
                    
                    "json" : String(data: nativeProduct.jsonRepresentation, encoding: String.Encoding.utf8) ?? ""
                ]
                
                return dict
            }
            return [:]
        }
        catch {
            return [:]
        }
    }
    
    @MainActor
    @objc
    public func requestProducts(pCallback:(([[String : Any]]) -> Void)? = nil) {
        
        print("[ APPHUD ] - request product")
        print("[ APPHUD ] ...")
        
        Task {  @MainActor [weak self] in
            guard let self = self else { return }
            do {

                var results : [[String : Any]] = []
                for placement in await Apphud.placements() {

                    if let payWall = placement.paywall {
                        
                        for product in payWall.products {
                            self._products[product.productId] = product
                            print("[ APPHUD ] - parse...")
                            var parseResult = await self.parseProduct(product: product)
                            parseResult["placement_id"] = placement.identifier
                            results.append(parseResult)
                        }
                    }
                    guard self._inited else { return }
                    guard self.godot_inited != false else {
                        return
                    }
                    guard let callback = pCallback else { return }
                    callback(results)

                }
            }
            catch {}
        }
    }
    
    @MainActor
    public func parseSubscription(subscription: ApphudSubscription) -> [String : String] {
       
        
        var sku: String = subscription.productId
        var typeProduct: String = "auto_renewable"
        
        let dict: [String : String] = [
            "sku" : sku,
            "purchased_date" : "\(subscription.startedAt)",
            "canceled_date" : String(describing: subscription.canceledAt),
            "transaction_id" : subscription.productId,
            "product_id" : subscription.productId,
            "product_type" : typeProduct,
            "is_renewable" : subscription.isAutorenewEnabled ? "yes" : "no",
            "expiration_date" : "\(subscription.expiresDate)",
            "is_sandbox" : subscription.isSandbox ? "yes" : "no",
            "is_local" : subscription.isLocal ? "yes" : "no",
            "is_introductory_activated" : subscription.isIntroductoryActivated ? "yes" : "no",
            "is_in_retry_billing" : subscription.isInRetryBilling ? "yes" : "no",
            "is_active" : subscription.isActive() ? "yes" : "no",
            "is_auto_renew_enabled" : subscription.isAutorenewEnabled ? "yes" : "no"
        ]
        
        return dict
    }
    
    public func parseNonRenewingPurchases(purchase: ApphudNonRenewingPurchase) async -> [String : String] {
        var typeProduct: String = "non_consumable"
        var sku: String = purchase.productId
        if let product = _products[purchase.productId] {
            do {
                if let nativeProduct = try await product.product() {
                    sku = nativeProduct.id
                    switch nativeProduct.type {
                    case .nonConsumable :
                        typeProduct = "non_consumable"
                    case .consumable :
                        typeProduct = "consumable"
                    default:
                        typeProduct = "non_consumable"
                    }
                }
            } catch {}
        }
        
        
        let dict: [String : String] = [
            "sku" : sku,
            "purchased_date" : "\(purchase.purchasedAt)",
            "canceled_date" : String(describing: purchase.canceledAt),
            "transaction_id" : purchase.productId,
            "product_id" : purchase.productId,
            "product_type" : typeProduct,
            "is_sandbox" : purchase.isSandbox ? "yes" : "no",
            "is_local" : purchase.isLocal ? "yes" : "no",
            "is_active" : purchase.isActive() ? "yes" : "no",
            "quantity" : "1",
        ]
        
        return dict
    }
    
    
    @MainActor
    @objc
    public func requestTransactions(pCallback:(([[String: String]]) -> Void)? = nil) {
        guard self._inited else { return }
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                guard self._inited else { return }
                var transactions: [[String: String]] = []
                
                if let subscriptions = Apphud.subscriptions() {
                    for subscription in subscriptions {
                        let dict = parseSubscription(subscription: subscription)
                        if !dict.isEmpty {
                            transactions.append(dict)
                        }
                    }
                }
                
                guard self._inited else { return }
                
                if let nonRenewingPurchases = Apphud.nonRenewingPurchases() {
                    for purchase in nonRenewingPurchases {
                        let dict = await parseNonRenewingPurchases(purchase: purchase)
                        transactions.append(dict)
                    }
                }
                guard self._inited else { return }
                guard self.godot_inited != false else {
                    return
                }
                guard let callback = pCallback else { return }
                callback(transactions)
            }
            catch {}
        }
    }
    
    @MainActor
    @objc
    public func purchasePromo(productId: String, discontID: String, callback:(([String : String], Bool) -> Void)? = nil) {
        
        guard self._inited else { return }
        print("[ APPHUD ] - purchase promo")
        
        Task { @MainActor [weak self] in
            
            guard let _self = self else {
                return
            }
            guard _self._inited else { return }
            
            do {
                
                if let product = _products[productId] {
                    
                    Apphud.purchasePromo(apphudProduct: product, discountID: discontID) { result in
                        
                        
                        
                        Task { @MainActor [weak self] in
                            guard let self = self else {
                                return
                            }
                            guard self._inited else { return }
                            
                            
                            
                            if result.success {
                                
                                if result.subscription != nil {
                                    guard let subscription = result.subscription else {
                                        return
                                    }
                                    
                                    var dict = await self.parseSubscription(subscription: subscription)
                                    dict["result"] = "ok"
                                    guard self._inited else { return }
                                    guard let callback = callback else {
                                        return
                                    }
                                    callback(dict, true)
                                }
                                else if result.nonRenewingPurchase != nil {
                                    guard let nonRenewingPurchase = result.nonRenewingPurchase else {
                                        return
                                    }
                                    var dict = await self.parseNonRenewingPurchases(purchase: nonRenewingPurchase)
                                    dict["result"] = "ok"
                                    guard self._inited else { return }
                                    guard let callback = callback else {
                                        return
                                    }
                                    callback(dict, true)
                                }
                                else {
                                    let dict: [String : String] = [
                                        "product_id" : productId,
                                        "sku" : product.skProduct?.productIdentifier ?? " Unknow sku",
                                        "error" : result.error?.localizedDescription ?? " Unknow error",
                                        "result" : "error"
                                    ]
                                    guard self._inited else { return }
                                    guard let callback = callback else {
                                        return
                                    }
                                    callback(dict, false)
                                }
                            }
                            else {
                                let dict: [String : String] = [
                                    "product_id" : productId,
                                    "error" : result.error?.localizedDescription ?? " purchase failed",
                                    "result" : "error"
                                ]
                                guard self._inited else { return }
                                guard let callback = callback else {
                                    return
                                }
                                callback(dict, false)
                                
                            }
                        }
                    }
                }
                else {
                    let dict: [String : String] = [
                        "product_id" : productId,
                        "error" : "product not found!"
                    ]
                    guard _self._inited else { return }
                    guard _self.godot_inited != false else {
                        return
                    }
                    
                    
                    guard let callback = callback else {
                        return
                    }
                    callback(dict, false)
                }
                
            } catch {}
        }
    }
    
    @objc
    public func restorePurchase(callback: (([[String : String]]) -> Void)? = nil) {
        Task { @MainActor [weak self] in
            guard let self = self else {
                return
            }
            do {
                Apphud.restorePurchases() { subscriptions, purchases, error in
                    Task {
                        var transactions: [[String : String]] = []
                        if subscriptions != nil {
                            for subscription in subscriptions! {
                                let dict = await self.parseSubscription(subscription: subscription)
                                transactions.append(dict)
                            }
                        }
                        
                        if purchases != nil {
                            for purchase in purchases! {
                                let dict = await self.parseNonRenewingPurchases(purchase: purchase)
                                transactions.append(dict)
                            }
                        }
                        guard self._inited else { return }
                        guard self.godot_inited != false else {
                            return
                        }
                        if callback != nil {
                            callback!(transactions)
                        }
                    }
                }
            }
            catch {}
        }
    }
    
    @objc
    public func purchase(productId: String, pCallback: (([String : String], Bool) -> Void)? = nil) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                if let product = _products[productId] {
                    
                    let result = await Apphud.purchase(product)
                    if result.success {
                        if result.subscription != nil {
                            var dict = await self.parseSubscription(subscription: result.subscription!)
                            dict["result"] = "ok"
                            guard self._inited else { return }
                            guard let callback = pCallback else { return }
                            callback(dict, true)
                        }
                        else if result.nonRenewingPurchase != nil {
                            var dict = await self.parseNonRenewingPurchases(purchase: result.nonRenewingPurchase!)
                            dict["result"] = "ok"
                            guard self._inited else { return }
                            guard let callback = pCallback else { return }
                            callback(dict, true)
                        }
                        else {
                            let dict: [String : String] = [
                                "product_id" : productId,
                                "sku" : product.skProduct?.productIdentifier ?? " Unknow sku",
                                "error" : result.error?.localizedDescription ?? " Unknow error",
                                "result" : "error"
                            ]
                            guard self._inited else { return }
                            guard let callback = pCallback else { return }
                            callback(dict, false)
                        }
                    }
                    else {
                        let dict: [String : String] = [
                            "product_id" : productId,
                            "error" : "product not found!"
                        ]
                        guard self._inited else { return }
                        guard self.godot_inited != false else {
                            return
                        }
                        guard let callback = pCallback else { return }
                        callback(dict, false)
                    }
                }
            }
            catch {}
        }
    }
    
    @objc
    public func logout() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            await Apphud.logout()
        }
    }
    
    
    
}
