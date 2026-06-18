//
//  utils.m
//  godot_plugin_lib
//
//  Created by Admin on 18.12.2024.
//

#include "utils.h"
#import <Foundation/Foundation.h>

Variant Utils::convert_ns_value_to_variant(id ns_value) {
    if (ns_value == nil) {
        return Variant(); // Возвращаем пустой Variant для nil
    }
    else if ([ns_value isKindOfClass:[NSString class]]) {
        NSString *string_value = (NSString *)ns_value;
        return String(string_value.UTF8String ? string_value.UTF8String : "");
    }
    else if ([ns_value isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)ns_value;

        if (CFNumberIsFloatType((CFNumberRef)number)) {
            return number.floatValue;
        }
        if (strcmp([number objCType], @encode(BOOL)) == 0) {
            return number.boolValue ? true : false;
        }
        return number.intValue;
    }
    else if ([ns_value isKindOfClass:[NSDictionary class]]) {
        Dictionary dict;
        NSDictionary *ns_dict = (NSDictionary *)ns_value;

        for (id key in ns_dict) {
            Variant godot_key;

            // Проверяем тип ключа
            if ([key isKindOfClass:[NSString class]]) {
                NSString *string_key = (NSString *)key;
                godot_key = String(string_key.UTF8String ? string_key.UTF8String : "");
            } else if ([key isKindOfClass:[NSNumber class]]) {
                NSNumber *number_key = (NSNumber *)key;

                if (CFNumberIsFloatType((CFNumberRef)number_key)) {
                    godot_key = number_key.floatValue;
                } else {
                    godot_key = number_key.intValue;
                }
            } else {
                // Если ключ не поддерживается, пропускаем
                NSLog(@"[convert_ns_value_to_variant] Skipping unsupported key type: %@", [key class]);
                continue;
            }

            // Конвертация значения
            Variant godot_value = convert_ns_value_to_variant(ns_dict[key]);
            dict[godot_key] = godot_value;
        }
        return dict;
    }
    else if ([ns_value isKindOfClass:[NSDictionary<NSString*, NSString*> class]]) {
        Dictionary dict;
        NSDictionary<NSString*, NSString*> *ns_dict = (NSDictionary<NSString*, NSString*> *)ns_value;

        for (id key in ns_dict) {
            Variant godot_key;

            // Проверяем тип ключа
            if ([key isKindOfClass:[NSString class]]) {
                NSString *string_key = (NSString *)key;
                godot_key = String(string_key.UTF8String ? string_key.UTF8String : "");
            } else {
                // Если ключ не поддерживается, пропускаем
                NSLog(@"[convert_ns_value_to_variant] Skipping unsupported key type: %@", [key class]);
                continue;
            }

            // Конвертация значения
            Variant godot_value = convert_ns_value_to_variant(ns_dict[key]);
            dict[godot_key] = godot_value;
        }
        return dict;
    }
    else if ([ns_value isKindOfClass:[NSDictionary<NSString*, id> class]]) {
        Dictionary dict;
        NSDictionary<NSString*, id> *ns_dict = (NSDictionary<NSString*, id> *)ns_value;

        for (id key in ns_dict) {
            Variant godot_key;

            // Проверяем тип ключа
            if ([key isKindOfClass:[NSString class]]) {
                NSString *string_key = (NSString *)key;
                godot_key = String(string_key.UTF8String ? string_key.UTF8String : "");
            } else {
                // Если ключ не поддерживается, пропускаем
                NSLog(@"[convert_ns_value_to_variant] Skipping unsupported key type: %@", [key class]);
                continue;
            }

            // Конвертация значения
            Variant godot_value = convert_ns_value_to_variant(ns_dict[key]);
            dict[godot_key] = godot_value;
        }
        return dict;
    }
    else if ([ns_value isKindOfClass:[NSArray class]]) {
        Array arr;
        NSArray *ns_arr = (NSArray *)ns_value;

        for (id element in ns_arr) {
            arr.append(convert_ns_value_to_variant(element));
        }
        return arr;
    }
    else if ([ns_value isKindOfClass:[NSArray<id> class]]) {
        Array arr;
        NSArray<id> *ns_arr = (NSArray<id> *)ns_value;

        for (id element in ns_arr) {
            arr.append(convert_ns_value_to_variant(element));
        }
        return arr;
    }
    else if ([ns_value isKindOfClass:[NSArray<NSDictionary<NSString*, NSString*>*> class]]) {
        Array arr;
        NSArray<NSDictionary<NSString*, NSString*>*> *ns_arr = (NSArray<NSDictionary<NSString*, NSString*>*> *)ns_value;

        for (id element in ns_arr) {
            arr.append(convert_ns_value_to_variant(element));
        }
        return arr;
    }
    else if ([ns_value isKindOfClass:[NSArray<NSDictionary<NSString*, id>*> class]]) {
        Array arr;
        NSArray<NSDictionary<NSString*, id>*> *ns_arr = (NSArray<NSDictionary<NSString*, id>*> *)ns_value;

        for (id element in ns_arr) {
            arr.append(convert_ns_value_to_variant(element));
        }
        return arr;
    }
    else if ([ns_value isKindOfClass:[NSArray<id> class]]) {
        Array arr;
        NSArray<id> *ns_arr = (NSArray<id> *)ns_value;

        for (id element in ns_arr) {
            arr.append(convert_ns_value_to_variant(element));
        }
        return arr;
    }
    else if ([ns_value isKindOfClass:[NSNull class]]) {
        return Variant();
    }

    NSLog(@"[convert_ns_value_to_variant] Unsupported type: %@", [ns_value class]);
    return Variant();
}
