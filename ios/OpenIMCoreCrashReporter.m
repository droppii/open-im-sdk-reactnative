#import "OpenIMCoreCrashReporter.h"

#import <objc/message.h>

@import OpenIMCore;

// Mirrors of the public Bugsnag Cocoa API used below. Bugsnag is looked up at runtime so the SDK
// does not depend on it: apps that do not link Bugsnag only get the report in the log.
@protocol OIMBugsnagStackframe <NSObject>
@property (copy, nullable, nonatomic) NSString *method;
@property (copy, nullable, nonatomic) NSString *file;
@property (copy, nullable, nonatomic) NSNumber *lineNumber;
@end

@protocol OIMBugsnagError <NSObject>
@property (copy, nullable, nonatomic) NSString *errorClass;
@property (copy, nullable, nonatomic) NSString *errorMessage;
@property (copy, nonatomic) NSArray *stacktrace;
@end

@protocol OIMBugsnagEvent <NSObject>
@property (copy, nonatomic) NSArray *errors;
@property (copy, nullable, nonatomic) NSString *context;
@property (copy, nullable, nonatomic) NSString *groupingHash;
@property (nonatomic) NSUInteger severity;
@property (nonatomic) BOOL unhandled;
- (void)addMetadata:(NSDictionary *)metadata toSection:(NSString *)sectionName;
@end

static NSString *const OIMCoreTag = @"[OpenIMCore]";
static const NSUInteger OIMBugsnagSeverityError = 0;

@interface OpenIMCoreCrashReporter () <Open_im_sdk_callbackOnCrashReportListener>
@end

@implementation OpenIMCoreCrashReporter

+ (void)install {
    static dispatch_once_t once;
    static OpenIMCoreCrashReporter *reporter;
    dispatch_once(&once, ^{
        reporter = [OpenIMCoreCrashReporter new];
        Open_im_sdkSetCrashReportListener(reporter);
        NSString *dir = [self crashDirectory];
        if (dir == nil || !Open_im_sdkEnableCrashReport(dir)) {
            NSLog(@"%@ enableCrashReport failed for %@", OIMCoreTag, dir);
        }
    });
}

+ (nullable NSString *)crashDirectory {
    NSURL *support = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    if (support == nil) {
        return nil;
    }
    NSURL *dir = [support URLByAppendingPathComponent:@"openim_crash" isDirectory:YES];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"%@ cannot create %@: %@", OIMCoreTag, dir.path, error);
        return nil;
    }
    [dir setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    return dir.path;
}

// Called on a Go thread: an Objective-C exception escaping here would abort the app.
- (BOOL)onCrashReport:(NSString *)report {
    @try {
        NSData *data = [report dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if (![json isKindOfClass:[NSDictionary class]]) {
            NSLog(@"%@ unreadable crash report: %@", OIMCoreTag, report);
            return NO;
        }
        NSLog(@"%@ core %@ in %@: %@\n%@", OIMCoreTag, json[@"kind"], json[@"where"], json[@"message"], json[@"stack"]);
        if (![self notifyBugsnag:json]) {
            NSLog(@"%@ Bugsnag is not available; the core crash report was only logged", OIMCoreTag);
            return NO;
        }
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"%@ handling a core crash report failed: %@", OIMCoreTag, exception);
        return NO;
    }
}

- (BOOL)notifyBugsnag:(NSDictionary *)report {
    Class bugsnag = NSClassFromString(@"Bugsnag");
    if (bugsnag == nil || ![bugsnag respondsToSelector:@selector(isStarted)] ||
        ![bugsnag respondsToSelector:@selector(notifyError:block:)]) {
        return NO;
    }
    if (!((BOOL (*)(id, SEL))objc_msgSend)(bugsnag, @selector(isStarted))) {
        return NO;
    }

    BOOL fatal = [report[@"kind"] isEqual:@"fatal"];
    NSString *errorClass = fatal ? @"GoFatalError" : @"GoPanic";
    NSString *message = [self stringValue:report[@"message"]];
    NSArray *frames = [report[@"frames"] isKindOfClass:[NSArray class]] ? report[@"frames"] : @[];
    NSDictionary *metadata = [self metadataForReport:report fatal:fatal];
    NSString *groupingHash = [self groupingHashForFrames:frames errorClass:errorClass message:message];
    NSError *error = [NSError errorWithDomain:errorClass code:0 userInfo:@{NSLocalizedDescriptionKey : message}];

    BOOL (^block)(id) = ^BOOL(id rawEvent) {
        id<OIMBugsnagEvent> event = rawEvent;
        // Metadata first: if a later step fails, the event still carries the Go stack and trail.
        // A previous run's fatal error stays handled so the current session is not counted as crashed.
        @try {
            [event addMetadata:metadata toSection:@"openim_core"];
            event.context = [self stringValue:report[@"where"]];
            event.groupingHash = groupingHash;
            event.severity = OIMBugsnagSeverityError;
            id<OIMBugsnagError> bsgError = event.errors.firstObject;
            bsgError.errorClass = errorClass;
            bsgError.errorMessage = message;
        } @catch (NSException *exception) {
            NSLog(@"%@ customizing the Bugsnag event failed: %@", OIMCoreTag, exception);
        }
        @try {
            NSArray *stacktrace = [self bugsnagFramesFromGoFrames:frames];
            id<OIMBugsnagError> bsgError = event.errors.firstObject;
            if (stacktrace.count > 0) {
                bsgError.stacktrace = stacktrace;
            }
        } @catch (NSException *exception) {
            NSLog(@"%@ replacing the Bugsnag stacktrace failed: %@", OIMCoreTag, exception);
        }
        return YES;
    };
    ((void (*)(id, SEL, NSError *, id))objc_msgSend)(bugsnag, @selector(notifyError:block:), error, block);
    return YES;
}

- (NSArray *)bugsnagFramesFromGoFrames:(NSArray *)goFrames {
    Class frameClass = NSClassFromString(@"BugsnagStackframe");
    if (frameClass == nil) {
        return @[];
    }
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:goFrames.count];
    for (NSDictionary *goFrame in goFrames) {
        if (![goFrame isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        id<OIMBugsnagStackframe> frame = [frameClass new];
        frame.method = [self stringValue:goFrame[@"function"]];
        frame.file = [self stringValue:goFrame[@"file"]];
        frame.lineNumber = [goFrame[@"line"] isKindOfClass:[NSNumber class]] ? goFrame[@"line"] : nil;
        [frames addObject:frame];
    }
    return frames;
}

- (NSString *)groupingHashForFrames:(NSArray *)frames errorClass:(NSString *)errorClass message:(NSString *)message {
    for (NSDictionary *frame in frames) {
        if ([frame isKindOfClass:[NSDictionary class]] && [frame[@"inProject"] boolValue]) {
            return [NSString stringWithFormat:@"%@:%@", errorClass, frame[@"function"]];
        }
    }
    NSDictionary *top = frames.firstObject;
    NSString *function = [top isKindOfClass:[NSDictionary class]] ? [self stringValue:top[@"function"]] : @"";
    return [NSString stringWithFormat:@"%@:%@", errorClass, function.length > 0 ? function : message];
}

- (NSDictionary *)metadataForReport:(NSDictionary *)report fatal:(BOOL)fatal {
    NSMutableDictionary *metadata = [@{
        @"kind" : [self stringValue:report[@"kind"]],
        @"where" : [self stringValue:report[@"where"]],
        @"operationID" : [self stringValue:report[@"operationID"]],
        @"coreVersion" : [self stringValue:report[@"coreVersion"]],
        @"goVersion" : [self stringValue:report[@"goVersion"]],
        (fatal ? @"crashedAt" : @"panickedAt") : [self formatMillis:report[@"time"]],
        @"previousRun" : @(fatal),
        @"suppressedRepeats" : [report[@"suppressed"] isKindOfClass:[NSNumber class]] ? report[@"suppressed"] : @0,
    } mutableCopy];
    [self putChunked:[self formatTrail:report[@"trail"]] forKey:@"trail" into:metadata];
    [self putChunked:[self stringValue:report[@"stack"]] forKey:@"goStack" into:metadata];
    return metadata;
}

// Bugsnag cuts metadata strings at 10000 characters; split instead of losing the end.
- (void)putChunked:(NSString *)value forKey:(NSString *)key into:(NSMutableDictionary *)metadata {
    const NSUInteger max = 9000;
    if (value.length <= max) {
        metadata[key] = value;
        return;
    }
    NSUInteger start = 0;
    NSUInteger part = 1;
    while (start < value.length) {
        NSRange range = [value rangeOfComposedCharacterSequencesForRange:NSMakeRange(start, MIN(max, value.length - start))];
        NSString *name = part == 1 ? key : [NSString stringWithFormat:@"%@_%lu", key, (unsigned long)part];
        metadata[name] = [value substringWithRange:range];
        start = NSMaxRange(range);
        part++;
    }
}

- (NSString *)formatTrail:(id)trail {
    if (![trail isKindOfClass:[NSArray class]]) {
        return @"";
    }
    NSMutableString *out = [NSMutableString string];
    for (NSDictionary *entry in trail) {
        if (![entry isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        [out appendFormat:@"%@ %@", [self formatMillis:entry[@"t"]], [self stringValue:entry[@"step"]]];
        NSString *detail = [self stringValue:entry[@"detail"]];
        if (detail.length > 0) {
            [out appendFormat:@" %@", detail];
        }
        NSString *op = [self stringValue:entry[@"op"]];
        if (op.length > 0) {
            [out appendFormat:@" op=%@", op];
        }
        NSInteger repeat = [entry[@"repeat"] integerValue];
        if (repeat > 0) {
            [out appendFormat:@" (repeated %ldx)", (long)repeat];
        }
        [out appendString:@"\n"];
    }
    return out;
}

- (NSString *)formatMillis:(id)millis {
    if (![millis isKindOfClass:[NSNumber class]]) {
        return @"";
    }
    static NSISO8601DateFormatter *formatter;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        formatter = [NSISO8601DateFormatter new];
        formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
    });
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[millis doubleValue] / 1000.0]];
}

- (NSString *)stringValue:(id)value {
    return [value isKindOfClass:[NSString class]] ? value : @"";
}

@end
