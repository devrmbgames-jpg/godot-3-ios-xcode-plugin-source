//
//  utils.h
//  godot_plugin_lib
//
//  Created by Admin on 18.12.2024.
//

#pragma once

#ifndef utils_h
#define utils_h

#include <Foundation/Foundation.h>


#include "core/version.h"

#if VERSION_MAJOR == 4
#include "core/object/class_db.h"
#else
#include "core/object.h"
#include "core/reference.h"
#include "core/variant.h"
#include "core/script_language.h"
#include "core/string_name.h"
#endif

struct Utils {
    //static String convert_ns_string_to_string(NSString* ns_val);
    //static Dictionary convert_ns_dict_str_to_dict(NSDictionary<NSString*, NSString*>* ns_val);
    //static Array convert_ns_arr_dict_str_to_arr(NSArray<NSDictionary<NSString*, NSString*>*>* ns_val);
    //static Dictionary convert_ns_dict_any_to_dict(NSDictionary<NSString*, id>* ns_val);
    //static Array convert_ns_arr_dict_any_to_arr(NSArray<NSDictionary<NSString*, id>*>* ns_val);
    static Variant convert_ns_value_to_variant(id ns_value);
};

#endif /* utils_h */
