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
- (void)showPreferences;
- (void)importOPML;
- (void)configureOpenQuickly:(NSObject  * _Nullable)window;
- (void)updateAppearance:(NSObject  * _Nullable)window;
@end

NS_ASSUME_NONNULL_END

#endif
