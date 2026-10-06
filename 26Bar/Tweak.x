#import <UIKit/UIKit.h>

#define PREF_PATH @"/var/jb/var/mobile/Library/Preferences/com.rikeeyyy.26bar.plist"

static BOOL enableNotchStatusBar = YES;
static BOOL enableTopCCGesture = YES;

static void loadPreferences() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    if (prefs) {
        enableNotchStatusBar = prefs[@"enableNotchStatusBar"] ? [prefs[@"enableNotchStatusBar"] boolValue] : YES;
        enableTopCCGesture = prefs[@"enableTopCCGesture"] ? [prefs[@"enableTopCCGesture"] boolValue] : YES;
    }
}

// -------------------------------------------------------------
// 1. MOBILEGESTALT SUBTYPE HOOK (GesturesXV Engine)
// -------------------------------------------------------------

extern uint32_t MGGetSInt32Answer(CFStringRef key, uint32_t defaultValue);

%hookf(uint32_t, MGGetSInt32Answer, CFStringRef key, uint32_t defaultValue) {
    if (CFEqual(key, CFSTR("artworkDeviceSubType"))) {
        if (enableNotchStatusBar) {
            // 2436 = iPhone X native profile (notched bar + native top-right CC)
            return 2436;
        }
    }
    return %orig;
}

// -------------------------------------------------------------
// 2. STATUS BAR ALIGNMENT (Split54)
// -------------------------------------------------------------

%hook _UIStatusBarVisualProvider_Split54

+ (double)leadingCenteringOffset {
    return enableNotchStatusBar ? -12.0 : %orig;
}

+ (double)trailingCenteringOffset {
    return enableNotchStatusBar ? 12.0 : %orig;
}

+ (double)height {
    return enableNotchStatusBar ? 44.0 : %orig;
}

+ (double)cornerRadius {
    return enableNotchStatusBar ? 0.0 : %orig;
}

%end

// -------------------------------------------------------------
// 3. NATIVE TOP-RIGHT CONTROL CENTER PRESENTATION
// -------------------------------------------------------------

@interface SBControlCenterController : NSObject
+ (id)sharedInstance;
- (BOOL)isVisible;
@end

%hook SBControlCenterController

- (unsigned long long)presentingEdge {
    if (enableTopCCGesture) {
        return 1; // Top edge pull
    }
    return %orig;
}

%end

// -------------------------------------------------------------
// CONSTRUCTOR
// -------------------------------------------------------------

%ctor {
    loadPreferences();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)loadPreferences,
        CFSTR("com.rikeeyyy.26bar/ReloadPrefs"),
        NULL,
        CFNotificationSuspensionBehaviorCoalesce
    );
}
