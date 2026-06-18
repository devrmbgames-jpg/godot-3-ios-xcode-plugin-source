//
//  ios_hepatic.h
//  godot_plugin_lib
//
//  Created by Admin on 26.05.2025.
//

#ifndef ios_hepatic_h
#define ios_hepatic_h


#pragma once

#import <CoreHaptics/CoreHaptics.h>
#import <Foundation/Foundation.h>

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

class GodotIOSHepatic : public Object {
    GDCLASS(GodotIOSHepatic, Object)

    static void _bind_methods();
    bool is_support;
    CHHapticEngine *engine;
    static bool _inited;
    int _index = 0;
    
public:
    GodotIOSHepatic();
    ~GodotIOSHepatic();
    
    void play(int type, float delay);
    void restart();
    
    
};



#endif /* ios_hepatic_h */
