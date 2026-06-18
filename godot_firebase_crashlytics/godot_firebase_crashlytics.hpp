//
//  godot_firebase_crashlytics.h
//  godot_plugin_lib
//
//  Created by Admin on 09.08.2024.
//

#import <Foundation/Foundation.h>

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




class GodotFirebaseCrashlytics : public Object {
    GDCLASS(GodotFirebaseCrashlytics, Object)
    
    
    static void _bind_methods();
    PrintHandlerList print_handler_list;
    ErrorHandlerList err_handler_list;
    
    bool _handler_setup = false;
    
public :
    GodotFirebaseCrashlytics();
    ~GodotFirebaseCrashlytics();
    
    void setup_print_handler();
    
    void log(const String &text);
    void set_custom_value(const String &key, const String &value);
    
    bool try_call(Object* obj, const String &method, const Array &args);
};

