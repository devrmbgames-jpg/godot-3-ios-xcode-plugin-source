//
//  godot_firebase_crashlytics.m
//  godot_plugin_lib
//
//  Created by Admin on 09.08.2024.
//

#include "godot_firebase_crashlytics.hpp"

#import <FirebaseCrashlytics/FIRCrashlytics.h>



void GodotFirebaseCrashlytics::_bind_methods() {
    ClassDB::bind_method(D_METHOD("log"), &GodotFirebaseCrashlytics::log);
    ClassDB::bind_method(D_METHOD("set_custom_value"), &GodotFirebaseCrashlytics::set_custom_value);
    ClassDB::bind_method(D_METHOD("try_call"), &GodotFirebaseCrashlytics::try_call);
    ClassDB::bind_method(D_METHOD("setup_print_handler"), &GodotFirebaseCrashlytics::setup_print_handler);
}


GodotFirebaseCrashlytics::GodotFirebaseCrashlytics() {
    print_handler_list.printfunc = [](void *, const String &p_string, bool p_error) -> void {
        
        if (p_error) {
            [FIRCrashlytics.crashlytics log:[NSString stringWithUTF8String:("ERROR: " + p_string).utf8()]];
        }
        else {
            [FIRCrashlytics.crashlytics log:[NSString stringWithUTF8String:p_string.utf8()]];
        }
        
    };
    
    
    err_handler_list.errfunc = [](void *,
                                  const char *p_function,
                                  const char *p_file,
                                  int p_line,
                                  const char *p_error,
                                  const char *p_message,
                                  ErrorHandlerType p_type) -> void {
       
        String err_details = String((p_message && *p_message) ? p_message : p_error);
        String text = (
                       String("ERROR: ") + err_details +
                       "\n   at: " + String(p_function) +
                       "  (" + String(p_file) + ":" + String::num(p_line) + ")");
  
        
        [FIRCrashlytics.crashlytics log:[NSString stringWithUTF8String:text.utf8()]];
        
    };
    
}

GodotFirebaseCrashlytics::~GodotFirebaseCrashlytics() {
    if (_handler_setup) {
        remove_print_handler(&print_handler_list);
        remove_error_handler(&err_handler_list);
        _handler_setup = false;
    }
}


void GodotFirebaseCrashlytics::setup_print_handler() {
    if (_handler_setup) {
        return;
    }
    _handler_setup = true;
    
    
    add_print_handler(&print_handler_list);
    add_error_handler(&err_handler_list);
    
}

void GodotFirebaseCrashlytics::log(const String &text) {
    [FIRCrashlytics.crashlytics log:[NSString stringWithUTF8String:text.utf8()]];
}


void GodotFirebaseCrashlytics::set_custom_value(const String &key, const String &value) { 
    [FIRCrashlytics.crashlytics setCustomValue:[NSString stringWithUTF8String:value.utf8()]
                                        forKey:[NSString stringWithUTF8String:key.utf8()]
    ];
    
}

bool GodotFirebaseCrashlytics::try_call(Object* obj, const String &method, const Array &args) {
    
    if (!obj)
        return false;
    
    @try {
        if (args.empty()) {
            obj->call(method);
        }
        else {
            obj->callv(method, args);
        }
    } @catch (...) {
        return false;
    }
    
    return true;
}

