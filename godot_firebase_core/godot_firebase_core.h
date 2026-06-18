//
//  godot_firebase_core.hpp
//  godot_plugin_lib
//
//  Created by Admin on 07.02.2024.
//

#pragma once

#import "godot_firebase_core_delegate.h"
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




class GodotFirebaseCore : public Reference {
    GDCLASS(GodotFirebaseCore, Reference)

    static void _bind_methods();
    
    GodotFirebaseCoreDelegate * _delegate;
    
public:
    
    static const String signal_auth_from_game_center_completed;
    static const String signal_sign_out;
    
    GodotFirebaseCore();
    ~GodotFirebaseCore();
    
    void auth_from_game_center();
    void sign_out();
    int get_status_auth();
    
    
    
};

