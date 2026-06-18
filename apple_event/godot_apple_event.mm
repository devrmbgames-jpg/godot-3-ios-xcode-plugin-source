
#include "godot_apple_event.h"


GodotAppleEvent *GodotAppleEvent::instance = NULL;
String GodotAppleEvent::last_event = "";

GodotAppleEvent *GodotAppleEvent::get_singleton() {
	return instance;
}

GodotAppleEvent::GodotAppleEvent() {
	ERR_FAIL_COND(instance != NULL);
	instance = this;
}

GodotAppleEvent::~GodotAppleEvent() {}

void GodotAppleEvent::_bind_methods() {
	ADD_SIGNAL(MethodInfo("event_open_url", PropertyInfo(Variant::STRING, "url")));
    ClassDB::bind_method(D_METHOD("get_last_event_url"),&GodotAppleEvent::get_last_event_url);
}

void GodotAppleEvent::open_url(String url) {
    if (url.length() > 0)
        last_event = url;
	emit_signal("event_open_url", url);
}

String GodotAppleEvent::get_last_event_url() const {
    return last_event;
}
