#import "UISounds.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

static NSString *resultToString(OSStatus result) {
  switch (result) {
    case kAudioServicesNoError: return @"No Error";
    case kAudioServicesUnsupportedPropertyError: return @"Unsupported Property";
    case kAudioServicesBadPropertySizeError: return @"Bad Property Size";
    case kAudioServicesBadSpecifierSizeError: return @"Bad Specifier Size";
    case kAudioServicesSystemSoundUnspecifiedError: return @"System Sound Unspecified";
    case kAudioServicesSystemSoundClientTimedOutError: return @"System Sound Client Timed Out";
    default: return @"Unhandled Error Code";
  }
}

@implementation UISounds

- (void) pluginInitialize{
  NSLog(@"UISounds pluginInitialize");
  systemSoundIds = [NSMutableDictionary dictionary];
}

- (void) preloadSound:(CDVInvokedUrlCommand *)command {
  NSString *assetPath = [command.arguments objectAtIndex:0];
  [self createSystemSoundFor:assetPath];
}

- (void) playSound:(CDVInvokedUrlCommand *)command {
  NSString *assetPath = [command.arguments objectAtIndex:0];
  [self playSystemSoundFor:assetPath];
}

- (void) unloadSound:(CDVInvokedUrlCommand *)command {
  NSString *assetPath = [command.arguments objectAtIndex:0];
  [self disposeSystemSoundFor:assetPath];
}

- (void) addSystemSoundIdFor:(NSString *)assetPath withSoundId:(SystemSoundID)soundId {
  systemSoundIds[assetPath] = [NSNumber numberWithInt:soundId];
}

- (SystemSoundID) getSystemSoundIdFor:(NSString *)assetPath {
    NSNumber *soundId = systemSoundIds[assetPath];
  if (soundId == nil) {
    return 0;
  }
  return [soundId intValue];
}

- (SystemSoundID) createSystemSoundFor:(NSString *)assetPath {
  SystemSoundID soundId = [self getSystemSoundIdFor:assetPath];
  if (soundId != 0) {
    NSLog(@"UISounds - createSystemSoundFor:%@ sound already exists!", assetPath);
  } else {
    NSURL *assetUrl = [self findUrlFor:assetPath];
    if (assetUrl) {
      CFURLRef assetUrlRef = (CFURLRef)CFBridgingRetain(assetUrl);
      OSStatus result = AudioServicesCreateSystemSoundID(assetUrlRef, &soundId);
      if (result == kAudioServicesNoError) {
        [self addSystemSoundIdFor:assetPath withSoundId:soundId];
        NSLog(@"UISounds - createSystemSoundFor:%@ - done", assetPath);
      } else {
        NSLog(@"UISounds - createSystemSoundFor:%@ - Error: %@", assetPath, resultToString(result));
      }
    }
  }
  return soundId;
}

- (void) playSystemSoundFor:(NSString *)assetPath {
  SystemSoundID soundId = [self getSystemSoundIdFor:assetPath];
  if (soundId == 0) {
    NSLog(@"UISounds - playSystemSoundFor:%@ - Sound not found. Be sure to call createSystemSound first!",
      assetPath);
  } else {
    AudioServicesPlaySystemSound(soundId);
    NSLog(@"UISounds - playSystemSoundFor:%@ - done", assetPath);
  }
}

- (void) disposeSystemSoundFor:(NSString *)assetPath {
   SystemSoundID soundId = [self getSystemSoundIdFor:assetPath];
  if (soundId == 0) {
    NSLog(@"UISounds - playSystemSoundFor:%@ - Sound not found. Be sure to call createSystemSound first!",
      assetPath);
  } else {
    OSStatus result = AudioServicesDisposeSystemSoundID(soundId);
    if (result == kAudioServicesNoError) {
      NSLog(@"UISounds - disposeSystemSoundFor:%@ - done", assetPath);
    } else {
      NSLog(@"UISounds - disposeSystemSoundFor:%@ - Error: %@", assetPath, resultToString(result));
    }
  }
}

- (NSURL *) findUrlFor:(NSString *)assetPath {
  NSURL *pathUrl = nil;
  if ([[NSFileManager defaultManager] fileExistsAtPath:assetPath]) {
    pathUrl = [NSURL fileURLWithPath:assetPath];
  } else {
    NSString* wwwPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"];
    NSString* pathFromWWW = [NSString stringWithFormat:@"%@/%@", wwwPath, assetPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathFromWWW]) {
      pathUrl = [NSURL fileURLWithPath:pathFromWWW];
    } else {
      NSLog(@"UISounds - findUrlFor:%@ - unable to find file at specified location or '%@'!",
        assetPath, pathFromWWW);
    }
  }
  return pathUrl;
}

@end
