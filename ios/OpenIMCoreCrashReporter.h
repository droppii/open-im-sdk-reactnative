#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Receives panic reports from the Go core and forwards them to Bugsnag when the app links it.
@interface OpenIMCoreCrashReporter : NSObject

/// Starts receiving core panic reports and records Go fatal errors under Application Support;
/// a fatal error left by the previous run is reported right away. Safe to call more than once.
+ (void)install;

@end

NS_ASSUME_NONNULL_END
