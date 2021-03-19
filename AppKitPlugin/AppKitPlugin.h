#ifndef AppKitBridge_Bridge_h
#define AppKitBridge_Bridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AppKitPluginDelegate <NSObject>
- (void)importOPML:(nonnull NSURL *)url;
@end

@protocol AppKitPlugin <NSObject>
- (void)setDelegate:(nullable id<AppKitPluginDelegate>)delegate;
- (void)start;
- (void)checkForUpdates;
- (void)showPreferences;
- (void)importOPML;
@end

NS_ASSUME_NONNULL_END

#endif
