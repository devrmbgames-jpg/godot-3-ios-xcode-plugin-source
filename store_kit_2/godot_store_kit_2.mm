//
//  godot_store_kit_2.m
//  godot_plugin_lib
//
//  Created by Admin on 26.07.2024.
//

#include "godot_store_kit_2.h"
#import <Game-Swift.h>
//#import "godot_plugin_lib-Swift.h"
#include "utils.h"




const String GodotStoreKit2::signal_update_products_list = "update_products_list";
const String GodotStoreKit2::signal_update_transaction_list = "update_transaction_list";
const String GodotStoreKit2::signal_purchased = "purchased";
const String GodotStoreKit2::signal_purchase_deferred = "purchase_deferred";
const String GodotStoreKit2::signal_store_sync = "store_sync_completed";
const String GodotStoreKit2::signal_update_region = "update_region";


GodotStoreKit2::GodotStoreKit2() {
    @try {
        _inited = false;
        GodotStoreKitSwift.shared.productUpdateCallback = ^(NSArray<NSDictionary<NSString*,id> *> *productList) {
            if (!productList || productList.count == 0 || !_inited) {
                NSLog(@"[GodotStoreKit] Product list is invalid or StoreKit is not initialized!");
                return;
            }
            NSLog(@"[GodotStoreKit] product update callback - %@", productList.description);

            @try {
                Variant var = Utils::convert_ns_value_to_variant(productList);
                NSLog(@"[GodotStoreKit] var is - %@", [NSString stringWithUTF8String:String(var).utf8()]);
                if (var.get_type() == Variant::ARRAY) {
                    Array arr = var;
                    //emit_signal(signal_update_products_list, arr);
                    call_deferred("emit_signal", signal_update_products_list, arr);
                }
                else {
                    NSLog(@"[GodotStoreKit] conver ns to variant is invalid!");
                }
            } @catch (NSException *exception) {
                NSLog(@"[GodotStoreKit] Exception during product update: %@", exception.reason);
            }
        };
        
        GodotStoreKitSwift.shared.transactionUpdateCallback = ^(NSArray<NSDictionary<NSString *, NSString *> *> *transactionList) {
            if (!transactionList) {
                NSLog(@"[GodotStoreKit2] Update transaction failed: transaction list is nil!");
                return;
            }
            
            if (!_inited) {
                NSLog(@"[GodotStoreKit2] Update transaction failed: StoreKit is not initialized!");
                return;
            }
            
            if (transactionList.count == 0) {
                NSLog(@"[GodotStoreKit2] Update transaction failed: transaction list is empty!");
                return;
            }
            
            NSLog(@"[GodotStoreKit2] Transaction list count: %lu", (unsigned long)transactionList.count);
            
            Variant variant_list = Utils::convert_ns_value_to_variant(transactionList);
            if (variant_list.get_type() == Variant::ARRAY) {
                Array transaction_list = variant_list;
                
                call_deferred("emit_signal", signal_update_transaction_list, transaction_list);
            }
            else {
                NSLog(@"[GodotStoreKit2] transaction variant is invalid!");
            }
            //emit_signal(signal_update_transaction_list, transaction_list);
        };

        
        GodotStoreKitSwift.shared.purchaseCallback = ^(NSInteger errCode,
                                                       NSString * errText,
                                                       NSDictionary<NSString *,NSString *> *product) {
            if (product == nil) return;
            if (product.count == 0) return;
            if (_inited == false) return;
            Dictionary dict = Utils::convert_ns_value_to_variant(product);
            String err = errText.UTF8String;
            int code = int(errCode);
            
            
            emit_signal(signal_purchased, code, err, dict);
        };
        
        GodotStoreKitSwift.shared.purchaseDeferredCallback = ^(NSString *sku) {
            if (_inited == false) return;
            if (!sku) return;
            if (sku.length > 0) {
                NSString *sku_cpy = [sku mutableCopy];
                emit_signal(signal_purchase_deferred, sku_cpy.UTF8String);
                _purchase_deferred = sku_cpy.UTF8String;
            }
        };
        
        GodotStoreKitSwift.shared.godot_inited = true;
        _inited = true;
    }
    @catch (NSException *exception) {
        NSLog(@"StoreKit2 %@", exception);
    }
    @catch (id e) {
        NSLog(@"StoreKit2 %@", e);
    }
}




GodotStoreKit2::~GodotStoreKit2() {
    _inited = false;
    GodotStoreKitSwift.shared.godot_inited = false;
    GodotStoreKitSwift.shared.purchaseDeferredCallback = nil;
    GodotStoreKitSwift.shared.purchaseCallback = nil;
    GodotStoreKitSwift.shared.transactionUpdateCallback = nil;
    GodotStoreKitSwift.shared.productUpdateCallback = nil;
}

void GodotStoreKit2::init_store() {
    [GodotStoreKitSwift.shared postInit];
}

void GodotStoreKit2::_bind_methods() {
    
    ADD_SIGNAL(MethodInfo(signal_update_products_list,
                          PropertyInfo(Variant::ARRAY, "list_products")));
    
    ADD_SIGNAL(MethodInfo(signal_update_transaction_list,
                          PropertyInfo(Variant::ARRAY, "list_transactions")));
    
    ADD_SIGNAL(MethodInfo(signal_purchased,
                          PropertyInfo(Variant::INT, "err_code"),
                          PropertyInfo(Variant::STRING, "error_text"),
                          PropertyInfo(Variant::DICTIONARY, "transaction")));
    
    ADD_SIGNAL(MethodInfo(signal_store_sync));
    
    ADD_SIGNAL(MethodInfo(signal_purchase_deferred, PropertyInfo(Variant::STRING, "sku")));
    
    ADD_SIGNAL(MethodInfo(signal_update_region));
    
    ClassDB::bind_method(D_METHOD("request_products", "sku_list"), &GodotStoreKit2::request_products);
    ClassDB::bind_method(D_METHOD("request_purchased", "sku_list"), &GodotStoreKit2::request_purchased);
    ClassDB::bind_method(D_METHOD("purchase_product", "sku", "count"), &GodotStoreKit2::purchase_product);
    ClassDB::bind_method(D_METHOD("restore_all"), &GodotStoreKit2::restore_all);
    ClassDB::bind_method(D_METHOD("store_sync"), &GodotStoreKit2::store_sync);
    ClassDB::bind_method(D_METHOD("request_region"), &GodotStoreKit2::request_region);
    ClassDB::bind_method(D_METHOD("get_region"), &GodotStoreKit2::get_region);
    ClassDB::bind_method(D_METHOD("purchase_deferred_force"), &GodotStoreKit2::purchase_deferred_force);
    ClassDB::bind_method(D_METHOD("purchase_deferred_clear"), &GodotStoreKit2::purchase_deferred_clear);
    ClassDB::bind_method(D_METHOD("get_screen_orientation"), &GodotStoreKit2::get_screen_orientation);
    ClassDB::bind_method(D_METHOD("init_store"), &GodotStoreKit2::init_store);
    ClassDB::bind_method(D_METHOD("set_finished_transaction"), &GodotStoreKit2::set_finished_transaction);
    ClassDB::bind_method(D_METHOD("show_manage_subscriptions"), &GodotStoreKit2::show_manage_subscriptions);
}


void GodotStoreKit2::request_products(PoolStringArray skus) {
    if (!_inited) return;
    @try {
        //request_region();
    
        NSMutableArray<NSString*> * ns_skus = [[NSMutableArray<NSString*> alloc] initWithCapacity:skus.size()];
        for (int i = 0; i < skus.size(); i++) {
            NSString* sku = [NSString stringWithUTF8String:skus[i].utf8()];
            NSString* copy = [sku mutableCopy];
            [ns_skus addObject:copy];
        }
    
        
        [GodotStoreKitSwift.shared productsWithProductIdentifiers:[ns_skus copy]];
        
    } @catch (NSException *exception) {
        NSLog(@"[GodotStoreKit] exception %@", exception);
    } @finally {
        
    }
    
}

void GodotStoreKit2::request_purchased(PoolStringArray skus) { 
 
    NSMutableArray<NSString*> * ns_skus = [[NSMutableArray<NSString*> alloc] initWithCapacity:skus.size()];
    
    for (int i = 0; i < skus.size(); i++) {
        NSString* sku = [NSString stringWithUTF8String:skus[i].utf8()];
        [ns_skus addObject:sku];
    }
    
    [GodotStoreKitSwift.shared requestPurchasedWithProductIdentifier:ns_skus];

}

void GodotStoreKit2::purchase_product(String sku, int quantity) {

    NSString* ns_sku = [NSString stringWithUTF8String:sku.utf8()];
    
    [GodotStoreKitSwift.shared purchaseWithProductIdentifier:ns_sku
                                                    quantity:quantity];
}

void GodotStoreKit2::restore_all() {
    [GodotStoreKitSwift.shared restoreAll];
}

void GodotStoreKit2::show_manage_subscriptions() {
    [GodotStoreKitSwift.shared showManageSubscriptions];
}

void GodotStoreKit2::store_sync() { 
    
    [GodotStoreKitSwift.shared storeSyncWithCompletion:^{
        emit_signal(signal_store_sync);
    }];
}

void GodotStoreKit2::request_region() {
    [GodotStoreKitSwift.shared getRegionWithCallback:^(NSString *country_code) {
        _current_region = country_code.UTF8String;
        emit_signal(signal_update_region);
    }];
}

String GodotStoreKit2::get_region() const {
    return _current_region;
}

void GodotStoreKit2::purchase_deferred_force() {
    [GodotStoreKitSwift.shared purchaseDeferredForce];
}

void GodotStoreKit2::purchase_deferred_clear() {
    [GodotStoreKitSwift.shared purchaseDeferredClear];
}

String GodotStoreKit2::get_purchase_deferred() const {
    return _purchase_deferred;
}

int GodotStoreKit2::get_screen_orientation() const {
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    return int(deviceOrientation);
}

void GodotStoreKit2::set_finished_transaction(bool val) {
    [GodotStoreKitSwift.shared setAutoFinishedTransaction: val];
}
