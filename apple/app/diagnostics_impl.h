// Compiled once by ios_main.mm so diagnostics need no dependency-source edits.
#include "diagnostics.h"
#include <fcntl.h>
#include <signal.h>
#include <sys/stat.h>
#include <sys/ucontext.h>
#include <mach/mach.h>
#include <os/proc.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <uuid/uuid.h>

namespace {
struct AnnePadCrashRecord {
    uint32_t magic;
    int32_t signal;
    int32_t code;
    uint32_t reserved;
    uint64_t pc;
    uint64_t lr;
    uint64_t address;
    uint64_t image;
};
static int diagnosticFD = -1;
static int crashFD = -1;
static uintptr_t diagnosticImage = 0;
static NSURL* diagnosticRoot;
static dispatch_queue_t diagnosticQueue;
static dispatch_source_t diagnosticTimer;
static volatile sig_atomic_t handlingCrash = 0;
static unsigned char diagnosticSignalStack[64 * 1024];

static void diagnosticSignal(int sig, siginfo_t* info, void* context) {
    if (!handlingCrash) {
        handlingCrash = 1;
        AnnePadCrashRecord record = {};
        record.magic = 0x414e4e34;
        record.signal = sig;
        record.code = info ? info->si_code : 0;
        record.address = info ? reinterpret_cast<uintptr_t>(info->si_addr) : 0;
        record.image = diagnosticImage;
#if defined(__arm64__)
        auto* state = static_cast<ucontext_t*>(context);
        if (state && state->uc_mcontext) {
            record.pc = state->uc_mcontext->__ss.__pc;
            record.lr = state->uc_mcontext->__ss.__lr;
        }
#endif
        if (crashFD >= 0) {
            (void)write(crashFD, &record, sizeof(record));
            (void)fsync(crashFD);
        }
    }
    // SA_RESETHAND restores the system disposition. Re-raise rather than
    // swallowing the fault or replacing the system crash report with _exit.
    raise(sig);
}

static void diagnosticWrite(const char* event) {
    if (diagnosticFD < 0) return;
    task_vm_info_data_t memory = {};
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    const bool hasMemory = task_info(mach_task_self(), TASK_VM_INFO,
        reinterpret_cast<task_info_t>(&memory), &count) == KERN_SUCCESS;
    char line[256];
    int n = snprintf(line, sizeof(line), "event=%s uptime=%.0f footprint_mib=%llu available_mib=%llu\n",
        event, NSProcessInfo.processInfo.systemUptime,
        static_cast<unsigned long long>(hasMemory ? memory.phys_footprint / (1024 * 1024) : 0),
        static_cast<unsigned long long>(os_proc_available_memory() / (1024 * 1024)));
    struct stat st = {};
    // Keep the session header and a bounded recent tail. Truncation retains
    // the initial header; the report labels that older heartbeats can expire.
    if (fstat(diagnosticFD, &st) == 0 && st.st_size > 64 * 1024) {
        ftruncate(diagnosticFD, 4096);
        lseek(diagnosticFD, 0, SEEK_END);
    }
    if (n > 0) (void)write(diagnosticFD, line, static_cast<size_t>(n));
}

static NSString* diagnosticText(NSURL* file) {
    NSData* data = [NSData dataWithContentsOfURL:file options:NSDataReadingMappedIfSafe error:nil];
    if (data.length > 70 * 1024) return @"[report exceeded size limit]\n";
    return data ? [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease] ?: @"" : @"";
}

static void appendCrash(NSMutableString* report, NSURL* file) {
    NSData* data = [NSData dataWithContentsOfURL:file];
    if (data.length != sizeof(AnnePadCrashRecord)) return;
    AnnePadCrashRecord record;
    memcpy(&record, data.bytes, sizeof(record));
    if (record.magic != 0x414e4e34) return;
    [report appendFormat:@"fatal_signal=%d code=%d pc_offset=0x%llx lr_offset=0x%llx fault_address=0x%llx\n",
        record.signal, record.code,
        (unsigned long long)(record.pc - record.image),
        (unsigned long long)(record.lr - record.image),
        (unsigned long long)record.address];
}

static void appendGuestFailure(NSMutableString* report, NSURL* file) {
    // Export only known numeric failure fields. Never copy guest memory dumps,
    // arbitrary exception text, paths, settings or the raw runtime log.
    NSFileHandle* handle = [NSFileHandle fileHandleForReadingFromURL:file error:nil];
    if (!handle) return;
    unsigned long long length = [handle seekToEndOfFile];
    [handle seekToFileOffset:length > 32768 ? length - 32768 : 0];
    NSData* data = [handle readDataOfLength:32768];
    [handle closeFile];
    NSString* text = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    if (!text) return;
    NSRegularExpression* fields = [NSRegularExpression regularExpressionWithPattern:
        @"(?:bad function pointer:|PC:|jal target|branch target)\\s*(0x[0-9A-Fa-f]{8})" options:0 error:nil];
    for (NSTextCheckingResult* match in [fields matchesInString:text options:0 range:NSMakeRange(0, text.length)]) {
        [report appendFormat:@"guest_failure_address=%@\n", [text substringWithRange:[match rangeAtIndex:1]]];
    }
}
}

void annepad_diagnostic_event(const char* event) {
    if (!diagnosticQueue) return;
    // Callers pass fixed program-owned literals, never user-supplied text.
    dispatch_async(diagnosticQueue, ^{ diagnosticWrite(event); });
}

void annepad_start_diagnostics(NSURL* root) {
    diagnosticRoot = [[root URLByAppendingPathComponent:@"Diagnostics" isDirectory:YES] retain];
    NSFileManager* files = NSFileManager.defaultManager;
    if (![files createDirectoryAtURL:diagnosticRoot withIntermediateDirectories:YES attributes:nil error:nil]) return;
    [diagnosticRoot setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    [files removeItemAtURL:[diagnosticRoot URLByAppendingPathComponent:@"previous-last_error.log"] error:nil];
    for (NSString* name in @[@"session.txt", @"fatal.bin"]) {
        NSURL* current = [diagnosticRoot URLByAppendingPathComponent:name];
        NSURL* previous = [diagnosticRoot URLByAppendingPathComponent:[@"previous-" stringByAppendingString:name]];
        if ([files fileExistsAtPath:current.path]) {
            [files removeItemAtURL:previous error:nil];
            [files moveItemAtURL:current toURL:previous error:nil];
        }
    }
    // The runtime's own failure log belongs to the session that just ended.
    NSURL* runtimeFailure = [root URLByAppendingPathComponent:@"last_error.log"];
    if ([files fileExistsAtPath:runtimeFailure.path]) {
        NSURL* previous = [diagnosticRoot URLByAppendingPathComponent:@"previous-last_error.log"];
        [files removeItemAtURL:previous error:nil];
        [files moveItemAtURL:runtimeFailure toURL:previous error:nil];
    }
    diagnosticFD = open([diagnosticRoot URLByAppendingPathComponent:@"session.txt"].fileSystemRepresentation,
        O_CREAT | O_TRUNC | O_WRONLY, 0600);
    crashFD = open([diagnosticRoot URLByAppendingPathComponent:@"fatal.bin"].fileSystemRepresentation,
        O_CREAT | O_TRUNC | O_WRONLY, 0600);
    diagnosticImage = reinterpret_cast<uintptr_t>(_dyld_get_image_header(0));
    NSString* imageUUID = @"unavailable";
    const auto* header = reinterpret_cast<const mach_header_64*>(diagnosticImage);
    const auto* command = reinterpret_cast<const load_command*>(header + 1);
    for (uint32_t i = 0; i < header->ncmds; ++i) {
        if (command->cmd == LC_UUID) {
            uuid_string_t uuid;
            uuid_unparse(reinterpret_cast<const uuid_command*>(command)->uuid, uuid);
            imageUUID = [NSString stringWithUTF8String:uuid];
        }
        command = reinterpret_cast<const load_command*>(reinterpret_cast<const char*>(command) + command->cmdsize);
    }
    NSDictionary* info = NSBundle.mainBundle.infoDictionary;
    NSString* headerText = [NSString stringWithFormat:
        @"AnnePad diagnostic report v1\nversion=%@ build=%@ image_uuid=%@\nos=%@ started=%@\nNo ROM, save, guest memory, account or device identifiers are included.\nSessions are bounded; old heartbeat entries may be discarded.\n",
        info[@"CFBundleShortVersionString"], info[@"CFBundleVersion"], imageUUID,
        NSProcessInfo.processInfo.operatingSystemVersionString,
        [NSISO8601DateFormatter stringFromDate:NSDate.date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0] formatOptions:NSISO8601DateFormatWithInternetDateTime]];
    NSData* headerData = [headerText dataUsingEncoding:NSUTF8StringEncoding];
    if (diagnosticFD >= 0) (void)write(diagnosticFD, headerData.bytes, headerData.length);
    stack_t stack = {};
    stack.ss_sp = diagnosticSignalStack;
    stack.ss_size = sizeof(diagnosticSignalStack);
    if (sigaltstack(&stack, nullptr) == 0) {
        struct sigaction action = {};
        action.sa_sigaction = diagnosticSignal;
        sigemptyset(&action.sa_mask);
        action.sa_flags = SA_SIGINFO | SA_RESETHAND | SA_ONSTACK;
        for (int sig : {SIGABRT, SIGBUS, SIGSEGV, SIGILL, SIGFPE}) sigaction(sig, &action, nullptr);
    }
    diagnosticQueue = dispatch_queue_create("com.chrissotraidis.annepad.diagnostics", DISPATCH_QUEUE_SERIAL);
    diagnosticWrite("startup");
    for (NSString* name in @[UIApplicationDidEnterBackgroundNotification, UIApplicationDidBecomeActiveNotification,
                             UIApplicationDidReceiveMemoryWarningNotification, UIApplicationWillTerminateNotification]) {
        [NSNotificationCenter.defaultCenter addObserverForName:name object:nil queue:nil usingBlock:^(NSNotification* note) {
            const char* event = [note.name isEqualToString:UIApplicationDidEnterBackgroundNotification] ? "background" :
                [note.name isEqualToString:UIApplicationDidBecomeActiveNotification] ? "foreground" :
                [note.name isEqualToString:UIApplicationDidReceiveMemoryWarningNotification] ? "memory_warning" : "termination";
            annepad_diagnostic_event(event);
        }];
    }
    diagnosticTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, diagnosticQueue);
    dispatch_source_set_timer(diagnosticTimer, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), 5 * NSEC_PER_SEC, NSEC_PER_SEC);
    dispatch_source_set_event_handler(diagnosticTimer, ^{ diagnosticWrite("heartbeat"); });
    dispatch_resume(diagnosticTimer);
}

static NSString* diagnosticReport() {
        NSMutableString* report = [NSMutableString string];
        for (NSString* prefix in @[@"previous-", @""]) {
            [report appendFormat:@"\n=== %@session ===\n", prefix.length ? @"Previous " : @"Current "];
            [report appendString:diagnosticText([diagnosticRoot URLByAppendingPathComponent:[prefix stringByAppendingString:@"session.txt"]])];
            appendCrash(report, [diagnosticRoot URLByAppendingPathComponent:[prefix stringByAppendingString:@"fatal.bin"]]);
            appendGuestFailure(report, prefix.length
                ? [diagnosticRoot URLByAppendingPathComponent:@"previous-last_error.log"]
                : [[diagnosticRoot URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"last_error.log"]);
        }
        return report;
}

void annepad_share_diagnostics(UIViewController* presenter) {
    if (!diagnosticQueue || !presenter) return;
    dispatch_async(diagnosticQueue, ^{
        diagnosticWrite("export");
        NSString* report = diagnosticReport();
        NSURL* output = [diagnosticRoot URLByAppendingPathComponent:@"AnnePad-Diagnostics.txt"];
        if (![report writeToURL:output atomically:YES encoding:NSUTF8StringEncoding error:nil]) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIActivityViewController* share = [[UIActivityViewController alloc] initWithActivityItems:@[output] applicationActivities:nil];
            share.popoverPresentationController.sourceView = presenter.view;
            share.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(presenter.view.bounds), CGRectGetMidY(presenter.view.bounds), 1, 1);
            [presenter presentViewController:share animated:YES completion:nil];
            [share release];
        });
    });
}
