//
//  godot_amplitude.h
//  godot_plugin_lib
//
//  Created by Admin on 24.07.2024.
//

#pragma once

#include "core/version.h"
@import AmplitudeSwift;

#if VERSION_MAJOR == 4
#include "core/object/class_db.h"
#else
#include "core/object.h"
#include "core/reference.h"
#include "core/image.h"
#include "core/variant.h"
#include "core/script_language.h"
#include "core/string_name.h"
#include "core/ref_ptr.h"
#endif




class GodotAmplitude : public Object {
    GDCLASS(GodotAmplitude, Object)

    static void _bind_methods();
    
    static Amplitude *_amplitude;
    static AMPConfiguration *_configuration;
    
public:
    
    
    GodotAmplitude();
    ~GodotAmplitude();
    
    void init_sdk();
    void init_config(String api_key);
    void connect_to_apphud();
    
    void config_flush_interval_millis(int millis);
    void config_flush_queue_size(int queue);
    void config_flush_max_retries(int times);
    void config_min_id_length(int length);
    void config_identify_batch_interval_millis(int millis);
    void config_flush_events_on_close(bool val);
    void config_opt_out(bool val);
    void config_min_time_between_sessions_millis(int millis);
    void config_server_url(String url);
    void config_server_zone(String zone);
    void config_use_batch(bool val);
    void config_enable_coppa_control(bool val);
    void config_migrate_legacy_data(bool val);
    void config_offline(bool val);
    
    static Amplitude * get_amplitude_instancen();
    // OFF = 0
    // ERROR = 1
    // WARN = 2
    // LOG = 3
    // DEBUG = 4
    void config_log_level(int level);
    
    
    
    void track_disable_carrier();
    void track_disable_city();
    void track_disable_country();
    void track_disable_device_model();
    void track_disable_device_manifacturer();
    void track_disable_DMA();
    void track_disable_ip_address();
    void track_disable_language();
    void track_disable_IDFV();
    void track_disable_os_name();
    void track_disable_os_version();
    void track_disable_platform();
    void track_disable_region();
    void track_disable_version_name();
    
    void log_event(String event, Dictionary dict);
    
    void log_revenue(String product, int quantity, float price, Dictionary opts);
    
    
    String get_device_id();
    String get_user_id();
    void set_user_id(String idfv);
    void set_device_id(String idfa);
    
    
};
