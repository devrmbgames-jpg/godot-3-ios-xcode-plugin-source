//
//  godot_amplitude.m
//  godot_plugin_lib
//
//  Created by Admin on 24.07.2024.
//

#import "godot_amplitude.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Game-Swift.h>
@import AmplitudeSwift;
@import ApphudSDK;


Amplitude* GodotAmplitude::_amplitude = nil;
AMPConfiguration* GodotAmplitude::_configuration = nil;

GodotAmplitude::GodotAmplitude() {
}

GodotAmplitude::~GodotAmplitude() {
    _amplitude = nil;
    _configuration = nil;
}

void GodotAmplitude::_bind_methods() {
    
    ClassDB::bind_method(D_METHOD("init_sdk"), &GodotAmplitude::init_sdk);
    ClassDB::bind_method(D_METHOD("init_config"), &GodotAmplitude::init_config);
    
    ClassDB::bind_method(D_METHOD("config_flush_interval_millis"), &GodotAmplitude::config_flush_interval_millis);
    ClassDB::bind_method(D_METHOD("config_flush_queue_size"), &GodotAmplitude::config_flush_queue_size);
    ClassDB::bind_method(D_METHOD("config_flush_max_retries"), &GodotAmplitude::config_flush_max_retries);
    ClassDB::bind_method(D_METHOD("config_min_id_length"), &GodotAmplitude::config_min_id_length);
    ClassDB::bind_method(D_METHOD("config_identify_batch_interval_millis"), &GodotAmplitude::config_identify_batch_interval_millis);
    ClassDB::bind_method(D_METHOD("config_flush_events_on_close"), &GodotAmplitude::config_flush_events_on_close);
    ClassDB::bind_method(D_METHOD("config_opt_out"), &GodotAmplitude::config_opt_out);
    ClassDB::bind_method(D_METHOD("config_min_time_between_sessions_millis"), &GodotAmplitude::config_min_time_between_sessions_millis);
    ClassDB::bind_method(D_METHOD("config_server_url"), &GodotAmplitude::config_server_url);
    ClassDB::bind_method(D_METHOD("config_server_zone"), &GodotAmplitude::config_server_zone);
    ClassDB::bind_method(D_METHOD("config_use_batch"), &GodotAmplitude::config_use_batch);
    ClassDB::bind_method(D_METHOD("config_enable_coppa_control"), &GodotAmplitude::config_enable_coppa_control);
    ClassDB::bind_method(D_METHOD("config_migrate_legacy_data"), &GodotAmplitude::config_migrate_legacy_data);
    ClassDB::bind_method(D_METHOD("config_offline"), &GodotAmplitude::config_offline);
    ClassDB::bind_method(D_METHOD("config_log_level"), &GodotAmplitude::config_log_level);
    
    ClassDB::bind_method(D_METHOD("track_disable_carrier"), &GodotAmplitude::track_disable_carrier);
    ClassDB::bind_method(D_METHOD("track_disable_city"), &GodotAmplitude::track_disable_city);
    ClassDB::bind_method(D_METHOD("track_disable_country"), &GodotAmplitude::track_disable_country);
    ClassDB::bind_method(D_METHOD("track_disable_device_model"), &GodotAmplitude::track_disable_device_model);
    ClassDB::bind_method(D_METHOD("track_disable_device_manifacturer"), &GodotAmplitude::track_disable_device_manifacturer);
    ClassDB::bind_method(D_METHOD("track_disable_DMA"), &GodotAmplitude::track_disable_DMA);
    ClassDB::bind_method(D_METHOD("track_disable_ip_address"), &GodotAmplitude::track_disable_ip_address);
    ClassDB::bind_method(D_METHOD("track_disable_language"), &GodotAmplitude::track_disable_language);
    ClassDB::bind_method(D_METHOD("track_disable_IDFV"), &GodotAmplitude::track_disable_IDFV);
    ClassDB::bind_method(D_METHOD("track_disable_os_name"), &GodotAmplitude::track_disable_os_name);
    ClassDB::bind_method(D_METHOD("track_disable_os_version"), &GodotAmplitude::track_disable_os_version);
    ClassDB::bind_method(D_METHOD("track_disable_platform"), &GodotAmplitude::track_disable_platform);
    ClassDB::bind_method(D_METHOD("track_disable_region"), &GodotAmplitude::track_disable_region);
    ClassDB::bind_method(D_METHOD("track_disable_version_name"), &GodotAmplitude::track_disable_version_name);
    
    ClassDB::bind_method(D_METHOD("get_device_id"), &GodotAmplitude::get_device_id);
    ClassDB::bind_method(D_METHOD("get_user_id"), &GodotAmplitude::get_user_id);
    ClassDB::bind_method(D_METHOD("set_user_id"), &GodotAmplitude::set_user_id);
    ClassDB::bind_method(D_METHOD("set_device_id"), &GodotAmplitude::set_device_id);

    ClassDB::bind_method(D_METHOD("connect_to_apphud"), &GodotAmplitude::connect_to_apphud);
    ClassDB::bind_method(D_METHOD("log_event"), &GodotAmplitude::log_event);
    /*
        String product,
        int quantity,
        float price,
        String revenue_type,
        String receipt,
        String receipt_signature
     */
    ClassDB::bind_method(D_METHOD("log_revenue", "product_id", "quantity", "price", "opts"), &GodotAmplitude::log_revenue);
    
}

void GodotAmplitude::init_sdk() {
    if (_amplitude != nil) {
        NSLog(@"[AMP ERROR] amplitude has inited!");
        return;
    }
    GodotAMPFix* fix = [[GodotAMPFix alloc] init];
    [fix removeLegacyAmplitudeDatabaseWithInstanceName: @""];
    _configuration.migrateLegacyData = false;
    _amplitude = [Amplitude initWithConfiguration:_configuration];
    
    connect_to_apphud();
    
    if (_amplitude != nil) {
        UIDevice *device = [UIDevice currentDevice];

        NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
        if (currentDeviceId != nil && [currentDeviceId length] > 0) {
            if (_amplitude.getUserId == nil) {
                [_amplitude setUserId:currentDeviceId];
            }
            if (_amplitude.getDeviceId == nil) {
                [_amplitude setDeviceId:currentDeviceId];
            }
        }
    }
    NSLog(@"[AMP INFO] - inited");
    
}

void GodotAmplitude::connect_to_apphud() {
    NSLog(@"[AMP INFO] connect to apphud!");
    if (_amplitude != nil) {
        if ([Apphud userID] != nil && [[Apphud userID] length] > 0)
            [_amplitude setUserId:[Apphud userID]];
        if ([Apphud deviceID] != nil && [[Apphud deviceID] length] > 0)
            [_amplitude setDeviceId:[Apphud deviceID]];
    }
}

Amplitude* GodotAmplitude::get_amplitude_instancen() {
    return _amplitude;
}

void GodotAmplitude::init_config(String api_key) {
    
    if (_configuration != nil) {
        NSLog(@"[AMP ERROR] amplitude configuration has inited!");
        return;
    }
    
    
    NSString *ns_api_key = [NSString stringWithUTF8String:api_key.utf8()];
    NSLog(@"[AMP INFO] amplitude init with api: %@", ns_api_key);
    _configuration = [AMPConfiguration initWithApiKey:ns_api_key];
    _configuration.logLevel = AMPLogLevelWARN;
    
    _configuration.loggerProvider = ^(NSInteger logLevel, NSString*  message) {
        if (!message) return;
        
        switch(logLevel) {
            case AMPLogLevelERROR: {
                NSLog(@"[AMP ERROR] %@", message);
                break;
            }
            case AMPLogLevelWARN: {
                NSLog(@"[AMP WARRNING] %@", message);
                break;
            }
            case AMPLogLevelLOG: {
                NSLog(@"[AMP LOG] %@", message);
                break;
            }
            case AMPLogLevelDEBUG: {
                NSLog(@"[AMP DEBUG] %@", message);
                break;
            }
        }
    };
    
    NSLog(@"[AMP INFO] init config");
}


#pragma mark CONFIG

void GodotAmplitude::config_flush_interval_millis(int millis) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.flushIntervalMillis = millis;
}

void GodotAmplitude::config_flush_queue_size(int queue) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.flushQueueSize = queue;
}

void GodotAmplitude::config_flush_max_retries(int times) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.flushMaxRetries = times;
}

void GodotAmplitude::config_min_id_length(int length) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.minIdLength = length;
}

void GodotAmplitude::config_identify_batch_interval_millis(int millis) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.identifyBatchIntervalMillis = millis;
}

void GodotAmplitude::config_flush_events_on_close(bool val) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.flushEventsOnClose = val;
}

void GodotAmplitude::config_opt_out(bool val) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.optOut = val;
}

void GodotAmplitude::config_min_time_between_sessions_millis(int millis) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.minTimeBetweenSessionsMillis = millis;
}

void GodotAmplitude::config_server_url(String url) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.serverUrl = [NSString stringWithUTF8String:url.utf8()];
}

void GodotAmplitude::config_server_zone(String zone) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.serverZone = zone == "US" ? AMPServerZoneUS : AMPServerZoneEU;
}

void GodotAmplitude::config_use_batch(bool val) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.useBatch = val;
}


void GodotAmplitude::config_enable_coppa_control(bool val) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.enableCoppaControl = val;
}

void GodotAmplitude::config_migrate_legacy_data(bool val) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.migrateLegacyData = val;
}

void GodotAmplitude::config_offline(bool val) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    return;
}

void GodotAmplitude::config_log_level(int level) {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    _configuration.logLevel = AMPLogLevel(level);
}

#pragma mark TRAKING OPTIONS


void GodotAmplitude::track_disable_carrier() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackCarrier];
}

void GodotAmplitude::track_disable_city() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackCity];
}

void GodotAmplitude::track_disable_country() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackCountry];
}

void GodotAmplitude::track_disable_device_model() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackDeviceModel];
}

void GodotAmplitude::track_disable_device_manifacturer() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackDeviceManufacturer];
}

void GodotAmplitude::track_disable_DMA() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackDMA];
}

void GodotAmplitude::track_disable_ip_address() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackIpAddress];
}

void GodotAmplitude::track_disable_language() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackLanguage];
}

void GodotAmplitude::track_disable_IDFV() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackIDFV];
}

void GodotAmplitude::track_disable_os_name() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackOsName];
}

void GodotAmplitude::track_disable_os_version() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackOsVersion];
}

void GodotAmplitude::track_disable_platform() {
    if (!_configuration) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackPlatform];
}

void GodotAmplitude::track_disable_region() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackRegion];
}

void GodotAmplitude::track_disable_version_name() {
    if (_configuration == nil) {
        NSLog(@"[AMP ERROR] Configuration is null!");
        return;
    }
    [_configuration.trackingOptions disableTrackVersionName];
}

#pragma mark TRACKING

void GodotAmplitude::log_event(String event, Dictionary dict) {
    if (_amplitude == nil) {
        NSLog(@"[AMP ERROR] Amplitude is null!");
        return;
    }
    

    NSString* event_name = [NSString stringWithUTF8String:event.utf8()];
    if (dict.empty()) {
        AMPBaseEvent* event = [AMPBaseEvent initWithEventType:event_name];
        [_amplitude track:event];
    }
    else {
        NSMutableDictionary<NSString*, NSString*>* propertyes = [[NSMutableDictionary<NSString*, NSString*> alloc] initWithCapacity:dict.size()];
        
        Array keys = dict.keys();
        
        for (int i = 0; i < keys.size(); i++) {
            String key = String(dict.get_key_at_index(i));
            String value = String(dict.get_value_at_index(i));
            
            
            NSString *ns_key = [NSString stringWithUTF8String:key.utf8()];
            NSString *ns_value = [NSString stringWithUTF8String:value.utf8()];
            propertyes[ns_key] = ns_value;
        }
        
        AMPBaseEvent* event = [AMPBaseEvent initWithEventType:event_name eventProperties:propertyes];
        [_amplitude track:event];
        
    }
}



void GodotAmplitude::log_revenue(String product, int quantity, float price, Dictionary opts) {
    if (_amplitude == nil) {
        NSLog(@"[AMP ERROR] Amplitude is null!");
        return;
    }
    
    AMPRevenue* revenue = [AMPRevenue new];
    revenue.productId = [NSString stringWithUTF8String:product.utf8()];
    revenue.quantity = quantity;
    revenue.price = price;
    
    if (opts.has("revenue_type")) {
        String str = opts.get("revenue_type", "");
        if (!str.empty())
            revenue.revenueType = [NSString stringWithUTF8String:str.utf8()];
    }
    
    if (opts.has("receipt_sig") && opts.has("receipt")) {
        String receiptSig = opts.get("receipt_sig", "");
        String receipt = opts.get("receipt", "");
        
        
        [revenue setReceipt:[NSString stringWithUTF8String:receipt.utf8()]
           receiptSignature:[NSString stringWithUTF8String:receiptSig.utf8()]];
    }
    
    [_amplitude revenue:revenue];
}

String GodotAmplitude::get_device_id() {
    if (_amplitude == nil) {
        NSLog(@"[AMP ERROR] Amplitude is null!");
        return "";
    }
    
    return [_amplitude.getDeviceId UTF8String];
}

String GodotAmplitude::get_user_id() {
    if (_amplitude == nil) {
        return "";
    }
    
    return [_amplitude.getUserId UTF8String];
}

void GodotAmplitude::set_user_id(String user_id) {
    if (!_amplitude) {
        NSLog(@"[AMP ERROR] Amplitude is null!");
        return;
    }
    NSString *user = [NSString stringWithUTF8String:user_id.utf8()];
    if (user != nil && user.length > 0)
        [_amplitude setUserId: [NSString stringWithUTF8String:user_id.utf8()]];
}

void GodotAmplitude::set_device_id(String idfa) {
    if (!_amplitude) {
        return;
    }
    
    NSString* device = [NSString stringWithUTF8String:idfa.utf8()];
    if (device != nil && device.length > 0)
        [_amplitude setDeviceId:[NSString stringWithUTF8String:idfa.utf8()]];
}



