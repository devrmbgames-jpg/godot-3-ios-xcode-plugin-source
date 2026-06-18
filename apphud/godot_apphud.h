//
//  godot_apphud.h
//  godot_plugin_lib
//
//  Created by Admin on 13.09.2024.
//


#pragma once

#include "core/version.h"

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




class GodotAppHud : public Object {
    GDCLASS(GodotAppHud, Object)

    static void _bind_methods();
    static GodotAppHud* _instance;
public:
    static GodotAppHud* get_instance();
    
    GodotAppHud();
    ~GodotAppHud();
    
    void start(String app_id, String user_id, bool is_observer);
    void start_manually(String app_id, String user_id, String device_id, bool is_observer);
    void request_transactions();
    void request_product();
    void restore_purchase();
    
    void connect_to_amplitude();
    
    void purchase_product(String product_id);
    void purchase_promo(String product_id, String discount_id);
    void log_out();
    
    String get_user_id();
    String get_device_id();
    
    
};
