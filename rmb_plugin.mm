//
//  rmb_plugin.cpp
//  godot_plugin
//
//  Created by Denis Belov on 3/9/22.
//  Copyright © 2022 Godot. All rights reserved.
//

#include "core/engine.h"
#include "godot_firebase_cloudmessage/godot_plugin_fbcloud_class.h"
#include "godot_firebase_analitics/godot_plugin_fb_analytics_class.h"
#include "spotlight/spotlight.h"
#include "appsharedialog/app_share_dialog.h"
#include "apple_event/godot_apple_event.h"
#include "apn/apn.h"
#include "rateme/rate_me.h"
#include "hepatic/ios_hepatic.h"


#include "godot_firebase_core.h"
#include "godot_firebase_crashlytics.hpp"

#include "store_kit_2/godot_store_kit_2.h"
#include "amlitude/godot_amplitude.h"
#include "apphud/godot_apphud.h"







class PluginManager {
    static Vector<Object*> plugins;
public :
    
    template<class T>
    static void add_singleton(const String &str = "") {
        T* ptr = memnew(T);
        if (str.empty()) {
            Engine::Singleton singleton = Engine::Singleton(ptr->get_class_static(), ptr);
            Engine::get_singleton()->add_singleton(singleton);
        }
        else {
            Engine::Singleton singleton = Engine::Singleton(str, ptr);
            Engine::get_singleton()->add_singleton(singleton);
        }
        
        plugins.push_back(ptr);
    }
    
    template<class T>
    static void register_class() {
        ClassDB::register_class<T>();
    }
    
    static void clear() {
        for (int i = 0; i < plugins.size(); i++) {
            Object* data = plugins[i];
            if (data)
                memdelete(data);
        }
        
        plugins.clear();
    }
};


Vector<Object*> PluginManager::plugins = Vector<Object*>();

void _add_singelot(const StringName &p_name = StringName(), Object *p_ptr = nullptr)
{
    Engine::get_singleton()->add_singleton(Engine::Singleton(p_name, p_ptr));
}

void rmb_plugin_init()
{
    
    PluginManager::add_singleton<APNPlugin>("APN");
    PluginManager::add_singleton<Spotlight>("Spotlight");
    PluginManager::add_singleton<GodotAppleEvent>("GodotAppleEvent");
    PluginManager::add_singleton<AppShareDialog>("AppShareDialog");
    PluginManager::add_singleton<FirebaseAnalytics>("FirebaseAnalytics");
    PluginManager::add_singleton<FirebaseCloudMessaging>("FirebaseCloudMessaging");
    PluginManager::add_singleton<RateMe>("RateMe");
    PluginManager::add_singleton<GodotFirebaseCrashlytics>("GodotFirebaseCrashlytics");
    
    PluginManager::register_class<GodotFirebaseCore>();
    
    PluginManager::add_singleton<GodotStoreKit2>("GodotStoreKit2");
    PluginManager::add_singleton<GodotAmplitude>("GodotAmplitude");
    PluginManager::add_singleton<GodotAppHud>("GodotAppHud");
    PluginManager::add_singleton<GodotIOSHepatic>("GodotIOSHepatic");

    
    print_verbose("register finished");    
}



void rmb_plugin_deinit()
{
    PluginManager::clear();
}


