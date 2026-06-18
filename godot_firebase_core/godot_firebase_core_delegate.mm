//
//  godot_firebase_core_delegate.m
//  godot_plugin_lib
//
//  Created by Admin on 07.02.2024.
//

#import "godot_firebase_core_delegate.h"
#import "godot_firebase_core.h"


#import <Firebase.h>


@implementation GodotFirebaseCoreDelegate {
    Object * _object;
    int status;
}

-(instancetype) initWithGodot:(Object *)object {
    self = [super init];
    if (self) {
        _object = object;
        status = ERR_UNAVAILABLE;
        //[FIRApp configure];
        
        print_verbose("[GodotFirebaseCoreDelegate] init with object" + object->to_string());
    }
    return self;
}

-(void) authFromGameCenter {

}

-(void) signOut {

}

-(int) getAuthStatus {
    return status;
}

-(void) clear {
    _object = nullptr;
}

@end
