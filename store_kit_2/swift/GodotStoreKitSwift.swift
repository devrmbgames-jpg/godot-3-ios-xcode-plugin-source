//
//  GodotStoreKitSwift.swift
//  godot_plugin_lib
//
//  Created by Admin on 26.07.2024.
//

import Foundation
import StoreKit




@objc(GodotStoreKitSwift)
public class ObjCGodotStoreKitSwift: NSObject, ObservableObject  {
    
    private var _products: [String: Product] = [:]
    private var updates: Task<Void, Never>? = nil
    private var _purchase_deferred: String = ""
    private var _transactionList: [UInt64: Transaction] = [:]
    
    @objc public var godot_inited = false
    @objc var autoFinishedTransaction = true
    
    @objc var transactionUpdateCallback: (([[String: String]]) -> Void)? = nil
    @objc var purchaseDeferredCallback: ((String) -> Void)? = nil
    @objc var productUpdateCallback: (([[String: Any]]) -> Void)? = nil
    @objc var purchaseCallback: ((Int, String, [String: String]) -> Void)? = nil
    
    @objc static let ERR_OK: Int = 0
    @objc static let ERR_UNVERYFIED: Int = -1
    @objc static let ERR_EXCEPTION: Int = -2
    @objc static let ERR_PENDING: Int = 1
    @objc static let ERR_CANCELLED: Int = 2
    
    // MARK: - Initialization and Deinitialization
        override init() {
            super.init()
            SKPaymentQueue.default().add(self)
        }
        
        deinit {
            updates?.cancel()
            SKPaymentQueue.default().remove(self)
        }
        
        @objc public func postInit() {
            updates = observeTransactionUpdates()
        }
        
        // MARK: - Observe Transactions
        private func observeTransactionUpdates() -> Task<Void, Never> {
            return Task(priority: .background) { [weak self] in
                guard let self = self else { return }
                guard let callback = self.transactionUpdateCallback else {
                    print("[StoreKit2] Transaction update callback is nil!")
                    return
                }
                
                var results: [[String: String]] = []
                for await verificationResult in Transaction.updates {
                    if case .verified(let transaction) = verificationResult {
                        if let dict = try? await ObjCGodotStoreKitSwift.transactionToDict(transaction: transaction) {
                            results.append(dict)
                        }
                        
                        await transaction.finish()
                    }
                }
                
                guard self.godot_inited else {
                    print("[StoreKit2] Godot not initialized")
                    return
                }
                callback(results)
            }
        }
        
    // MARK: - Restore Transactions
    @MainActor
    @objc public func restoreAll() {
        guard godot_inited else {
            print("[StoreKit2] Godot not initialized!")
            return
        }
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            var results: [[String: String]] = []
            
            for await verificationResult in Transaction.currentEntitlements {
                if case .verified(let transaction) = verificationResult {
                    if let dict = try? await ObjCGodotStoreKitSwift.transactionToDict(transaction: transaction) {
                        results.append(dict)
                    }
                    
                    await transaction.finish()
                } else if case .unverified(_, let error) = verificationResult {
                    print("[StoreKit2] Unverified transaction: \(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async { [weak self, results] in
                guard let self = self else { return }
                guard self.godot_inited, let callback = self.transactionUpdateCallback else {
                    print("[StoreKit2] Callback not initialized or Godot not initialized!")
                    return
                }
                callback(results)
            }
        }
    }

    @MainActor
    @objc public func products(productIdentifiers: [String]) {
        guard !productIdentifiers.isEmpty else {
            print("[StoreKit2] Product identifiers list is empty!")
            return
        }
        let callback = self.productUpdateCallback
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            guard let callback = callback else { return }
            do {
                let appProducts = try await Product.products(for: productIdentifiers)
                var results: [[String: Any]] = []
                for product in appProducts {
                    let dict = try await ObjCGodotStoreKitSwift.parseProduct(product: product)
                    results.append(dict)
                    self._products[product.id] = product
                }
                guard self.godot_inited else { return }
                callback(results)
            } catch {
                print("[StoreKit2] Error fetching products: \(error.localizedDescription)")
            }
        }
    }

    
    

        // MARK: - Purchase Product
        @objc public func purchase(productIdentifier: String, quantity: Int) {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard let callback = self.purchaseCallback else {
                    print("[StoreKit2] Purchase callback is nil!")
                    return
                }
                
                do {
                   
                    
                    guard let product = self._products[productIdentifier] else {
                        print("[StoreKit2] Product not found: \(productIdentifier)")
                        return
                    }
                    
                    let options: Set<Product.PurchaseOption> = quantity > 1 ? [.quantity(quantity)] : []
                    let result = try await product.purchase(options: options)
                    
                    switch result {
                    case .success(let verificationResult):
                        if case .verified(let transaction) = verificationResult {
                            var dict = try await ObjCGodotStoreKitSwift.transactionToDict(transaction: transaction)
                            dict["receipt_sig"] = String(data: verificationResult.signatureData, encoding: .utf8)
                            dict["receipt"] = verificationResult.jwsRepresentation
                            await transaction.finish()
                            callback(ObjCGodotStoreKitSwift.ERR_OK, "OK", dict)
                        } else if case .unverified(_, let error) = verificationResult {
                            callback(ObjCGodotStoreKitSwift.ERR_UNVERYFIED, error.localizedDescription, [:])
                        }
                    case .pending:
                        callback(ObjCGodotStoreKitSwift.ERR_PENDING, "Pending", [:])
                    case .userCancelled:
                        callback(ObjCGodotStoreKitSwift.ERR_CANCELLED, "User cancelled", [:])
                    @unknown default:
                        print("[StoreKit2] Unknown purchase result")
                    }
                } catch {
                    guard self.godot_inited else { return }
                    callback(ObjCGodotStoreKitSwift.ERR_EXCEPTION, error.localizedDescription, [:])
                }
            }
        }
        
        // MARK: - Sync Store
        @objc public func storeSync(completion: @escaping () -> Void) {
            Task { @MainActor in
                do {
                    try await AppStore.sync()
                    completion()
                } catch {
                    print("[StoreKit2] Store sync failed: \(error.localizedDescription)")
                }
            }
        }
        
        // MARK: - Finish Transaction
        @objc public func transactionFinished(id: UInt64) {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                do {
                    await self._transactionList[id]?.finish()
                }
            }
        }
    
    @objc
    public static let shared = ObjCGodotStoreKitSwift()
    
    @objc
    public func getRegion(callback: @escaping(String) -> Void) {
        Task {
            let code = await Storefront.current?.countryCode
            guard self.godot_inited != false else {
                return
            }
            callback(code ?? "US")
        }
    }
    
    @MainActor
    @objc func showManageSubscriptions() {
            if #available(iOS 15.0, *) {
                if let window = UIApplication.shared.connectedScenes.first {
                    Task { @MainActor in
                        do {
                            try await AppStore.showManageSubscriptions(in: window as! UIWindowScene)
                        } catch {
                            print(error)
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    
    @MainActor
    static private func parseOffer(offer: Product.SubscriptionOffer) -> [String: String] {
        // Тип скидки (rawValue всегда присутствует)
        let typeDiscount: String = offer.type.rawValue
        
        // Режим оплаты
        let paymentMode: String = offer.paymentMode.rawValue
        
        // Цена скидки, форматируем с 2 знаками после запятой
        let priceDiscount: String = String(format: "%.2f", (offer.price as NSDecimalNumber).doubleValue)
        
        // Отображаемая цена
        let displayPrice: String = offer.displayPrice
        
        // SKU скидки (используем пустую строку вместо "ERROR")
        let skuDiscount: String = offer.id ?? ""
        
        // Период действия
        let period: String = "\(offer.period.value)"
        
        // Количество периодов
        let periodCount: String = "\(offer.periodCount)"
        
        // Формируем словарь
        let dict: [String: String] = [
            "sku": skuDiscount,
            "type": typeDiscount,
            "payment_mode": paymentMode,
            "price": priceDiscount,
            "display_price": displayPrice,
            "period": period,
            "period_count": periodCount
        ]
        
        return dict
    }

    
    @MainActor
    static private func parseProduct(product: Product) async throws -> [String: Any] {
        var typeProduct: String = ""
        switch product.type {
        case .nonConsumable:
            typeProduct = "non_consumable"
        case .autoRenewable:
            typeProduct = "auto_renewable"
        case .consumable:
            typeProduct = "consumable"
        case .nonRenewable:
            typeProduct = "non_renewable"
        default:
            typeProduct = "unknown"
        }

        var promotionalOffers: [[String: String]] = []
        if let offers = product.subscription?.promotionalOffers {
            for offer in offers {
                let dictOffer = ObjCGodotStoreKitSwift.parseOffer(offer: offer)
                promotionalOffers.append(dictOffer)
            }
        }

        var introductoryOffer: [String: String] = [:]
        if let offer = product.subscription?.introductoryOffer {
            introductoryOffer = ObjCGodotStoreKitSwift.parseOffer(offer: offer)
        }

        var subscriptionStatus: [[String: String]] = []
        if let status = try await product.subscription?.status {
            for stat in status {
                var dictStatus: [String: String] = [:]
                if case .verified(let renewalInfo) = stat.renewalInfo {
                    
                    let productId: String = renewalInfo.currentProductID
                    let originalTransactionId: String = "\(renewalInfo.originalTransactionID)"
                    let willAutoRenew: String = renewalInfo.willAutoRenew ? "yes" : "no"
                    let offerId: String = renewalInfo.offerID ?? ""
                    
                    dictStatus["product_id"] = productId
                    dictStatus["original_transaction_id"] = originalTransactionId
                    dictStatus["will_auto_renew"] = willAutoRenew
                    dictStatus["offer_id"] = offerId
                }
                if case .verified(let transaction) = stat.transaction {
                    let transactionId: String = "\(transaction.id)"
                    dictStatus["transaction_id"] = transactionId
                }
                subscriptionStatus.append(dictStatus)
            }
        }

        let displayName: String = product.displayName
        let description: String = product.description
        let displayPrice: String = product.displayPrice
        let priceText: String = String(format: "%.2f", (product.price as NSDecimalNumber).doubleValue)
        let currency: String = product.priceFormatStyle.currencyCode
        let sku: String = product.id
        let isFamily: String = product.isFamilyShareable ? "yes" : "no"
        let dict: [String: Any] = [
            "display_name": displayName,
            "description": description,
            "display_price": displayPrice,
            "price": priceText,
            "currency": currency ,
            "sku": sku,
            "type": typeProduct,
            "is_family": isFamily,
            "introductory_offer": introductoryOffer,
            "offers": promotionalOffers,
            "subscription_status": subscriptionStatus
        ]

        return dict //.filter { $0.value is NSString || $0.value is NSNumber || $0.value is NSDictionary || $0.value is NSArray }
    }

    
    @MainActor
    @objc public func requestPurchased(productIdentifier: [String]) {
        guard productIdentifier.count > 0 else {
            print("StoreKit2 product list is empty!")
            return
        }
        Task { @MainActor [weak self] in
            guard let self = self else {
                return
            }
            guard self.transactionUpdateCallback != nil else {
                print("StoreKit2 request purchased is failed! Callback is null")
                return
            }
            var results: [[String : String]] = []
            for await verificationResult in Transaction.currentEntitlements {
                switch verificationResult {
                case .verified(let transaction):
                    if productIdentifier.contains(transaction.productID) {
                        
                        do {
                            let dict = try await ObjCGodotStoreKitSwift.transactionToDict(transaction: transaction)
                            await transaction.finish()
                            
                            
                            results.append(dict)
                        }
                        catch(let err) {
                            print("StoreKit2 parse transaction failed - ", err)
                        }
                        
                    }
                    
                    
                    continue
                default:
                    continue
                }
            }
            guard self.godot_inited != false else {
                return
            }
            
            
            self.transactionUpdateCallback!(results)

        }
    }
    
    @MainActor
    static func transactionToDict(transaction: Transaction) async throws -> [String: String] {
        
        var typeProduct: String = ""
        switch transaction.productType {
        case .nonConsumable :
            typeProduct = "non_consumable"
            break
        case .autoRenewable :
            typeProduct = "auto_renewable"
            break
        case .consumable :
            typeProduct = "consumable"
            break
        case .nonRenewable :
            typeProduct = "non_renewable"
            break
        default:
            typeProduct = "unknow"
        }
        
        
        var isBillingRetry: Bool = false
        var willAutoRenew: Bool = false
        var autoRenewPreference: String? = "no"
        
        
        let products = try await Product.products(for: [transaction.productID])
        if let product = products.first {
            if let verificationResultRenewalInfo = try await product.subscription?.status.first?.renewalInfo {
                switch verificationResultRenewalInfo {
                case .verified(let renewalInfo) :
                    isBillingRetry = renewalInfo.isInBillingRetry
                    willAutoRenew = renewalInfo.willAutoRenew
                    autoRenewPreference = renewalInfo.autoRenewPreference
                    
                    
                case .unverified(_, let verificationError):
                    print(verificationError.localizedDescription)
                }
            }
        }
        
        
        
        
        var revocationReason: String = ""
        if #available(iOS 15.4, *) {
            revocationReason = transaction.revocationReason?.localizedDescription ?? ""
        }
        
        let revocationDate: Int = Int(transaction.revocationDate?.timeIntervalSince1970 ?? 0)
        let expirationDate: Int = Int(transaction.expirationDate?.timeIntervalSince1970 ?? 0)
        let purchaseData: Int = Int(transaction.purchaseDate.timeIntervalSince1970)
        var isExpiration: Bool = false
        if let expirationDate = transaction.expirationDate {
            isExpiration = expirationDate < Date()
        }
        
        let dict: [String : String] = [
            "sku" : transaction.productID,
            "original_id" : "\(transaction.originalID)",
            "purchased_date" : "\(purchaseData)",
            "transaction_id" : "\(transaction.id)",
            "product_id" : transaction.productID,
            "bundle_id" : transaction.appBundleID,
            "is_finished" : "no",
            "product_type" : typeProduct,
            "subscription_group" : transaction.subscriptionGroupID ?? "",
            "expiration_date" : "\(expirationDate)",
            "is_expiration" : isExpiration ? "yes" : "no",
            "is_upgraded" : transaction.isUpgraded ? "yes" : "no",
            "quantity" : "\(transaction.purchasedQuantity)",
            "is_revocation" : transaction.revocationDate != nil ? "yes" : "no",
            "revocation_date" : "\(revocationDate)",
            "revocation_reason" : revocationReason,
            "ownership_type" : transaction.ownershipType.rawValue,
            "receipt" : "",
            "receipt_sig" : "",
            "is_billing_retry" : isBillingRetry ? "yes" : "no",
            "will_auto_renew" : willAutoRenew ? "yes" : "no",
            "auto_renew_preference" : "\(autoRenewPreference ?? "")"
        ]
        
        
        
        return dict
    }
    
    @MainActor
    @objc public func purchaseDeferredForce() {
        guard !_purchase_deferred.isEmpty else { return }
        guard purchaseDeferredCallback != nil else {
            print("StoreKit2 purchase deferred force is failed! callback is null")
            return
        }
        guard self.godot_inited != false else {
            return
        }
        
        purchaseDeferredCallback!(_purchase_deferred)
        _purchase_deferred = ""
    }
    
    @MainActor
    @objc public func purchaseDeferredClear() {
        _purchase_deferred = ""
    }
}


extension ObjCGodotStoreKitSwift: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    
    
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        print("update purchase deferred!")
        _purchase_deferred = product.productIdentifier
        guard self.godot_inited != false else {
            return false
        }
        
        if (purchaseDeferredCallback != nil) {
            purchaseDeferredCallback!(_purchase_deferred)
        }
        return false
    }
}
