//
//  godot_firebase_core_delegate.h
//  godot_plugin_lib
//
//  Created by Admin on 07.02.2024.
//
#pragma once
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

@interface GodotFirebaseCoreDelegate: NSObject
-(instancetype)initWithGodot:(Object *)object;
-(void)authFromGameCenter;
-(void)signOut;
-(int)getAuthStatus;
-(void)clear;
@end
