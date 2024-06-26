#ifndef AppKitBridge_Bridge_h
#define AppKitBridge_Bridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AppKitPluginDelegate <NSObject>
- (void)importOPML:(nonnull NSURL *)url;
@end

NS_SWIFT_UI_ACTOR
@protocol AppKitPlugin <NSObject>
- (void)setDelegate:(nullable id<AppKitPluginDelegate>)delegate;
- (void)start;
- (void)importOPML;
- (void)configureOpenQuickly:(NSObject  * _Nullable)window;
- (void)configureAbout:(NSObject  * _Nullable)window;
- (void)configureSettings:(NSObject  * _Nullable)window;
- (void)configureWindowSize:(NSObject  * _Nullable)window x:(double)x y:(double)y width:(double)width height:(double)height;
- (void)configureWindowAspectRatio:(NSObject  * _Nullable)window width:(double)width height:(double)height;
- (void)updateAppearance:(NSObject  * _Nullable)window;
- (void)clearRecentDocuments;
- (void)activateIgnoringOtherApps;
@end

NS_ASSUME_NONNULL_END

#endif
