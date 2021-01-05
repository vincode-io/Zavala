#ifndef SparkleBridge_Bridge_h
#define SparkleBridge_Bridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SparklePlugin <NSObject>
- (void)start;
- (void)checkForUpdates;
@end

NS_ASSUME_NONNULL_END

#endif
