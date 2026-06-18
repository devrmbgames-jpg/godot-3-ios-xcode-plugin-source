//
//  godot_apphud.m
//  godot_plugin_lib
//
//  Created by Admin on 13.09.2024.
//

#include "godot_apphud.h"
#include "godot_amplitude.h"
//#import "godot_plugin_lib-Swift.h"
#include <Game-Swift.h>
#include "utils.h"

@import AmplitudeSwift;
@import ApphudSDK;


GodotAppHud* GodotAppHud::_instance = NULL;

GodotAppHud* GodotAppHud::get_instance() {
    return _instance;
}

void GodotAppHud::_bind_methods() { 
    ClassDB::bind_method(D_METHOD("start"), &GodotAppHud::start);
    ClassDB::bind_method(D_METHOD("start_manually"), &GodotAppHud::start_manually);
    ClassDB::bind_method(D_METHOD("log_out"), &GodotAppHud::log_out);
    ClassDB::bind_method(D_METHOD("purchase_promo"), &GodotAppHud::purchase_promo);
    ClassDB::bind_method(D_METHOD("request_product"), &GodotAppHud::request_product);
    ClassDB::bind_method(D_METHOD("request_transactions"), &GodotAppHud::request_transactions);
    ClassDB::bind_method(D_METHOD("restore_purchase"), &GodotAppHud::restore_purchase);
    ClassDB::bind_method(D_METHOD("purchase_product"), &GodotAppHud::purchase_product);
    ClassDB::bind_method(D_METHOD("connect_to_amplitude"), &GodotAppHud::connect_to_amplitude);
    ClassDB::bind_method(D_METHOD("get_user_id"), &GodotAppHud::get_user_id);
    ClassDB::bind_method(D_METHOD("get_device_id"), &GodotAppHud::get_device_id);
    
    ADD_SIGNAL(MethodInfo("connected"));
    ADD_SIGNAL(MethodInfo("update_transaction", PropertyInfo(Variant::DICTIONARY, "transaction")));
    ADD_SIGNAL(MethodInfo("update_product", PropertyInfo(Variant::DICTIONARY, "product")));
    ADD_SIGNAL(MethodInfo("purchase_success", PropertyInfo(Variant::DICTIONARY, "transaction")));
    ADD_SIGNAL(MethodInfo("purchase_failed", PropertyInfo(Variant::DICTIONARY, "transaction")));
}

GodotAppHud::GodotAppHud() {
    if (_instance)
        return;
    _instance = this;
    GodotAppHudSwift.shared.godot_inited = true;
}

GodotAppHud::~GodotAppHud() {
    if (_instance == this)
        _instance = NULL;
    GodotAppHudSwift.shared.godot_inited = false;
    [GodotAppHudSwift.shared erase];
}

void GodotAppHud::start(String app_id, String user_id, bool is_observer) {
    NSString *appId = [NSString stringWithUTF8String:app_id.utf8()];
    NSString *userId = [NSString stringWithUTF8String:user_id.utf8()];
    
    if (user_id.empty()) {
        userId = nil;
    }
    
    UIDevice *device = [UIDevice currentDevice];
    NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
    
    if (userId == nil || userId.length < 2) {
        userId = currentDeviceId;
    }
    
    [GodotAppHudSwift.shared startWithApiKey:appId userID:userId observerMode:is_observer callback:^(BOOL result) {
        if (result) {
            if (GodotAppHud::get_instance() == NULL)
                return;
            NSLog(@"[GodotAppHud] start success!");
            GodotAppHud::get_instance()->call_deferred("emit_signal", "connected");
        }
    }];
    
    connect_to_amplitude();
 
    
    
}

void GodotAppHud::connect_to_amplitude() {
    Amplitude* instance = GodotAmplitude::get_amplitude_instancen();
    if (instance) {
        
        NSLog(@"[GodotAppHud] - connect to amplitude");
        if ([Apphud userID] && [[Apphud userID] length] > 0)
            [instance setUserId:[Apphud userID]];
        if ([Apphud deviceID] && [[Apphud deviceID] length] > 0)
            [instance setDeviceId:[Apphud deviceID]];
        
    }
}





void GodotAppHud::start_manually(String app_id, String user_id, String device_id, bool is_observer) { 
    NSString *appId = [NSString stringWithUTF8String:app_id.utf8()];
    NSString *userId = [NSString stringWithUTF8String:user_id.utf8()];
    NSString *deviceId = [NSString stringWithUTF8String:device_id.utf8()];
    
    if (user_id.empty()) {
        userId = nil;
    }
    
    if (device_id.empty()) {
        deviceId = nil;
    }
    
    [GodotAppHudSwift.shared startMannualyWithApiKey:appId userID:userId deviceID:deviceId observerMode:is_observer callback:^(BOOL result) {
        if (result) {
            if (GodotAppHud::get_instance() == NULL)
                return;
            NSLog(@"[GodotAppHud] start success!");
            GodotAppHud::get_instance()->call_deferred("emit_signal", "connected");
            
        }
    }];

    
}



void GodotAppHud::purchase_promo(String product_id, String discount_id) {
    [GodotAppHudSwift.shared purchasePromoWithProductId:[NSString stringWithUTF8String:product_id.utf8()]
                                              discontID:[NSString stringWithUTF8String:discount_id.utf8()]
                                               callback:^(NSDictionary<NSString *,NSString *> * result, BOOL success) {
        if (!result) return;
        if (result.count == 0) return;
        if (GodotAppHud::get_instance() == NULL) return;
        
        Dictionary dict = Utils::convert_ns_value_to_variant(result);
        GodotAppHud::get_instance()->call_deferred("emit_signal", "update_transaction", dict);
        if (success) {
            GodotAppHud::get_instance()->call_deferred("emit_signal", "purchase_success", dict);
        }
        else {
            GodotAppHud::get_instance()->call_deferred("emit_signal", "purchase_failed", dict);
        }
    }];
}



void GodotAppHud::request_product() {
    [GodotAppHudSwift.shared requestProductsWithPCallback:^(NSArray<NSDictionary<NSString *,id> *> *products) {
        NSLog(@"[GodotAppHud] OK! %@", products);
        
        if (!products) return;
        if (products.count == 0) return;
        if (GodotAppHud::get_instance() == NULL) return;
        
        for (NSDictionary<NSString *,id> * product in products) {
            Dictionary dict = Utils::convert_ns_value_to_variant(product);
            GodotAppHud::get_instance()->call_deferred("emit_signal", "update_product", dict);
        }
    }];
}

void GodotAppHud::request_transactions() {
    [GodotAppHudSwift.shared requestTransactionsWithPCallback:^(NSArray<NSDictionary<NSString *,NSString *> *> * transactions) {
        if (!transactions) return;
        if (transactions.count == 0) return;
        if (GodotAppHud::get_instance() == NULL) return;
        
        for (NSDictionary<NSString *,NSString *> * transaction in transactions) {
            Dictionary dict = Utils::convert_ns_value_to_variant(transaction);
            GodotAppHud::get_instance()->call_deferred("emit_signal", "update_transaction", dict);
        }
    }];
}

void GodotAppHud::restore_purchase() {
    [GodotAppHudSwift.shared restorePurchaseWithCallback:^(NSArray<NSDictionary<NSString *,NSString *> *> * transactions) {
        if (!transactions) return;
        if (transactions.count == 0) return;
        if (GodotAppHud::get_instance() == NULL) return;
        
        for (NSDictionary<NSString *,NSString *> * transaction in transactions) {
            Dictionary dict = Utils::convert_ns_value_to_variant(transaction);
            GodotAppHud::get_instance()->call_deferred("emit_signal", "update_transaction", dict);
        }
    }];
}

void GodotAppHud::purchase_product(String product_id) {
    [GodotAppHudSwift.shared purchaseWithProductId:[NSString stringWithUTF8String:product_id.utf8()]
                                          pCallback:^(NSDictionary<NSString *,NSString *> * result, BOOL success) {
        if (!result) return;
        if (result.count == 0) return;
        if (GodotAppHud::get_instance() == NULL) return;
        
        Dictionary dict = Utils::convert_ns_value_to_variant(result);
        GodotAppHud::get_instance()->call_deferred("emit_signal", "update_transaction", dict);
        if (success) {
            GodotAppHud::get_instance()->call_deferred("emit_signal", "purchase_success", dict);
        }
        else {
            GodotAppHud::get_instance()->call_deferred("emit_signal", "purchase_failed", dict);
        }
    }];
}

void GodotAppHud::log_out() { 
    [GodotAppHudSwift.shared logout];
}


String GodotAppHud::get_user_id() {
    return [Apphud userID].UTF8String;
}

String GodotAppHud::get_device_id() {
    return [Apphud deviceID].UTF8String;
}
