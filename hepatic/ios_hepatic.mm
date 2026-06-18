//
//  ios_hepatic.m
//  godot_plugin_lib
//
//  Created by Admin on 26.05.2025.
//

#import "ios_hepatic.h"
#import <Foundation/Foundation.h>
#import <CoreHaptics/CoreHaptics.h>

#import "platform/iphone/godot_app_delegate.h"

bool GodotIOSHepatic::_inited = false;

GodotIOSHepatic::GodotIOSHepatic() {
    is_support = CHHapticEngine.capabilitiesForHardware.supportsHaptics;
    _index = 0;
    if (is_support) {
        NSError* err;
        engine = [[CHHapticEngine alloc] initAndReturnError:&err];
        if (err) {
            NSLog(@"Haptics res: - %@", err.description);
        }
        
        
        
        [engine setStoppedHandler:^(CHHapticEngineStoppedReason stoppedReason) {
            if (_inited && stoppedReason) {
                NSLog(@"Haptic Stopped!");
                call_deferred("emit_signal", "drop");
            }
        }];
        
       
        [engine setResetHandler:^{
            if (_inited && engine) {
                NSError *error;
                [engine startAndReturnError:&error];
                if (error) {
                    NSLog(@"Haptic error: %@", error.description);
                }
            }
        }];
    }
    else {
        NSLog(@"Haptic Platform unsupported!");
    }
    
    _inited = true;
}

GodotIOSHepatic::~GodotIOSHepatic() {
    _inited = false;
    _index = 0;
}

void GodotIOSHepatic::_bind_methods() {
    ClassDB::bind_method(D_METHOD("play"), &GodotIOSHepatic::play);
    ClassDB::bind_method(D_METHOD("restart"), &GodotIOSHepatic::restart);

    ADD_SIGNAL(MethodInfo("drop"));
}




void GodotIOSHepatic::play(int type, float delay) {
    if (!is_support) {
        NSLog(@"Haptic is not supported!");
        return;
    }
    if (!engine) {
        NSLog(@"Haptic engine is null!");
        return;
    }
    
    
    CHHapticEventType t = CHHapticEventTypeHapticTransient;
    if (type == 0) {
        t = CHHapticEventTypeHapticTransient;
    }
    if (type == 1) {
        t = CHHapticEventTypeHapticContinuous;
    }
    if (type == 2) {
        t = CHHapticEventTypeAudioContinuous;
    }
    if (type == 3) {
        t = CHHapticEventTypeAudioCustom;
    }
    NSDictionary* hapticDict = @{
        CHHapticPatternKeyPattern: @[
            @{
                CHHapticPatternKeyEvent: @{
                    CHHapticPatternKeyEventType: t,
                    CHHapticPatternKeyTime: @(CHHapticTimeImmediate),
                    CHHapticPatternKeyEventDuration: [NSNumber numberWithFloat:delay],
                },
            },
        ],
    };
    
    NSError *error = nil;
    CHHapticPattern *pattern = [[CHHapticPattern alloc] initWithDictionary:hapticDict error:&error];
    if (error) {
        NSLog(@"Haptic error: %@", error.description);
        return;
    }
    
    
    id<CHHapticPatternPlayer> player = [engine createPlayerWithPattern:pattern error:&error];
    if (error) {
        NSLog(@"Haptic error: %@", error.description);
        return;
    }
    
    [engine notifyWhenPlayersFinished:^CHHapticEngineFinishedAction(NSError *error) {
        return CHHapticEngineFinishedActionStopEngine;
    }];
    
    
    [engine startWithCompletionHandler:^(NSError *error) {
        if (!_inited) return;
        
        NSError* err;
        [player startAtTime:0 error:&err];
        if (err) {
            NSLog(@"Haptic error: %@", error.description);
        }
    }];
    
    
}

void GodotIOSHepatic::restart() {
    NSError *error;
    [engine startAndReturnError:&error];
    if (error) {
        NSLog(@"Haptic error: %@", error.description);
    }
}
