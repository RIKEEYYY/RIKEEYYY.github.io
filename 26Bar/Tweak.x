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
// INTERFACE DECLARATIONS
// -------------------------------------------------------------
@interface _UIStatusBar : UIView
+ (Class)visualProviderClassForScreen:(UIScreen *)screen visualProviderInfo:(id)info;
@end

@interface SBControlCenterController : UIViewController
+ (id)sharedInstance;
- (BOOL)isVisible;
- (void)presentAnimated:(BOOL)animated completion:(id)completion;
- (void)dismissAnimated:(BOOL)animated completion:(id)completion;
@end

@interface SpringBoard : UIApplication
@end

// -------------------------------------------------------------
// 1. FORCE MODERN NOTCHED VISUAL PROVIDER (Split 54)
// -------------------------------------------------------------

%hook _UIStatusBar

+ (Class)visualProviderClassForScreen:(UIScreen *)screen visualProviderInfo:(id)info {
    if (enableNotchStatusBar) {
        Class splitClass = NSClassFromString(@"_UIStatusBarVisualProvider_Split54");
        if (splitClass) {
            return splitClass;
        }
    }
    return %orig;
}

+ (double)heightForOrientation:(long long)orientation {
    if (enableNotchStatusBar) {
        return (orientation == 1 || orientation == 2) ? 44.0 : 24.0;
    }
    return %orig;
}

%end

// Expand safe area insets to accommodate the 44pt modern notch layout
%hook UIWindow

- (UIEdgeInsets)safeAreaInsets {
    UIEdgeInsets insets = %orig;
    if (enableNotchStatusBar && insets.top < 44.0) {
        insets.top = 44.0;
    }
    return insets;
}

%end

// -------------------------------------------------------------
// 2. TOP RIGHT CONTROL CENTER PULL-DOWN
// -------------------------------------------------------------

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    if (!enableTopCCGesture) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        if (!keyWindow && [UIApplication sharedApplication].windows.count > 0) {
            keyWindow = [UIApplication sharedApplication].windows[0];
        }

        if (keyWindow) {
            UIScreenEdgePanGestureRecognizer *topRightPan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTopRightCCPan:)];
            topRightPan.edges = UIRectEdgeTop;
            [keyWindow addGestureRecognizer:topRightPan];
        }
    });
}

%new
- (void)_handleTopRightCCPan:(UIScreenEdgePanGestureRecognizer *)recognizer {
    if (!enableTopCCGesture) return;

    UIView *view = recognizer.view;
    CGPoint location = [recognizer locationInView:view];
    CGFloat width = view.bounds.size.width;

    // Trigger only if swipe originated on the top-right side (> 60% width)
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (location.x > (width * 0.60)) {
            SBControlCenterController *cc = [%c(SBControlCenterController) sharedInstance];
            if (![cc isVisible]) {
                [cc presentAnimated:YES completion:nil];
            }
        }
    }
}

%end

// Override presentation edge in SpringBoard's presentation context
%hook SBControlCenterController

- (unsigned long long)presentingEdge {
    if (enableTopCCGesture) {
        return 1; // Top edge pull
    }
    return %orig;
}

%end

// -------------------------------------------------------------
// INITIALIZER
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
