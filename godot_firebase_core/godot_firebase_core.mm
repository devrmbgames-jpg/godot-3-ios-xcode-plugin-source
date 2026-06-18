//
//  godot_firebase_core.cpp
//  godot_plugin_lib
//
//  Created by Admin on 07.02.2024.
//
#include "godot_firebase_core.h"


const String GodotFirebaseCore::signal_auth_from_game_center_completed = "auth_from_game_center_completed";
const String GodotFirebaseCore::signal_sign_out = "sign_out";

GodotFirebaseCore::GodotFirebaseCore() {
    _delegate = [[GodotFirebaseCoreDelegate alloc] initWithGodot:this];
}

GodotFirebaseCore::~GodotFirebaseCore() {
    [_delegate clear];
    _delegate = nil;
}

void GodotFirebaseCore::_bind_methods() {
    ClassDB::bind_method(D_METHOD("auth_from_game_center"),&GodotFirebaseCore::auth_from_game_center);
    ClassDB::bind_method(D_METHOD("sign_out"),&GodotFirebaseCore::sign_out);
    
    
    ADD_SIGNAL(MethodInfo(signal_auth_from_game_center_completed,
                          PropertyInfo(Variant::STRING, "uuid"),
                          PropertyInfo(Variant::INT, "err_code"),
                          PropertyInfo(Variant::STRING, "error")));
    ADD_SIGNAL(MethodInfo(signal_sign_out));
}

void GodotFirebaseCore::auth_from_game_center() {
    [_delegate authFromGameCenter];
}

void GodotFirebaseCore::sign_out() {
    [_delegate signOut];
}

int GodotFirebaseCore::get_status_auth() {
    return [_delegate getAuthStatus];
}
