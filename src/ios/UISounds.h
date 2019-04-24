#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface UISounds : CDVPlugin
{
  NSMutableDictionary *systemSoundIds;
}

- (void)preloadSound:(CDVInvokedUrlCommand *)command;
- (void)playSound:(CDVInvokedUrlCommand *)command;
- (void)unloadSound:(CDVInvokedUrlCommand *)command;

@end