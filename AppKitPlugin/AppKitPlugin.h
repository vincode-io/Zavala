#ifndef AppKitBridge_Bridge_h
#define AppKitBridge_Bridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AppKitPlugin <NSObject>
- (void)start;
- (void)checkForUpdates;
@end

NS_ASSUME_NONNULL_END

#endif
