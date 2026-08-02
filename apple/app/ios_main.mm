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
    CGFloat opacity;
    bool visible;
};

constexpr size_t kControlCount = 15;

std::array<TouchControl, kControlCount> defaultControls() {
    // Adapt HarkinianPad's physically accepted grip-first phone/tablet layouts
    // to AnnePad's direct analog N64 input bridge. The game-specific native HUD
    // artwork and synthetic SDL-key path deliberately remain HarkinianPad-only.
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return {{
            {"stick", "", ControlKind::Stick, 0x0000, 0.164, 0.745, 0.090, 0.42, true},
            {"d_up", "D\u2191", ControlKind::Button, 0x0800, 0.080, 0.550, 0.032, 0.42, true},
            {"d_down", "D\u2193", ControlKind::Button, 0x0400, 0.080, 0.665, 0.032, 0.42, true},
            {"d_left", "D\u2190", ControlKind::Button, 0x0200, 0.040, 0.608, 0.032, 0.42, true},
            {"d_right", "D\u2192", ControlKind::Button, 0x0100, 0.120, 0.608, 0.032, 0.42, true},
            {"c_up", "C\u2191", ControlKind::Button, 0x0008, 0.903, 0.805, 0.033, 0.42, true},
            {"c_down", "C\u2193", ControlKind::Button, 0x0004, 0.902, 0.905, 0.033, 0.42, true},
            {"c_left", "C\u2190", ControlKind::Button, 0x0002, 0.857, 0.854, 0.033, 0.42, true},
            {"c_right", "C\u2192", ControlKind::Button, 0x0001, 0.948, 0.853, 0.033, 0.42, true},
            {"a", "A", ControlKind::Button, 0x8000, 0.893, 0.693, 0.048, 0.48, true},
            {"b", "B", ControlKind::Button, 0x4000, 0.826, 0.635, 0.048, 0.48, true},
            {"z", "Z", ControlKind::Button, 0x2000, 0.193, 0.613, 0.048, 0.44, true},
            {"l", "L", ControlKind::Button, 0x0020, 0.941, 0.514, 0.041, 0.38, true},
            {"r", "R", ControlKind::Button, 0x0010, 0.941, 0.434, 0.041, 0.38, true},
            {"start", "START", ControlKind::Button, 0x1000, 0.865, 0.434, 0.033, 0.40, true},
        }};
    }
    return {{
        {"stick", "", ControlKind::Stick, 0x0000, 0.214, 0.722, 0.112, 0.42, true},
        {"d_up", "D\u2191", ControlKind::Button, 0x0800, 0.131, 0.365, 0.042, 0.42, true},
        {"d_down", "D\u2193", ControlKind::Button, 0x0400, 0.131, 0.502, 0.042, 0.42, true},
        {"d_left", "D\u2190", ControlKind::Button, 0x0200, 0.080, 0.434, 0.042, 0.42, true},
        {"d_right", "D\u2192", ControlKind::Button, 0x0100, 0.182, 0.434, 0.042, 0.42, true},
        {"c_up", "C\u2191", ControlKind::Button, 0x0008, 0.867, 0.398, 0.039, 0.42, true},
        {"c_down", "C\u2193", ControlKind::Button, 0x0004, 0.867, 0.570, 0.039, 0.42, true},
        {"c_left", "C\u2190", ControlKind::Button, 0x0002, 0.824, 0.485, 0.039, 0.42, true},
        {"c_right", "C\u2192", ControlKind::Button, 0x0001, 0.911, 0.486, 0.039, 0.42, true},
        {"a", "A", ControlKind::Button, 0x8000, 0.876, 0.738, 0.051, 0.48, true},
        {"b", "B", ControlKind::Button, 0x4000, 0.806, 0.665, 0.051, 0.48, true},
        {"z", "Z", ControlKind::Button, 0x2000, 0.242, 0.499, 0.051, 0.44, true},
        {"l", "L", ControlKind::Button, 0x0020, 0.895, 0.270, 0.043, 0.38, true},
        {"r", "R", ControlKind::Button, 0x0010, 0.895, 0.170, 0.043, 0.38, true},
        {"start", "START", ControlKind::Button, 0x1000, 0.810, 0.170, 0.040, 0.40, true},
    }};
}

NSString* layoutDefaultsKey() {
    return UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad
        ? @"annepad.touch.layout.ipad.v2"
        : @"annepad.touch.layout.iphone.v2";
}

} // namespace

@interface AnnePadTouchOverlayView : UIView
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
        [self loadLayout];
        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(clearInput)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
    }
    return self;
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

- (CGPoint)centerForControl:(const TouchControl&)control {
    CGRect usable = [self usableBounds];
    CGFloat radius = control.size * [self baseDimension];
    CGFloat x = CGRectGetMinX(usable) + control.x * usable.size.width;
    CGFloat y = CGRectGetMinY(usable) + control.y * usable.size.height;
    x = MAX(CGRectGetMinX(usable) + radius, MIN(CGRectGetMaxX(usable) - radius, x));
    y = MAX(CGRectGetMinY(usable) + radius, MIN(CGRectGetMaxY(usable) - radius, y));
    return CGPointMake(x, y);
}

- (CGFloat)radiusForControl:(const TouchControl&)control {
    return control.size * [self baseDimension];
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
        control.opacity = [value[@"opacity"] doubleValue];
        control.visible = value[@"visible"] == nil || [value[@"visible"] boolValue];
    }
}

- (void)saveLayout {
    NSMutableDictionary* saved = [NSMutableDictionary dictionaryWithCapacity:kControlCount];
    for (const TouchControl& control : _controls) {
        NSString* key = [NSString stringWithUTF8String:control.key];
        saved[key] = @{
            @"x": @(control.x), @"y": @(control.y),
            @"size": @(control.size), @"opacity": @(control.opacity),
            @"visible": @(control.visible),
        };
    }
    [NSUserDefaults.standardUserDefaults setObject:saved forKey:layoutDefaultsKey()];
}

- (NSArray<NSString*>*)toolbarLabels {
    return @[@"DONE", _hasUndo ? @"UNDO" : @"RESET", @"\u2212", @"+", @"FADE", @"HIDE"];
}

- (CGRect)editButtonRect {
    CGRect usable = [self usableBounds];
    return CGRectMake(CGRectGetMidX(usable) - 34.0, CGRectGetMinY(usable) + 6.0, 68.0, 28.0);
}

- (CGRect)romButtonRect {
    CGRect edit = [self editButtonRect];
    return CGRectOffset(edit, -76.0, 0.0);
}

- (CGRect)toolbarRectAtIndex:(NSInteger)index {
    CGRect usable = [self usableBounds];
    CGFloat width = MIN(58.0, usable.size.width / 7.0);
    CGFloat total = width * 6.0;
    return CGRectMake(CGRectGetMidX(usable) - total / 2.0 + width * index,
                      CGRectGetMinY(usable) + 6.0, width - 3.0, 30.0);
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

    for (NSInteger index = 0; index < (NSInteger)kControlCount; ++index) {
        const TouchControl& control = _controls[index];
        if (!control.visible && !_editing) continue;
        CGPoint center = [self centerForControl:control];
        CGFloat radius = [self radiusForControl:control];
        CGRect circle = CGRectMake(center.x - radius, center.y - radius,
                                   radius * 2.0, radius * 2.0);
        CGFloat alpha = control.visible ? control.opacity : 0.16;
        BOOL pressed = NO;
        for (const auto& item : _touchRoles) {
            if (item.second == index) {
                pressed = YES;
                break;
            }
        }
        UIColor* fill = pressed
            ? [UIColor colorWithWhite:0.32 alpha:MIN(0.90, alpha + 0.30)]
            : [UIColor colorWithWhite:0.05 alpha:alpha];
        UIColor* stroke = (index == _selected && _editing)
            ? [UIColor colorWithRed:1.0 green:0.82 blue:0.18 alpha:0.95]
            : [UIColor colorWithWhite:1.0 alpha:MIN(0.75, alpha + 0.18)];
        CGContextSetFillColorWithColor(context, fill.CGColor);
        CGContextFillEllipseInRect(context, circle);
        CGContextSetStrokeColorWithColor(context, stroke.CGColor);
        CGContextSetLineWidth(context, index == _selected && _editing ? 3.0 : 1.5);
        if (!control.visible) CGContextSetLineDash(context, 0, (CGFloat[]){4.0, 3.0}, 2);
        CGContextStrokeEllipseInRect(context, circle);
        CGContextSetLineDash(context, 0, nullptr, 0);

        if (control.kind == ControlKind::Stick) {
            CGPoint knob = pressed ? _stickKnob : center;
            if (CGPointEqualToPoint(knob, CGPointZero)) knob = center;
            CGFloat knobRadius = radius * 0.42;
            CGContextSetFillColorWithColor(context,
                [UIColor colorWithWhite:1.0 alpha:alpha + 0.15].CGColor);
            CGContextFillEllipseInRect(context,
                CGRectMake(knob.x - knobRadius, knob.y - knobRadius,
                           knobRadius * 2.0, knobRadius * 2.0));
        } else {
            [self drawLabel:[NSString stringWithUTF8String:control.label] inRect:circle
                      color:[UIColor colorWithWhite:1.0 alpha:0.92]
                       size:MAX(10.0, radius * (strlen(control.label) > 2 ? 0.34 : 0.65))];
        }
    }

    if (_editing) {
        NSArray<NSString*>* labels = [self toolbarLabels];
        for (NSInteger i = 0; i < 6; ++i) {
            CGRect item = [self toolbarRectAtIndex:i];
            [[UIColor colorWithWhite:0.02 alpha:0.82] setFill];
            [[UIBezierPath bezierPathWithRoundedRect:item cornerRadius:7.0] fill];
            [self drawLabel:labels[i] inRect:item color:UIColor.whiteColor size:10.0];
        }
    } else {
        CGRect rom = [self romButtonRect];
        [[UIColor colorWithWhite:0.02 alpha:0.42] setFill];
        [[UIBezierPath bezierPathWithRoundedRect:rom cornerRadius:7.0] fill];
        [self drawLabel:@"ROM" inRect:rom color:[UIColor colorWithWhite:1 alpha:0.72] size:10.0];
        CGRect edit = [self editButtonRect];
        [[UIColor colorWithWhite:0.02 alpha:0.42] setFill];
        [[UIBezierPath bezierPathWithRoundedRect:edit cornerRadius:7.0] fill];
        [self drawLabel:@"EDIT" inRect:edit color:[UIColor colorWithWhite:1 alpha:0.72] size:10.0];
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
        if (distance <= radius * 1.12 && distance < nearestDistance) {
            nearest = index;
            nearestDistance = distance;
        }
    }
    return nearest;
}

- (BOOL)handleToolbarPoint:(CGPoint)point {
    if (!_editing) {
        if (CGRectContainsPoint([self romButtonRect], point)) {
            [self clearInput];
            annepad_present_rom_manager((__bridge void*)self.window.rootViewController);
            return YES;
        }
        if (CGRectContainsPoint([self editButtonRect], point)) {
            _editing = YES;
            [self clearInput];
            [self setNeedsDisplay];
            return YES;
        }
        return NO;
    }
    for (NSInteger index = 0; index < 6; ++index) {
        if (!CGRectContainsPoint([self toolbarRectAtIndex:index], point)) continue;
        TouchControl& selected = _controls[MAX(0, _selected)];
        switch (index) {
            case 0:
                _editing = NO;
                _hasUndo = NO;
                [self saveLayout];
                break;
            case 1:
                if (_hasUndo) {
                    std::swap(_controls, _undoControls);
                    _hasUndo = NO;
                } else {
                    _undoControls = _controls;
                    _controls = defaultControls();
                    _hasUndo = YES;
                }
                [self saveLayout];
                break;
            case 2:
                selected.size = MAX(0.026, selected.size - 0.008);
                _hasUndo = NO;
                [self saveLayout];
                break;
            case 3:
                selected.size = MIN(0.20, selected.size + 0.008);
                _hasUndo = NO;
                [self saveLayout];
                break;
            case 4:
                selected.opacity += 0.14;
                if (selected.opacity > 0.78) selected.opacity = 0.24;
                _hasUndo = NO;
                [self saveLayout];
                break;
            case 5:
                selected.visible = !selected.visible;
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
