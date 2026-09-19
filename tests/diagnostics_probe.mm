// Runs against the real diagnostic implementation in an isolated Simulator.
#include <array>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <unistd.h>
#include "../apple/app/diagnostics_impl.h"

static bool sharePresented = false;
@interface DiagnosticShareProbe : UIViewController
@end
@implementation DiagnosticShareProbe
- (void)presentViewController:(UIViewController*)controller animated:(BOOL)animated completion:(void (^)(void))completion {
    sharePresented = [controller isKindOfClass:UIActivityViewController.class];
    if (completion) completion();
}
@end

int main(int argc, char** argv) {
    @autoreleasepool {
        if (argc != 3) return 64;
        NSURL* root = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]] isDirectory:YES];
        annepad_start_diagnostics(root);
        if (strcmp(argv[2], "clean") == 0) {
            NSString* report = diagnosticReport();
            if ([report containsString:@"guest_failure_address="] || [report containsString:@"fatal_signal="]) return 3;
            puts("PASS: clean later session does not inherit stale crash evidence");
            return 0;
        }
        if (strcmp(argv[2], "crash") == 0) {
            NSString* privateFixture = @"secret-account /Users/private/rom.z64\n  bad function pointer: 0x801E40B8\n raw guest memory 12345678\n";
            [privateFixture writeToURL:[root URLByAppendingPathComponent:@"last_error.log"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            raise(SIGABRT);
            return 99;
        }
        dispatch_sync(diagnosticQueue, ^{
            for (unsigned i = 0; i < 3000; ++i) diagnosticWrite("test_heartbeat");
            NSString* report = diagnosticReport();
            const bool safe = ![report containsString:@"secret-account"] && ![report containsString:@"/Users/"] && ![report containsString:@"raw guest memory"];
            const bool recovered = [report containsString:@"fatal_signal=6"] && [report containsString:@"guest_failure_address=0x801E40B8"];
            struct stat st = {};
            fstat(diagnosticFD, &st);
            if (!safe || !recovered || st.st_size > 66 * 1024) _exit(1);
            [report writeToURL:[root URLByAppendingPathComponent:@"test-report.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            puts("PASS: fatal-signal recovery, previous session, numeric-only export, bounded journal");
        });
        DiagnosticShareProbe* presenter = [[DiagnosticShareProbe alloc] init];
        annepad_share_diagnostics(presenter);
        NSDate* deadline = [NSDate dateWithTimeIntervalSinceNow:10];
        while (!sharePresented && deadline.timeIntervalSinceNow > 0) {
            [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        }
        if (!sharePresented) return 2;
        puts("PASS: share action creates UIActivityViewController and a report file");
    }
    return 0;
}
