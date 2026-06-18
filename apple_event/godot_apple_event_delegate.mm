
#import "godot_apple_event_delegate.h"
#import "godot_apple_event.h"

#import "platform/iphone/godot_app_delegate.h"

struct AppleEventInitializer {

	AppleEventInitializer() {
        
		[GodotApplicalitionDelegate addService:[GodotAppleEventDelegate shared]];
	}
};
static AppleEventInitializer initializer;


__attribute__((constructor))
static void apple_event_loaded(void) {
    NSLog(@"APPLE_EVENT FILE LOADED");
}
@interface GodotAppleEventDelegate ()

@end



@implementation GodotAppleEventDelegate

- (instancetype)init {
    self = [super init];
    return self;
}

+ (instancetype)shared {
    static GodotAppleEventDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GodotAppleEventDelegate alloc] init];
    });
    return sharedInstance;
}


- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
 
    NSLog(@"APPLE_EVENT launching options: %@", launchOptions);
    NSLog(@"DEEPLINK APPLE_EVENT launching options: %@", launchOptions);
    NSURL *url = launchOptions[UIApplicationLaunchOptionsURLKey];
    NSLog(@"APPLE_EVENT URL = %@", url);
    for (id value in launchOptions.allValues) {
        NSLog(@"APPLE_EVENT \\-- VALUE::: %@", value);
        
        if ([value isKindOfClass:[NSURL class]]) {
            NSURL* url = (NSURL*)value;
            String url_godot = url.absoluteString.UTF8String;
            if (!url_godot.empty()) {
                GodotAppleEvent::last_event = url_godot;
            }
            
            GodotAppleEvent* apple_event = GodotAppleEvent::get_singleton();
            if (apple_event) {
                apple_event->open_url(url_godot);
            }
        }
        else if ([value isKindOfClass:[NSString class]]) {
            NSString* url = (NSString*)value;
            String url_godot = url.UTF8String;
            if (!url_godot.empty()) {
                GodotAppleEvent::last_event = url_godot;
            }
            
            GodotAppleEvent* apple_event = GodotAppleEvent::get_singleton();
            if (apple_event) {
                apple_event->open_url(url_godot);
            }
        }
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application 
		continueUserActivity:(NSUserActivity *)userActivity 
		restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
		

    NSLog(@"APPLE_EVENT: open web URL:%@", userActivity.webpageURL);
    NSLog(@"DEEPLINK APPLE_EVENT: open web URL:%@", userActivity.webpageURL);
    NSURL* url = userActivity.webpageURL;
    
		
    if (url.absoluteString.length > 3) {
        GodotAppleEvent* apple_event = GodotAppleEvent::get_singleton();
        String godot_url = url.absoluteString.UTF8String;
        GodotAppleEvent::last_event = godot_url;
        if (apple_event) {
            apple_event->open_url(godot_url);
        }
    }
    
    return YES;
}


- (BOOL) application:(UIApplication *)app
             openURL:(NSURL *)url
             options:(NSDictionary<NSString*,id> *)options {
    NSLog(@"APPLE_EVENT 2: open URL:%@", url);
    NSLog(@"DEEPLINK APPLE_EVENT 2: open URL:%@", url);
    
    GodotAppleEvent* apple_event = GodotAppleEvent::get_singleton();
    
    if (url.absoluteString.length > 3) {
        String godot_url = url.absoluteString.UTF8String;
        GodotAppleEvent::last_event = godot_url;
        if (apple_event) {
            apple_event->open_url(godot_url);
        }
    }
    
    return YES;
}

@end
