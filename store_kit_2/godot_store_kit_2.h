//
//  godot_store_kit_2.h
//  godot_plugin_lib
//
//  Created by Admin on 26.07.2024.
//

#pragma once

#include "core/version.h"


#if VERSION_MAJOR == 4
    #include "core/object/class_db.h"
#else
    #include "core/object.h"
    #include "core/reference.h"
    #include "core/resource.h"
    #include "core/variant.h"
    #include "core/string_name.h"
    #include "core/ref_ptr.h"
#endif

class GodotStoreKit2 : public Object {
    GDCLASS(GodotStoreKit2, Object)
    
    static void _bind_methods();
    
    static const String signal_update_products_list;
    static const String signal_update_transaction_list;
    static const String signal_purchased;
    static const String signal_purchase_deferred;
    static const String signal_store_sync;
    static const String signal_update_region;
    
    String _current_region;
    String _purchase_deferred;
    bool _inited = false;
    
public:
    GodotStoreKit2();
    ~GodotStoreKit2();
    
    void init_store();
    void request_products(PoolStringArray skus);
    void request_purchased(PoolStringArray skus);
    void purchase_product(String sku, int quantity);
    void restore_all();
    void store_sync();
    void request_region();
    void purchase_deferred_force();
    void purchase_deferred_clear();
    void set_finished_transaction(bool val);
    void transaction_finish(uint64_t id);
    void show_manage_subscriptions();
    String get_purchase_deferred() const;
    
    
    String get_region() const;
    
    int get_screen_orientation() const;
    
};
