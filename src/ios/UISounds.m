#import "UISounds.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

static const SystemSoundID INVALID_SOUND_ID = 0;

static NSString *resultToString(OSStatus result) {
  switch (result) {
    case kAudioServicesNoError:
      return @"No Error";
    case kAudioServicesUnsupportedPropertyError:
      return @"Unsupported Property";
    case kAudioServicesBadPropertySizeError:
      return @"Bad Property Size";
    case kAudioServicesBadSpecifierSizeError:
      return @"Bad Specifier Size";
    case kAudioServicesSystemSoundUnspecifiedError:
      return @"System Sound Unspecified";
    case kAudioServicesSystemSoundClientTimedOutError:
      return @"System Sound Client Timed Out";
    default:
      return @"Unhandled Error Code";
  }
}

@implementation UISounds

- (void)pluginInitialize {
  NSLog(@"UISounds native plugin initialized");
  systemSoundIds = [NSMutableDictionary dictionary];
}

- (void)preloadSound:(CDVInvokedUrlCommand *)command {
  NSString *assetPath = [command.arguments objectAtIndex:0];
  [self.commandDelegate runInBackground:^{
    CDVPluginResult *result = [self createSystemSoundFor:assetPath];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
  }];
}

- (void)preloadMultiple:(CDVInvokedUrlCommand *)command {
  [self.commandDelegate runInBackground:^{
    CDVPluginResult *result = [self createMultipleSystemSounds:command.arguments];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
  }];
}

- (void)playSound:(CDVInvokedUrlCommand *)command {
  NSString *assetPath = [command.arguments objectAtIndex:0];
  [self.commandDelegate runInBackground:^{
    CDVPluginResult *result = [self playSystemSoundFor:assetPath];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
  }];
}

- (void)unloadSound:(CDVInvokedUrlCommand *)command {
  NSString *assetPath = [command.arguments objectAtIndex:0];
  [self.commandDelegate runInBackground:^{
    CDVPluginResult *result = [self disposeSystemSoundFor:assetPath];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
  }];
}

- (void)addSystemSoundIdFor:(NSString *)assetPath withSoundId:(SystemSoundID)soundId {
  systemSoundIds[assetPath] = [NSNumber numberWithInt:soundId];
}

- (SystemSoundID)getSystemSoundIdFor:(NSString *)assetPath {
  NSNumber *soundId = systemSoundIds[assetPath];
  return soundId == nil ? INVALID_SOUND_ID : [soundId intValue];
}

- (void)removeSystemSoundIdFor:(NSString *)assetPath {
  [systemSoundIds removeObjectForKey:assetPath];
}

- (CDVPluginResult *)createSystemSoundFor:(NSString *)assetPath {
  SystemSoundID soundId = [self getSystemSoundIdFor:assetPath];
  if (soundId != INVALID_SOUND_ID) {
    NSString *message = [NSString stringWithFormat:@"UISounds: '%@' is already loaded", assetPath];
    return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
  }

  NSURL *assetUrl = [self findUrlFor:assetPath];
  if (assetUrl == nil) {
    NSString *message = [NSString
        stringWithFormat:@"UISounds: File '%@' not found in the app's www folder!", assetPath];
    return [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
  }

  CFURLRef assetUrlRef = (CFURLRef)CFBridgingRetain(assetUrl);
  OSStatus result = AudioServicesCreateSystemSoundID(assetUrlRef, &soundId);
  if (result != kAudioServicesNoError) {
    NSString *message =
        [NSString stringWithFormat:@"UISounds: AudioServices error when loading '%@': %@",
                                   assetPath, resultToString(result)];
    return [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
  }

  [self addSystemSoundIdFor:assetPath withSoundId:soundId];
  NSString *message = [NSString stringWithFormat:@"UISounds: '%@' loaded", assetPath];
  return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
}

- (NSString *)addAssetPath:(NSString *)assetPath toFailures:(NSString *)failures {
  if (failures != nil) {
    return [failures stringByAppendingFormat:@", '%@'", assetPath];
  }
  return [NSString stringWithFormat:@"UISounds: Failed to load assets - '%@'", assetPath];
}

- (CDVPluginResult *)createMultipleSystemSounds:(NSArray *)arrayOfAssetPaths {
  NSEnumerator *enumerator = [arrayOfAssetPaths objectEnumerator];
  NSString *assetPath = nil;
  NSString *errorMessage = nil;
  while (assetPath = [enumerator nextObject]) {
    SystemSoundID soundId = [self getSystemSoundIdFor:assetPath];
    if (soundId != INVALID_SOUND_ID) {
      continue;  // already loaded
    }

    NSURL *assetUrl = [self findUrlFor:assetPath];
    if (assetUrl == nil) {
      errorMessage = [self addAssetPath:assetPath toFailures:errorMessage];
      continue;
    }

    CFURLRef assetUrlRef = (CFURLRef)CFBridgingRetain(assetUrl);
    OSStatus result = AudioServicesCreateSystemSoundID(assetUrlRef, &soundId);
    if (result != kAudioServicesNoError) {
      errorMessage = [self addAssetPath:assetPath toFailures:errorMessage];
      continue;
    }

    [self addSystemSoundIdFor:assetPath withSoundId:soundId];
  }

  if (errorMessage != nil) {
    return [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
  }
  NSString *message = @"UISounds: All assets loaded";
  return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
}

- (CDVPluginResult *)playSystemSoundFor:(NSString *)assetPath {
  SystemSoundID soundId = [self getSystemSoundIdFor:assetPath];
  if (soundId == INVALID_SOUND_ID) {
    CDVPluginResult *result = [self createSystemSoundFor:assetPath];
    if ([result.status intValue] != CDVCommandStatus_OK) {
      return result;  // could not load that asset
    }

    soundId = [self getSystemSoundIdFor:assetPath];
    AudioServicesPlaySystemSound(soundId);
    NSString *message =
        [NSString stringWithFormat:@"UISounds: '%@' loaded and playback started. Call "
                                   @"preloadSound() first for lower-latency playback.",
                                   assetPath];
    return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
  }

  AudioServicesPlaySystemSound(soundId);
  NSString *message = [NSString stringWithFormat:@"UISounds: '%@' playback started", assetPath];
  return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
}

- (CDVPluginResult *)disposeSystemSoundFor:(NSString *)assetPath {
  SystemSoundID soundId = [self getSystemSoundIdFor:assetPath];
  if (soundId == INVALID_SOUND_ID) {
    NSString *message =
        [NSString stringWithFormat:@"UISounds: '%@' is not loaded, cannot be unloaded", assetPath];
    return [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
  }

  OSStatus result = AudioServicesDisposeSystemSoundID(soundId);
  if (result != kAudioServicesNoError) {
    NSString *message =
        [NSString stringWithFormat:@"UISounds: AudioServices error while unloading '%@': %@",
                                   assetPath, resultToString(result)];
    return [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
  }

  [self removeSystemSoundIdFor:assetPath];

  NSString *message = [NSString stringWithFormat:@"UISounds: '%@' unloaded", assetPath];
  return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
}

- (NSURL *)findUrlFor:(NSString *)assetPath {
  NSString *wwwPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"];
  NSString *pathFromWWW = [NSString stringWithFormat:@"%@/%@", wwwPath, assetPath];
  if ([[NSFileManager defaultManager] fileExistsAtPath:pathFromWWW]) {
    return [NSURL fileURLWithPath:pathFromWWW];
  }
  return nil;
}

@end
