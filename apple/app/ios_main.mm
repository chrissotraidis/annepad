#include <array>
#include <atomic>
#include <cmath>
#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <unordered_map>
#include <unistd.h>

#include <SDL.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include "rom_setup.h"
#include "touch_tap_latch.h"

int annepad_recomp_main(int argc, char** argv);
extern "C" void annepad_apply_resolution_multiplier(int multiplier);

namespace {

std::atomic<uint16_t> g_touch_buttons{0};
AnnePadTouchTapLatch g_touch_taps;
std::atomic<int32_t> g_touch_x{0};
std::atomic<int32_t> g_touch_y{0};

constexpr uint8_t kTapHoldPolls = 6;
constexpr uint8_t kShoulderTapHoldPolls = 45;

enum class ControlKind { Stick, Button };

struct TouchControl {
    const char* key;
    const char* label;
    ControlKind kind;
    uint16_t mask;
    CGFloat x;
    CGFloat y;
    CGFloat size;
    bool visible;
};

constexpr size_t kControlCount = 15;
constexpr CGFloat kDefaultTouchOpacity = 0.46;
constexpr CGFloat kMinimumTouchOpacity = 0.15;
constexpr CGFloat kMaximumTouchOpacity = 0.85;

std::array<TouchControl, kControlCount> defaultControls() {
    // Adapt HarkinianPad's physically accepted grip-first phone/tablet layouts
    // to AnnePad's direct analog N64 input bridge. The game-specific native HUD
    // artwork and synthetic SDL-key path deliberately remain HarkinianPad-only.
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return {{
            {"stick", "", ControlKind::Stick, 0x0000, 0.164, 0.745, 0.090, true},
            {"d_up", "\u2191", ControlKind::Button, 0x0800, 0.080, 0.550, 0.032, true},
            {"d_down", "\u2193", ControlKind::Button, 0x0400, 0.080, 0.665, 0.032, true},
            {"d_left", "\u2190", ControlKind::Button, 0x0200, 0.040, 0.608, 0.032, true},
            {"d_right", "\u2192", ControlKind::Button, 0x0100, 0.120, 0.608, 0.032, true},
            {"c_up", "\u2191", ControlKind::Button, 0x0008, 0.903, 0.805, 0.033, true},
            {"c_down", "\u2193", ControlKind::Button, 0x0004, 0.902, 0.905, 0.033, true},
            {"c_left", "\u2190", ControlKind::Button, 0x0002, 0.857, 0.854, 0.033, true},
            {"c_right", "\u2192", ControlKind::Button, 0x0001, 0.948, 0.853, 0.033, true},
            {"a", "A", ControlKind::Button, 0x8000, 0.893, 0.693, 0.048, true},
            {"b", "B", ControlKind::Button, 0x4000, 0.826, 0.635, 0.048, true},
            {"z", "Z", ControlKind::Button, 0x2000, 0.890, 0.560, 0.048, true},
            {"l", "L", ControlKind::Button, 0x0020, 0.059, 0.380, 0.041, true},
            {"r", "R", ControlKind::Button, 0x0010, 0.941, 0.380, 0.041, true},
            {"start", "START", ControlKind::Button, 0x1000, 0.865, 0.380, 0.033, true},
        }};
    }
    // The phone radii normalize HarkinianPad's accepted 116-point stick,
    // 52-point face, 44-point D/shoulder, and 40-point C-button targets. The
    // positions reproduce the physically accepted low-grip iPhone layout with
    // exact axes and spacing for each directional and face-button cluster.
    return {{
        {"stick", "", ControlKind::Stick, 0x0000, 0.166, 0.855, 0.148, true},
        {"d_up", "\u2191", ControlKind::Button, 0x0800, 0.126, 0.471, 0.056, true},
        {"d_down", "\u2193", ControlKind::Button, 0x0400, 0.126, 0.645, 0.056, true},
        {"d_left", "\u2190", ControlKind::Button, 0x0200, 0.073, 0.558, 0.056, true},
        {"d_right", "\u2192", ControlKind::Button, 0x0100, 0.179, 0.558, 0.056, true},
        {"c_up", "\u2191", ControlKind::Button, 0x0008, 0.923, 0.476, 0.051, true},
        {"c_down", "\u2193", ControlKind::Button, 0x0004, 0.923, 0.644, 0.051, true},
        {"c_left", "\u2190", ControlKind::Button, 0x0002, 0.875, 0.560, 0.051, true},
        {"c_right", "\u2192", ControlKind::Button, 0x0001, 0.971, 0.560, 0.051, true},
        {"a", "A", ControlKind::Button, 0x8000, 0.923, 0.913, 0.066, true},
        {"b", "B", ControlKind::Button, 0x4000, 0.861, 0.845, 0.066, true},
        {"z", "Z", ControlKind::Button, 0x2000, 0.923, 0.777, 0.066, true},
        {"l", "L", ControlKind::Button, 0x0020, 0.960, 0.345, 0.050, true},
        {"r", "R", ControlKind::Button, 0x0010, 0.960, 0.235, 0.050, true},
        {"start", "START", ControlKind::Button, 0x1000, 0.907, 0.071, 0.050, true},
    }};
}

NSString* layoutDefaultsKey() {
    return UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad
        ? @"annepad.touch.layout.ipad.v4"
        : @"annepad.touch.layout.iphone.v6";
}

NSString* resolutionDefaultsKey() {
    return @"annepad.video.internal-resolution.v1";
}

NSString* touchOpacityDefaultsKey() {
    return @"annepad.touch.opacity.v1";
}

NSString* touchControlsEnabledDefaultsKey() {
    return @"annepad.touch.enabled.v1";
}

CGFloat savedTouchOpacity() {
    NSNumber* saved = [NSUserDefaults.standardUserDefaults
        objectForKey:touchOpacityDefaultsKey()];
    if (![saved isKindOfClass:NSNumber.class]) return kDefaultTouchOpacity;
    return MAX(kMinimumTouchOpacity, MIN(kMaximumTouchOpacity, saved.doubleValue));
}

BOOL savedTouchControlsEnabled() {
    NSNumber* saved = [NSUserDefaults.standardUserDefaults
        objectForKey:touchControlsEnabledDefaultsKey()];
    return ![saved isKindOfClass:NSNumber.class] || saved.boolValue;
}

int savedResolutionMultiplier() {
    NSInteger value = [NSUserDefaults.standardUserDefaults
        integerForKey:resolutionDefaultsKey()];
    return value >= 1 && value <= 4 ? (int)value : 3;
}

} // namespace

@interface AnnePadTouchOverlayView : UIView
- (void)presentResolutionMenu;
@end

@implementation AnnePadTouchOverlayView {
    std::array<TouchControl, kControlCount> _controls;
    std::array<TouchControl, kControlCount> _undoControls;
    std::unordered_map<UITouch*, int> _touchRoles;
    CGPoint _stickOrigin;
    CGPoint _stickKnob;
    BOOL _editing;
    BOOL _hasUndo;
    NSInteger _selected;
    BOOL _touchControlsEnabled;
    CGFloat _globalOpacity;
    CGFloat _undoOpacity;
    UISlider* _opacitySlider;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        self.multipleTouchEnabled = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _controls = defaultControls();
        _selected = 9;
        _touchControlsEnabled = savedTouchControlsEnabled();
        _globalOpacity = savedTouchOpacity();
        [self loadLayout];
        _opacitySlider = [[UISlider alloc] initWithFrame:CGRectZero];
        _opacitySlider.minimumValue = kMinimumTouchOpacity;
        _opacitySlider.maximumValue = kMaximumTouchOpacity;
        _opacitySlider.value = _globalOpacity;
        _opacitySlider.minimumTrackTintColor = UIColor.systemBlueColor;
        _opacitySlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.28];
        _opacitySlider.accessibilityLabel = @"Touch control opacity";
        _opacitySlider.accessibilityValue = [NSString stringWithFormat:@"%.0f percent",
                                             _globalOpacity * 100.0];
        _opacitySlider.hidden = YES;
        [_opacitySlider addTarget:self
                           action:@selector(opacitySliderChanged:)
                 forControlEvents:UIControlEventValueChanged];
        [self addSubview:_opacitySlider];
#if !__has_feature(objc_arc)
        [_opacitySlider release];
#endif
        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(clearInput)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _opacitySlider.frame = [self opacitySliderRect];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (UIEdgeInsets)usableInsets {
    UIEdgeInsets insets = self.safeAreaInsets;
    insets.top += 2.0;
    insets.bottom += 2.0;
    return insets;
}

- (CGRect)usableBounds {
    return UIEdgeInsetsInsetRect(self.bounds, [self usableInsets]);
}

- (CGFloat)baseDimension {
    CGRect usable = [self usableBounds];
    return MIN(usable.size.width, usable.size.height);
}

- (BOOL)isShoulderControl:(const TouchControl&)control {
    return std::strcmp(control.key, "l") == 0 || std::strcmp(control.key, "r") == 0;
}

- (BOOL)isDirectionalControl:(const TouchControl&)control {
    return std::strncmp(control.key, "d_", 2) == 0 ||
           std::strncmp(control.key, "c_", 2) == 0;
}

- (UIColor*)accentColorForControl:(const TouchControl&)control {
    if (std::strcmp(control.key, "a") == 0) {
        return [UIColor colorWithRed:0.10 green:0.34 blue:0.88 alpha:1.0];
    }
    if (std::strcmp(control.key, "b") == 0) {
        return [UIColor colorWithRed:0.05 green:0.58 blue:0.28 alpha:1.0];
    }
    if (std::strncmp(control.key, "c_", 2) == 0) {
        return [UIColor colorWithRed:0.94 green:0.63 blue:0.06 alpha:1.0];
    }
    if (std::strcmp(control.key, "start") == 0) {
        return [UIColor colorWithRed:0.78 green:0.10 blue:0.12 alpha:1.0];
    }
    return nil;
}

- (CGPoint)centerForControl:(const TouchControl&)control {
    CGRect usable = [self usableBounds];
    CGFloat radius = control.size * [self baseDimension];
    CGFloat halfWidth = [self isShoulderControl:control] ? radius * 1.65 : radius;
    CGFloat x = CGRectGetMinX(usable) + control.x * usable.size.width;
    CGFloat y = CGRectGetMinY(usable) + control.y * usable.size.height;
    x = MAX(CGRectGetMinX(usable) + halfWidth, MIN(CGRectGetMaxX(usable) - halfWidth, x));
    y = MAX(CGRectGetMinY(usable) + radius, MIN(CGRectGetMaxY(usable) - radius, y));
    return CGPointMake(x, y);
}

- (CGFloat)radiusForControl:(const TouchControl&)control {
    return control.size * [self baseDimension];
}

- (CGRect)frameForControl:(const TouchControl&)control {
    CGPoint center = [self centerForControl:control];
    CGFloat radius = [self radiusForControl:control];
    CGFloat halfWidth = [self isShoulderControl:control] ? radius * 1.65 : radius;
    return CGRectMake(center.x - halfWidth, center.y - radius,
                      halfWidth * 2.0, radius * 2.0);
}

- (CGFloat)defaultSizeForControl:(const TouchControl&)control {
    std::array<TouchControl, kControlCount> defaults = defaultControls();
    for (const TouchControl& candidate : defaults) {
        if (std::strcmp(candidate.key, control.key) == 0) return candidate.size;
    }
    return control.size;
}

- (void)loadLayout {
    NSDictionary* saved = [NSUserDefaults.standardUserDefaults dictionaryForKey:layoutDefaultsKey()];
    if (![saved isKindOfClass:NSDictionary.class]) return;
    for (TouchControl& control : _controls) {
        NSString* key = [NSString stringWithUTF8String:control.key];
        NSDictionary* value = saved[key];
        if (![value isKindOfClass:NSDictionary.class]) continue;
        control.x = [value[@"x"] doubleValue];
        control.y = [value[@"y"] doubleValue];
        control.size = [value[@"size"] doubleValue];
        control.visible = value[@"visible"] == nil || [value[@"visible"] boolValue];
    }
}

- (void)saveLayout {
    NSMutableDictionary* saved = [NSMutableDictionary dictionaryWithCapacity:kControlCount];
    for (const TouchControl& control : _controls) {
        NSString* key = [NSString stringWithUTF8String:control.key];
        saved[key] = @{
            @"x": @(control.x), @"y": @(control.y),
            @"size": @(control.size), @"visible": @(control.visible),
        };
    }
    [NSUserDefaults.standardUserDefaults setObject:saved forKey:layoutDefaultsKey()];
    [NSUserDefaults.standardUserDefaults setDouble:_globalOpacity
                                             forKey:touchOpacityDefaultsKey()];
    [NSUserDefaults.standardUserDefaults setBool:_touchControlsEnabled
                                           forKey:touchControlsEnabledDefaultsKey()];
}

- (NSArray<NSString*>*)toolbarLabels {
    BOOL hasSelection = _selected >= 0 && _selected < (NSInteger)kControlCount;
    BOOL selectedVisible = hasSelection ? _controls[_selected].visible : YES;
    BOOL selectedHideable = hasSelection && _controls[_selected].kind != ControlKind::Stick;
    return @[@"DONE", _hasUndo ? @"UNDO" : @"RESET", @"\u2212", @"+",
             !selectedHideable ? @"FIXED" : (selectedVisible ? @"HIDE" : @"SHOW")];
}

- (CGRect)utilityButtonRect {
    CGRect usable = [self usableBounds];
    return CGRectMake(CGRectGetMaxX(usable) - 48.0,
                      CGRectGetMinY(usable) + 4.0, 44.0, 44.0);
}

- (CGRect)toolbarRectAtIndex:(NSInteger)index {
    CGRect usable = [self usableBounds];
    CGFloat width = MIN(72.0, usable.size.width / 6.0);
    CGFloat total = width * 5.0;
    return CGRectMake(CGRectGetMidX(usable) - total / 2.0 + width * index,
                      CGRectGetMinY(usable) + 6.0, width, 34.0);
}

- (CGRect)opacityPanelRect {
    CGRect usable = [self usableBounds];
    CGFloat width = MIN(330.0, usable.size.width - 16.0);
    return CGRectMake(CGRectGetMidX(usable) - width / 2.0,
                      CGRectGetMinY(usable) + 44.0, width, 42.0);
}

- (CGRect)opacitySliderRect {
    CGRect panel = [self opacityPanelRect];
    return CGRectMake(CGRectGetMinX(panel) + 82.0, CGRectGetMinY(panel) + 5.0,
                      panel.size.width - 134.0, 32.0);
}

- (void)opacitySliderChanged:(UISlider*)slider {
    _globalOpacity = MAX(kMinimumTouchOpacity,
                         MIN(kMaximumTouchOpacity, (CGFloat)slider.value));
    slider.accessibilityValue = [NSString stringWithFormat:@"%.0f percent",
                                 _globalOpacity * 100.0];
    _hasUndo = NO;
    [self saveLayout];
    [self setNeedsDisplay];
}

- (void)drawLabel:(NSString*)label inRect:(CGRect)rect color:(UIColor*)color size:(CGFloat)size {
    NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    NSDictionary* attributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:size],
        NSForegroundColorAttributeName: color,
        NSParagraphStyleAttributeName: style,
    };
    CGSize textSize = [label sizeWithAttributes:attributes];
    CGRect textRect = CGRectMake(rect.origin.x,
                                 CGRectGetMidY(rect) - textSize.height / 2.0,
                                 rect.size.width, textSize.height);
    [label drawInRect:textRect withAttributes:attributes];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == nullptr) return;
    const uint16_t latchedButtons = g_touch_taps.active();

    for (NSInteger index = 0; index < (NSInteger)kControlCount; ++index) {
        const TouchControl& control = _controls[index];
        if (!_touchControlsEnabled && !_editing) continue;
        if (!control.visible && !_editing) continue;
        CGPoint center = [self centerForControl:control];
        CGFloat radius = [self radiusForControl:control];
        CGRect controlFrame = [self frameForControl:control];
        UIBezierPath* controlPath = [self isShoulderControl:control]
            ? [UIBezierPath bezierPathWithRoundedRect:controlFrame cornerRadius:radius]
            : [UIBezierPath bezierPathWithOvalInRect:controlFrame];
        CGFloat alpha = control.visible ? _globalOpacity : 0.16;
        BOOL latched = (latchedButtons & control.mask) != 0;
        BOOL pressed = latched;
        for (const auto& item : _touchRoles) {
            if (item.second == index) {
                pressed = YES;
                break;
            }
        }
        UIColor* accent = [self accentColorForControl:control];
        UIColor* fill = latched && [self isShoulderControl:control]
            ? [UIColor colorWithRed:0.12 green:0.52 blue:0.92 alpha:0.88]
            : (accent != nil
                ? [accent colorWithAlphaComponent:pressed ? MIN(0.92, alpha + 0.24) : alpha]
                : [UIColor colorWithWhite:pressed ? 0.34 : 0.04
                                     alpha:pressed ? MIN(0.88, alpha + 0.30) : alpha]);
        UIColor* stroke = (index == _selected && _editing)
            ? [UIColor colorWithRed:1.0 green:0.82 blue:0.18 alpha:0.95]
            : [UIColor colorWithWhite:1.0 alpha:MIN(0.88, alpha + 0.28)];
        [fill setFill];
        [controlPath fill];
        [stroke setStroke];
        controlPath.lineWidth = index == _selected && _editing ? 3.0 : 2.0;
        if (!control.visible) CGContextSetLineDash(context, 0, (CGFloat[]){4.0, 3.0}, 2);
        [controlPath stroke];
        CGContextSetLineDash(context, 0, nullptr, 0);

        if (control.kind == ControlKind::Stick) {
            CGPoint knob = pressed ? _stickKnob : center;
            if (CGPointEqualToPoint(knob, CGPointZero)) knob = center;
            CGFloat knobRadius = radius * 0.42;
            UIColor* knobColor = [UIColor colorWithRed:0.30 green:0.59 blue:0.82
                                                  alpha:MIN(0.82, alpha + 0.22)];
            CGContextSetFillColorWithColor(context, knobColor.CGColor);
            CGContextFillEllipseInRect(context,
                CGRectMake(knob.x - knobRadius, knob.y - knobRadius,
                           knobRadius * 2.0, knobRadius * 2.0));
        } else {
            CGFloat labelScale = [self isDirectionalControl:control] ? 0.72 : 0.66;
            if (std::strcmp(control.key, "start") == 0) labelScale = 0.34;
            if ([self isShoulderControl:control]) labelScale = 0.56;
            [self drawLabel:[NSString stringWithUTF8String:control.label] inRect:controlFrame
                      color:[UIColor colorWithWhite:1.0 alpha:0.92]
                       size:MAX(11.0, radius * labelScale)];
        }
    }

    if (_editing) {
        NSArray<NSString*>* labels = [self toolbarLabels];
        CGRect first = [self toolbarRectAtIndex:0];
        CGRect last = [self toolbarRectAtIndex:4];
        CGRect toolbar = CGRectUnion(first, last);
        UIBezierPath* toolbarPath = [UIBezierPath bezierPathWithRoundedRect:toolbar
                                                              cornerRadius:10.0];
        [[UIColor colorWithWhite:0.02 alpha:0.84] setFill];
        [toolbarPath fill];
        [[UIColor colorWithWhite:1.0 alpha:0.28] setStroke];
        toolbarPath.lineWidth = 1.0;
        [toolbarPath stroke];
        for (NSInteger i = 0; i < 5; ++i) {
            CGRect item = [self toolbarRectAtIndex:i];
            if (i > 0) {
                CGFloat x = CGRectGetMinX(item);
                [[UIColor colorWithWhite:1.0 alpha:0.18] setStroke];
                UIBezierPath* divider = [UIBezierPath bezierPath];
                [divider moveToPoint:CGPointMake(x, CGRectGetMinY(item) + 7.0)];
                [divider addLineToPoint:CGPointMake(x, CGRectGetMaxY(item) - 7.0)];
                divider.lineWidth = 1.0;
                [divider stroke];
            }
            [self drawLabel:labels[i] inRect:item color:UIColor.whiteColor size:10.0];
        }
        CGRect opacityPanel = [self opacityPanelRect];
        UIBezierPath* opacityPath = [UIBezierPath bezierPathWithRoundedRect:opacityPanel
                                                               cornerRadius:10.0];
        [[UIColor colorWithWhite:0.02 alpha:0.84] setFill];
        [opacityPath fill];
        [[UIColor colorWithWhite:1.0 alpha:0.28] setStroke];
        opacityPath.lineWidth = 1.0;
        [opacityPath stroke];
        CGRect opacityLabel = CGRectMake(CGRectGetMinX(opacityPanel) + 8.0,
                                         CGRectGetMinY(opacityPanel), 70.0,
                                         opacityPanel.size.height);
        [self drawLabel:@"OPACITY" inRect:opacityLabel color:UIColor.whiteColor size:9.0];
        CGRect percentLabel = CGRectMake(CGRectGetMaxX(opacityPanel) - 48.0,
                                         CGRectGetMinY(opacityPanel), 40.0,
                                         opacityPanel.size.height);
        [self drawLabel:[NSString stringWithFormat:@"%.0f%%", _globalOpacity * 100.0]
                  inRect:percentLabel color:UIColor.whiteColor size:9.0];
    } else {
        CGRect utility = [self utilityButtonRect];
        UIBezierPath* utilityPath = [UIBezierPath bezierPathWithRoundedRect:utility
                                                              cornerRadius:22.0];
        [[UIColor colorWithWhite:0.02 alpha:0.64] setFill];
        [utilityPath fill];
        [[UIColor colorWithWhite:1.0 alpha:0.34] setStroke];
        utilityPath.lineWidth = 1.0;
        [utilityPath stroke];
        [self drawLabel:@"\u2022\u2022\u2022" inRect:utility
                  color:[UIColor colorWithWhite:1 alpha:0.88] size:16.0];
    }
}

- (NSInteger)controlAtPoint:(CGPoint)point includeHidden:(BOOL)includeHidden {
    NSInteger nearest = NSNotFound;
    CGFloat nearestDistance = CGFLOAT_MAX;
    for (NSInteger index = 0; index < (NSInteger)kControlCount; ++index) {
        const TouchControl& control = _controls[index];
        if (!control.visible && !includeHidden) continue;
        CGPoint center = [self centerForControl:control];
        CGFloat distance = hypot(point.x - center.x, point.y - center.y);
        CGFloat radius = [self radiusForControl:control];
        BOOL inside = [self isShoulderControl:control]
            ? CGRectContainsPoint(CGRectInset([self frameForControl:control], -radius * 0.12, -radius * 0.12), point)
            : distance <= radius * 1.12;
        if (inside && distance < nearestDistance) {
            nearest = index;
            nearestDistance = distance;
        }
    }
    return nearest;
}

- (void)presentUtilityMenu {
    [self clearInput];
    UIViewController* presenter = self.window.rootViewController;
    while (presenter.presentedViewController != nil) {
        presenter = presenter.presentedViewController;
    }
    if (presenter == nil) return;

    UIAlertController* menu =
        [UIAlertController alertControllerWithTitle:@"AnnePad"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
    AnnePadTouchOverlayView* overlay = self;
    NSString* touchToggleTitle = _touchControlsEnabled
        ? @"Turn Off Touch Controls"
        : @"Turn On Touch Controls";
    [menu addAction:[UIAlertAction actionWithTitle:touchToggleTitle
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction* action) {
        overlay->_touchControlsEnabled = !overlay->_touchControlsEnabled;
        [overlay clearInput];
        [overlay saveLayout];
        [overlay setNeedsDisplay];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"Manage Game ROM"
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction* action) {
        // Let the action sheet finish dismissing before presenting the ROM
        // manager. UIKit drops a second presentation during the first one's
        // animated teardown.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            annepad_present_rom_manager((__bridge void*)overlay.window.rootViewController);
        });
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"Edit Touch Layout"
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction* action) {
        overlay->_editing = YES;
        overlay->_opacitySlider.hidden = NO;
        overlay->_opacitySlider.value = overlay->_globalOpacity;
        [overlay clearInput];
        [overlay setNeedsDisplay];
    }]];
    NSString* resolutionTitle = [NSString stringWithFormat:@"Internal Resolution: %d\u00d7",
                                 savedResolutionMultiplier()];
    [menu addAction:[UIAlertAction actionWithTitle:resolutionTitle
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction* action) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [overlay presentResolutionMenu];
        });
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    UIPopoverPresentationController* popover = menu.popoverPresentationController;
    if (popover != nil) {
        popover.sourceView = self;
        popover.sourceRect = [self utilityButtonRect];
        popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }
    [presenter presentViewController:menu animated:YES completion:nil];
}

- (void)presentResolutionMenu {
    UIViewController* presenter = self.window.rootViewController;
    while (presenter.presentedViewController != nil) {
        presenter = presenter.presentedViewController;
    }
    if (presenter == nil) return;

    UIAlertController* menu =
        [UIAlertController alertControllerWithTitle:@"Internal Resolution"
                                            message:@"3\u00d7 is the tested default. Higher settings use more GPU and memory."
                                     preferredStyle:UIAlertControllerStyleActionSheet];
    const int current = savedResolutionMultiplier();
    AnnePadTouchOverlayView* overlay = self;
    for (int multiplier = 1; multiplier <= 4; ++multiplier) {
        NSString* label = multiplier == current
            ? [NSString stringWithFormat:@"\u2713  %d\u00d7", multiplier]
            : [NSString stringWithFormat:@"%d\u00d7", multiplier];
        [menu addAction:[UIAlertAction actionWithTitle:label
                                                 style:UIAlertActionStyleDefault
                                               handler:^(__unused UIAlertAction* action) {
            [NSUserDefaults.standardUserDefaults setInteger:multiplier
                                                     forKey:resolutionDefaultsKey()];
            annepad_apply_resolution_multiplier(multiplier);
            [overlay clearInput];
        }]];
    }
    [menu addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    UIPopoverPresentationController* popover = menu.popoverPresentationController;
    if (popover != nil) {
        popover.sourceView = self;
        popover.sourceRect = [self utilityButtonRect];
        popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }
    [presenter presentViewController:menu animated:YES completion:nil];
}

- (BOOL)handleToolbarPoint:(CGPoint)point {
    if (!_editing) {
        if (CGRectContainsPoint([self utilityButtonRect], point)) {
            [self presentUtilityMenu];
            return YES;
        }
        return NO;
    }
    for (NSInteger index = 0; index < 5; ++index) {
        if (!CGRectContainsPoint([self toolbarRectAtIndex:index], point)) continue;
        TouchControl& selected = _controls[MAX(0, _selected)];
        switch (index) {
            case 0:
                _editing = NO;
                _hasUndo = NO;
                _opacitySlider.hidden = YES;
                [self saveLayout];
                break;
            case 1:
                if (_hasUndo) {
                    std::swap(_controls, _undoControls);
                    std::swap(_globalOpacity, _undoOpacity);
                    _opacitySlider.value = _globalOpacity;
                    _hasUndo = NO;
                } else {
                    _undoControls = _controls;
                    _undoOpacity = _globalOpacity;
                    _controls = defaultControls();
                    _globalOpacity = kDefaultTouchOpacity;
                    _opacitySlider.value = _globalOpacity;
                    _hasUndo = YES;
                }
                [self saveLayout];
                break;
            case 2:
            {
                CGFloat baseSize = [self defaultSizeForControl:selected];
                selected.size = MAX(baseSize * 0.70, selected.size - baseSize * 0.10);
                _hasUndo = NO;
                [self saveLayout];
                break;
            }
            case 3:
            {
                CGFloat baseSize = [self defaultSizeForControl:selected];
                selected.size = MIN(baseSize * 1.50, selected.size + baseSize * 0.10);
                _hasUndo = NO;
                [self saveLayout];
                break;
            }
            case 4:
                if (selected.kind != ControlKind::Stick) {
                    selected.visible = !selected.visible;
                }
                _hasUndo = NO;
                [self saveLayout];
                break;
        }
        [self setNeedsDisplay];
        return YES;
    }
    return NO;
}

- (void)moveSelectedToPoint:(CGPoint)point {
    if (_selected == NSNotFound) return;
    CGRect usable = [self usableBounds];
    TouchControl& control = _controls[_selected];
    control.x = MAX(0.0, MIN(1.0, (point.x - CGRectGetMinX(usable)) / usable.size.width));
    control.y = MAX(0.0, MIN(1.0, (point.y - CGRectGetMinY(usable)) / usable.size.height));
    _hasUndo = NO;
    [self setNeedsDisplay];
}

- (void)publishInput {
    uint16_t buttons = 0;
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    for (const auto& item : _touchRoles) {
        UITouch* touch = item.first;
        NSInteger role = item.second;
        if (role < 0 || role >= (NSInteger)kControlCount) continue;
        const TouchControl& control = _controls[role];
        CGPoint point = [touch locationInView:self];
        if (control.kind == ControlKind::Stick) {
            CGFloat radius = [self radiusForControl:control];
            CGFloat dx = point.x - _stickOrigin.x;
            CGFloat dy = point.y - _stickOrigin.y;
            CGFloat length = hypot(dx, dy);
            if (length > radius && length > 0.0) {
                dx *= radius / length;
                dy *= radius / length;
            }
            x = dx / radius;
            y = -dy / radius;
            _stickKnob = CGPointMake(_stickOrigin.x + dx, _stickOrigin.y + dy);
        } else {
            buttons |= control.mask;
        }
    }
    g_touch_buttons.store(buttons, std::memory_order_relaxed);
    g_touch_x.store((int32_t)std::lround(x * 10000.0), std::memory_order_relaxed);
    g_touch_y.store((int32_t)std::lround(y * 10000.0), std::memory_order_relaxed);
    [self setNeedsDisplay];
}

- (void)clearInput {
    _touchRoles.clear();
    _stickOrigin = CGPointZero;
    _stickKnob = CGPointZero;
    g_touch_buttons.store(0, std::memory_order_relaxed);
    g_touch_taps.clearAll();
    g_touch_x.store(0, std::memory_order_relaxed);
    g_touch_y.store(0, std::memory_order_relaxed);
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    for (UITouch* touch in touches) {
        CGPoint point = [touch locationInView:self];
        if ([self handleToolbarPoint:point]) continue;
        if (!_editing && !_touchControlsEnabled) continue;
        NSInteger control = [self controlAtPoint:point includeHidden:_editing];
        if (control == NSNotFound) continue;
        _selected = control;
        _touchRoles[touch] = (int)control;
        if (_editing) {
            [self moveSelectedToPoint:point];
        } else if (_controls[control].kind == ControlKind::Stick) {
            _stickOrigin = point;
            _stickKnob = point;
        } else {
            // Preserve quick taps across several runtime polls. Shoulder taps
            // get a slightly longer grace window so Stadium's R+button party
            // selection chord can also be entered sequentially on a touchscreen.
            const uint16_t mask = _controls[control].mask;
            const uint8_t holdPolls = (mask & 0x0030u) != 0
                ? kShoulderTapHoldPolls : kTapHoldPolls;
            g_touch_taps.extend(mask, holdPolls);
            if ((mask & 0x0030u) != 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC),
                               dispatch_get_main_queue(), ^{ [self setNeedsDisplay]; });
            }
        }
    }
    if (!_editing) [self publishInput];
}

- (void)touchesMoved:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    if (_editing) {
        for (UITouch* touch in touches) {
            auto found = _touchRoles.find(touch);
            if (found != _touchRoles.end()) {
                _selected = found->second;
                [self moveSelectedToPoint:[touch locationInView:self]];
            }
        }
    } else {
        [self publishInput];
    }
}

- (void)finishTouches:(NSSet<UITouch*>*)touches {
    for (UITouch* touch in touches) {
        auto found = _touchRoles.find(touch);
        if (found != _touchRoles.end()) {
            _touchRoles.erase(found);
        }
    }
    if (_editing) {
        [self saveLayout];
    } else {
        [self publishInput];
    }
}

- (void)touchesEnded:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    [self finishTouches:touches];
}

- (void)touchesCancelled:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    [self finishTouches:touches];
}

@end

extern "C" int annepad_resolution_multiplier(void) {
    return savedResolutionMultiplier();
}

extern "C" void annepad_touch_attach(void* window_pointer) {
    if (window_pointer == nullptr) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow* window = (UIWindow*)window_pointer;
        UIView* host = window.rootViewController.view ?: window;
        for (UIView* view in host.subviews) {
            if ([view isKindOfClass:AnnePadTouchOverlayView.class]) return;
        }
        AnnePadTouchOverlayView* overlay =
            [[AnnePadTouchOverlayView alloc] initWithFrame:host.bounds];
        overlay.translatesAutoresizingMaskIntoConstraints = NO;
        [host addSubview:overlay];
        [NSLayoutConstraint activateConstraints:@[
            [overlay.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
            [overlay.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
            [overlay.topAnchor constraintEqualToAnchor:host.topAnchor],
            [overlay.bottomAnchor constraintEqualToAnchor:host.bottomAnchor],
        ]];
    });
}

extern "C" void annepad_touch_snapshot(uint16_t* buttons, float* x, float* y) {
    if (buttons != nullptr) {
        *buttons = g_touch_buttons.load(std::memory_order_relaxed) |
                   g_touch_taps.consume();
    }
    if (x != nullptr) *x = g_touch_x.load(std::memory_order_relaxed) / 10000.0F;
    if (y != nullptr) *y = g_touch_y.load(std::memory_order_relaxed) / 10000.0F;
}

extern "C" int SDL_main(int argc, char** argv) {
    @autoreleasepool {
        SDL_SetHint(SDL_HINT_ORIENTATIONS, "LandscapeLeft LandscapeRight");
        SDL_SetHint(SDL_HINT_ACCELEROMETER_AS_JOYSTICK, "0");
#if !defined(ANNEPAD_RELEASE_BUILD)
        setenv("PSR_AUTOBOOT", "1", 1);
#endif

        NSFileManager* files = [NSFileManager defaultManager];
        NSURL* support = [[files URLsForDirectory:NSApplicationSupportDirectory
                                        inDomains:NSUserDomainMask] firstObject];
        NSURL* root = [support URLByAppendingPathComponent:@"AnnePad" isDirectory:YES];
        NSError* error = nil;
        if (![files createDirectoryAtURL:root
             withIntermediateDirectories:YES
                              attributes:nil
                                   error:&error]) {
            std::fprintf(stderr, "AnnePad could not create Application Support: %s\n",
                         error.localizedDescription.UTF8String);
            return EXIT_FAILURE;
        }
        if (!annepad_prepare_rom_setup()) return EXIT_FAILURE;
        if (chdir(root.fileSystemRepresentation) != 0) {
            std::perror("AnnePad could not enter Application Support");
            return EXIT_FAILURE;
        }

        return annepad_recomp_main(argc, argv);
    }
}
