#import "rom_setup.h"
#import "diagnostics.h"

#import <CommonCrypto/CommonDigest.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#include <cstdio>

namespace {

constexpr NSUInteger kExpectedROMSize = 32u * 1024u * 1024u;
NSString* const kExpectedMD5 = @"ed1378bc12115f71209a77844965ba50";
NSString* const kROMErrorDomain = @"com.chrissotraidis.annepad.rom-import";

enum class ROMError : NSInteger {
    Read = 1,
    Size,
    ByteOrder,
    Revision,
    Write,
};

NSURL* applicationSupportRoot(NSError** error) {
    NSFileManager* files = NSFileManager.defaultManager;
    NSURL* support = [[files URLsForDirectory:NSApplicationSupportDirectory
                                     inDomains:NSUserDomainMask] firstObject];
    NSURL* root = [support URLByAppendingPathComponent:@"AnnePad" isDirectory:YES];
    if (![files createDirectoryAtURL:root
         withIntermediateDirectories:YES
                          attributes:@{NSFileProtectionKey:
                                           NSFileProtectionCompleteUntilFirstUserAuthentication}
                               error:error]) {
        return nil;
    }
    return root;
}

NSError* romError(ROMError code, NSString* description) {
    return [NSError errorWithDomain:kROMErrorDomain
                               code:static_cast<NSInteger>(code)
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

NSString* md5ForData(NSData* data) {
    unsigned char digest[CC_MD5_DIGEST_LENGTH] = {};
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5(data.bytes, static_cast<CC_LONG>(data.length), digest);
#pragma clang diagnostic pop
    NSMutableString* result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (unsigned char byte : digest) [result appendFormat:@"%02x", byte];
    return result;
}

NSData* normalizedROMData(NSData* source, NSError** error) {
    if (source.length != kExpectedROMSize) {
        if (error) {
            *error = romError(ROMError::Size,
                @"This file is not 32 MiB. Choose an unmodified Pokémon Stadium (US) 1.0 ROM.");
        }
        return nil;
    }

    const uint8_t* input = static_cast<const uint8_t*>(source.bytes);
    const uint32_t magic = (static_cast<uint32_t>(input[0]) << 24) |
                           (static_cast<uint32_t>(input[1]) << 16) |
                           (static_cast<uint32_t>(input[2]) << 8) |
                           static_cast<uint32_t>(input[3]);
    NSMutableData* normalized = [NSMutableData dataWithLength:source.length];
    uint8_t* output = static_cast<uint8_t*>(normalized.mutableBytes);

    switch (magic) {
        case 0x80371240u: // big-endian .z64
            memcpy(output, input, source.length);
            break;
        case 0x37804012u: // byte-swapped .v64
            for (NSUInteger index = 0; index < source.length; index += 2) {
                output[index] = input[index + 1];
                output[index + 1] = input[index];
            }
            break;
        case 0x40123780u: // little-endian .n64
            for (NSUInteger index = 0; index < source.length; index += 4) {
                output[index] = input[index + 3];
                output[index + 1] = input[index + 2];
                output[index + 2] = input[index + 1];
                output[index + 3] = input[index];
            }
            break;
        default:
            if (error) {
                *error = romError(ROMError::ByteOrder,
                    @"This is not a recognized .z64, .v64, or .n64 ROM.");
            }
            return nil;
    }

    if (![[md5ForData(normalized) lowercaseString] isEqualToString:kExpectedMD5]) {
        if (error) {
            *error = romError(ROMError::Revision,
                @"This ROM is a different game, region, revision, or has been modified. AnnePad supports Pokémon Stadium (US) 1.0 only.");
        }
        return nil;
    }
    return normalized;
}

BOOL validateInstalledROM(NSURL* root) {
    NSURL* target = [root URLByAppendingPathComponent:@"baserom.z64"];
    NSDictionary* attributes = [NSFileManager.defaultManager
        attributesOfItemAtPath:target.path error:nil];
    if ([attributes[NSFileSize] unsignedIntegerValue] != kExpectedROMSize) return NO;
    NSData* data = [NSData dataWithContentsOfURL:target
                                        options:NSDataReadingMappedIfSafe
                                          error:nil];
    return data != nil && [[md5ForData(data) lowercaseString] isEqualToString:kExpectedMD5];
}

BOOL installROMFromURL(NSURL* sourceURL, NSError** error) {
    BOOL scoped = [sourceURL startAccessingSecurityScopedResource];
    NSData* source = [NSData dataWithContentsOfURL:sourceURL
                                           options:NSDataReadingMappedIfSafe
                                             error:error];
    if (scoped) [sourceURL stopAccessingSecurityScopedResource];
    if (source == nil) {
        if (error && *error == nil) {
            *error = romError(ROMError::Read,
                              @"AnnePad could not read that file. Check Files access and try again.");
        }
        return NO;
    }

    NSData* normalized = normalizedROMData(source, error);
    if (normalized == nil) return NO;

    NSURL* root = applicationSupportRoot(error);
    if (root == nil) return NO;
    NSURL* target = [root URLByAppendingPathComponent:@"baserom.z64"];
    if (![normalized writeToURL:target options:NSDataWritingAtomic error:error]) {
        if (error && *error == nil) {
            *error = romError(ROMError::Write,
                              @"AnnePad could not store the ROM. Check available storage and try again.");
        }
        return NO;
    }

    [NSFileManager.defaultManager setAttributes:@{
        NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication,
    } ofItemAtPath:target.path error:nil];
    [target setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];

    NSURL* config = [root URLByAppendingPathComponent:@"rom.cfg"];
    NSString* configText = [target.path stringByAppendingString:@"\n"];
    if (![configText writeToURL:config
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:error]) {
        return NO;
    }
    std::fprintf(stderr, "[AnnePad] ROM import accepted: Pokemon Stadium US 1.0\n");
    std::fflush(stderr);
    return YES;
}

UIViewController* topViewController(UIViewController* controller) {
    while (controller.presentedViewController != nil) {
        controller = controller.presentedViewController;
    }
    return controller;
}

void styleButton(UIButton* button) {
    button.backgroundColor = [UIColor colorWithRed:0.18 green:0.43 blue:0.94 alpha:1.0];
    button.layer.cornerRadius = 13.0;
    button.contentEdgeInsets = UIEdgeInsetsMake(14.0, 24.0, 14.0, 24.0);
    button.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
}

} // namespace

@interface AnnePadROMSetupController : UIViewController <UIDocumentPickerDelegate>
@property(nonatomic, assign) BOOL imported;
@property(nonatomic, strong) UILabel* statusLabel;
@end

@implementation AnnePadROMSetupController

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.035 green:0.055 blue:0.11 alpha:1.0];

    UILabel* title = [[UILabel alloc] init];
    title.text = @"AnnePad";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:40.0];
    title.textAlignment = NSTextAlignmentCenter;

    UILabel* body = [[UILabel alloc] init];
    body.text = @"Choose your legally obtained Pokémon Stadium (US) 1.0 ROM.\n\nAnnePad accepts .z64, .v64, and .n64 files, verifies the exact supported revision, and keeps the normalized copy private on this device. No ROM is included with the app.";
    body.textColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    body.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightRegular];
    body.textAlignment = NSTextAlignmentCenter;
    body.numberOfLines = 0;

    UIButton* choose = [UIButton buttonWithType:UIButtonTypeSystem];
    [choose setTitle:@"Choose ROM" forState:UIControlStateNormal];
    [choose setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    choose.accessibilityIdentifier = @"annepad.rom.choose";
    styleButton(choose);
    [choose addTarget:self action:@selector(chooseROM) forControlEvents:UIControlEventTouchUpInside];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"Supported revision: US 1.0";
    self.statusLabel.textColor = [UIColor colorWithWhite:0.62 alpha:1.0];
    self.statusLabel.font = [UIFont systemFontOfSize:14.0];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;

    UIButton* diagnostics = [UIButton buttonWithType:UIButtonTypeSystem];
    [diagnostics setTitle:@"Share Diagnostics" forState:UIControlStateNormal];
    [diagnostics addTarget:self action:@selector(shareDiagnostics) forControlEvents:UIControlEventTouchUpInside];
    UIStackView* stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        title, body, choose, diagnostics, self.statusLabel,
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 20.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerYAnchor],
        [stack.widthAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.widthAnchor multiplier:0.78],
        [body.widthAnchor constraintLessThanOrEqualToConstant:650.0],
    ]];
}

- (void)shareDiagnostics {
    annepad_share_diagnostics(self);
}

- (void)chooseROM {
    UIDocumentPickerViewController* picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[UTTypeData] asCopy:YES];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    picker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController*)controller
didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
    NSError* error = nil;
    if (urls.count == 1 && installROMFromURL(urls.firstObject, &error)) {
        self.statusLabel.textColor = [UIColor colorWithRed:0.38 green:0.91 blue:0.57 alpha:1.0];
        self.statusLabel.text = @"Verified. Starting Pokémon Stadium…";
        self.imported = YES;
        return;
    }
    self.statusLabel.textColor = [UIColor colorWithRed:1.0 green:0.48 blue:0.45 alpha:1.0];
    self.statusLabel.text = error.localizedDescription ?: @"AnnePad could not import that file.";
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController*)controller {
    self.statusLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    self.statusLabel.text = @"No ROM selected. Choose your legal copy whenever you're ready.";
}

@end

@interface AnnePadROMManager : NSObject <UIDocumentPickerDelegate>
@property(nonatomic, assign) UIViewController* presenter;
+ (instancetype)shared;
- (void)presentFrom:(UIViewController*)presenter;
@end

@implementation AnnePadROMManager

+ (instancetype)shared {
    static AnnePadROMManager* manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ manager = [[AnnePadROMManager alloc] init]; });
    return manager;
}

- (void)showMessage:(NSString*)title body:(NSString*)body {
    UIViewController* presenter = topViewController(self.presenter);
    if (presenter == nil) return;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:body
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

- (void)presentPicker {
    UIViewController* presenter = topViewController(self.presenter);
    if (presenter == nil) return;
    UIDocumentPickerViewController* picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[UTTypeData] asCopy:YES];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [presenter presentViewController:picker animated:YES completion:nil];
}

- (void)removeROM {
    NSError* error = nil;
    NSURL* root = applicationSupportRoot(&error);
    if (root != nil) {
        NSFileManager* files = NSFileManager.defaultManager;
        NSURL* rom = [root URLByAppendingPathComponent:@"baserom.z64"];
        NSURL* runtimeCopy = [root URLByAppendingPathComponent:@"pokestadium.us.1.0.z64"];
        NSURL* config = [root URLByAppendingPathComponent:@"rom.cfg"];
        if ([files fileExistsAtPath:rom.path] && ![files removeItemAtURL:rom error:&error]) {
            [self showMessage:@"Could Not Remove ROM" body:error.localizedDescription];
            return;
        }
        [files removeItemAtURL:runtimeCopy error:nil];
        [files removeItemAtURL:config error:nil];
    }
    [self showMessage:@"ROM Removed"
                 body:@"The private ROM copy was removed. The current session can finish; AnnePad will ask for a ROM the next time it launches."];
}

- (void)presentFrom:(UIViewController*)presenter {
    self.presenter = topViewController(presenter);
    UIAlertController* menu = [UIAlertController
        alertControllerWithTitle:@"Game ROM"
                         message:@"AnnePad never bundles or downloads game data."
                  preferredStyle:UIAlertControllerStyleActionSheet];
    [menu addAction:[UIAlertAction actionWithTitle:@"Replace ROM"
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction* action) {
        [self presentPicker];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"Remove ROM"
                                             style:UIAlertActionStyleDestructive
                                           handler:^(__unused UIAlertAction* action) {
        [self removeROM];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    UIPopoverPresentationController* popover = menu.popoverPresentationController;
    if (popover != nil) {
        popover.sourceView = self.presenter.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(self.presenter.view.bounds), 32.0, 1.0, 1.0);
    }
    [self.presenter presentViewController:menu animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController*)controller
didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
    NSError* error = nil;
    if (urls.count == 1 && installROMFromURL(urls.firstObject, &error)) {
        [self showMessage:@"ROM Verified"
                     body:@"The private copy was replaced. Relaunch AnnePad when you want the running game to use it."];
        return;
    }
    [self showMessage:@"ROM Not Imported"
                 body:error.localizedDescription ?: @"AnnePad could not import that file."];
}

@end

extern "C" bool annepad_prepare_rom_setup(void) {
    NSError* error = nil;
    NSURL* root = applicationSupportRoot(&error);
    if (root == nil) {
        std::fprintf(stderr, "[AnnePad] setup storage unavailable: %s\n",
                     error.localizedDescription.UTF8String);
        return false;
    }
    if (validateInstalledROM(root)) return true;

    AnnePadROMSetupController* controller = [[AnnePadROMSetupController alloc] init];
    UIWindow* window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    window.windowLevel = UIWindowLevelNormal + 2.0;
    window.rootViewController = controller;
    [window makeKeyAndVisible];

    while (!controller.imported) {
        @autoreleasepool {
            [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode
                                    beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        }
    }
    window.hidden = YES;
    return true;
}

extern "C" void annepad_present_rom_manager(void* presenter_pointer) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController* presenter = (__bridge UIViewController*)presenter_pointer;
        if (presenter != nil) [[AnnePadROMManager shared] presentFrom:presenter];
    });
}
