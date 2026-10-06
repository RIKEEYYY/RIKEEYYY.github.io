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

@interface SBControlCenterController : UIViewController
+ (id)sharedInstance;
- (BOOL)isVisible;
- (void)presentAnimated:(BOOL)animated completion:(id)completion;
@end

// Status Bar Hooks
%hook UIStatusBar_Base

+ (Class)_implementationClass {
    if (enableNotchStatusBar) {
        return %NSClassFromString(@"UIStatusBar_Modern");
    }
    return %orig;
}

+ (void)_setImplementationClass:(Class)arg1 {
    if (enableNotchStatusBar) {
        %orig(%NSClassFromString(@"UIStatusBar_Modern"));
    } else {
        %orig(arg1);
    }
}

%end

%hook UIStatusBarWindow

+ (void)setStatusBar:(Class)arg1 {
    if (enableNotchStatusBar) {
        %orig(%NSClassFromString(@"UIStatusBar_Modern"));
    } else {
        %orig(arg1);
    }
}

%end

%hook _UIStatusBar

+ (double)heightForOrientation:(long long)orientation {
    if (enableNotchStatusBar) {
        return (orientation == 1 || orientation == 2) ? 44.0 : 24.0;
    }
    return %orig;
}

%end

%hook UIWindow

- (UIEdgeInsets)safeAreaInsets {
    UIEdgeInsets insets = %orig;
    if (enableNotchStatusBar && insets.top < 44.0) {
        insets.top = 44.0;
    }
    return insets;
}

%new
- (void)_handleCCSwipeDown:(UIScreenEdgePanGestureRecognizer *)recognizer {
    if (!enableTopCCGesture) return;

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [recognizer locationInView:self];
        CGFloat screenWidth = self.bounds.size.width;

        // Top right 35% of the screen
        if (location.x > (screenWidth * 0.65)) {
            SBControlCenterController *cc = [%c(SBControlCenterController) sharedInstance];
            if (![cc isVisible]) {
                [cc presentAnimated:YES completion:nil];
            }
        }
    }
}

- (void)didMoveToWindow {
    %orig;
    if (!enableTopCCGesture) return;

    if ([self.screen isEqual:[UIScreen mainScreen]]) {
        BOOL hasGesture = NO;
        for (UIGestureRecognizer *g in self.gestureRecognizers) {
            if ([g isKindOfClass:[UIScreenEdgePanGestureRecognizer class]] && 
                ((UIScreenEdgePanGestureRecognizer *)g).edges == UIRectEdgeTop) {
                hasGesture = YES;
                break;
            }
        }

        if (!hasGesture) {
            UIScreenEdgePanGestureRecognizer *topPan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(_handleCCSwipeDown:)];
            topPan.edges = UIRectEdgeTop;
            [self addGestureRecognizer:topPan];
        }
    }
}

%end

%hook _UIStatusBarPillView

- (void)layoutSubviews {
    %orig;
    if (enableNotchStatusBar) {
        self.layer.cornerRadius = self.bounds.size.height / 2.0;
        self.layer.masksToBounds = YES;
    }
}

%end

%hook SBControlCenterController

- (unsigned long long)presentingEdge {
    if (enableTopCCGesture) {
        return 1; // Top edge
    }
    return %orig;
}

%end

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
