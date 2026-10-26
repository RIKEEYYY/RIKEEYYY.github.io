#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define PREF_PATH @"/var/jb/var/mobile/Library/Preferences/com.rikeeyyy.26bar.plist"
#define PREFS_RELOAD_NOTIFICATION CFSTR("com.rikeeyyy.26bar/ReloadPrefs")

static BOOL enableNotchStatusBar = YES;
static BOOL enableTopCCGesture = YES;
static BOOL enableTopLeftCCGesture = YES;
static const void *CCPanRecognizerKey = &CCPanRecognizerKey;
static const void *CCPanDelegateKey = &CCPanDelegateKey;

static void loadPreferences(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    enableNotchStatusBar = prefs[@"enableNotchStatusBar"] ? [prefs[@"enableNotchStatusBar"] boolValue] : YES;
    enableTopCCGesture = prefs[@"enableTopCCGesture"] ? [prefs[@"enableTopCCGesture"] boolValue] : YES;
    enableTopLeftCCGesture = prefs[@"enableTopLeftCCGesture"] ? [prefs[@"enableTopLeftCCGesture"] boolValue] : YES;
}

static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    loadPreferences();
}

@interface _UIStatusBar : UIView
+ (Class)visualProviderClassForScreen:(UIScreen *)screen visualProviderInfo:(id)info;
@end

// Select Split54 directly for the status bar. This avoids spoofing the device's
// artwork subtype globally through MobileGestalt.
%hook _UIStatusBar

+ (Class)visualProviderClassForScreen:(UIScreen *)screen visualProviderInfo:(id)info {
    if (enableNotchStatusBar) {
        Class splitClass = NSClassFromString(@"_UIStatusBarVisualProvider_Split54");
        if (splitClass) return splitClass;
    }
    return %orig;
}

%end

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

@interface SBControlCenterController : NSObject
+ (id)sharedInstance;
- (BOOL)isVisible;
- (void)presentAnimated:(BOOL)animated;
@end

@interface _26BarCCGestureDelegate : NSObject <UIGestureRecognizerDelegate>
@property(nonatomic, assign) UIWindow *window;
@end

@implementation _26BarCCGestureDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIWindow *window = self.window;
    if (!window) return NO;

    CGFloat x = [touch locationInView:window].x;
    CGFloat width = CGRectGetWidth(window.bounds);
    if (width <= 0) return NO;

    if (x < width * 0.40) return enableTopLeftCCGesture;
    if (x > width * 0.60) return enableTopCCGesture;
    return NO;
}

@end

@interface SpringBoard : UIApplication
- (void)_26bar_installCCGestureWithAttempts:(NSInteger)attempts;
- (void)_26bar_handleCCPan:(UIScreenEdgePanGestureRecognizer *)pan;
@end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    [self _26bar_installCCGestureWithAttempts:20];
}

%new
- (void)_26bar_installCCGestureWithAttempts:(NSInteger)attempts {
    UIWindow *window = nil;
    for (UIScene *scene in self.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *candidate in ((UIWindowScene *)scene).windows) {
            if (candidate.isKeyWindow) {
                window = candidate;
                break;
            }
        }
        if (window) break;
    }

    // SpringBoard's iOS 15 window lifecycle may not expose a connected scene.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (!window) {
        for (UIWindow *candidate in self.windows) {
            if (candidate.isKeyWindow) {
                window = candidate;
                break;
            }
        }
        if (!window) window = self.keyWindow;
    }
#pragma clang diagnostic pop

    if (window) {
        if (objc_getAssociatedObject(window, CCPanRecognizerKey)) return;

        _26BarCCGestureDelegate *gestureDelegate = [_26BarCCGestureDelegate new];
        gestureDelegate.window = window;

        UIScreenEdgePanGestureRecognizer *pan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(_26bar_handleCCPan:)];
        pan.edges = UIRectEdgeTop;
        pan.delegate = gestureDelegate;
        pan.cancelsTouchesInView = NO;
        pan.delaysTouchesBegan = NO;
        pan.delaysTouchesEnded = NO;

        [window addGestureRecognizer:pan];
        objc_setAssociatedObject(window, CCPanRecognizerKey, pan, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(window, CCPanDelegateKey, gestureDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    if (attempts > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self _26bar_installCCGestureWithAttempts:attempts - 1];
        });
    }
}

%new
- (void)_26bar_handleCCPan:(UIScreenEdgePanGestureRecognizer *)pan {
    if (pan.state != UIGestureRecognizerStateEnded) return;
    if ([pan translationInView:pan.view].y < 24.0) return;

    Class controllerClass = NSClassFromString(@"SBControlCenterController");
    if (!controllerClass || ![controllerClass respondsToSelector:@selector(sharedInstance)]) return;

    SBControlCenterController *controller = [controllerClass sharedInstance];
    if (!controller || ![controller respondsToSelector:@selector(presentAnimated:)]) return;
    if ([controller respondsToSelector:@selector(isVisible)] && [controller isVisible]) return;
    [controller presentAnimated:YES];
}

%end

%hook SBControlCenterController

- (unsigned long long)presentingEdge {
    if (enableTopCCGesture || enableTopLeftCCGesture) return 1;
    return %orig;
}

%end

%ctor {
    loadPreferences();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        preferencesChanged,
        PREFS_RELOAD_NOTIFICATION,
        NULL,
        CFNotificationSuspensionBehaviorCoalesce
    );
}
