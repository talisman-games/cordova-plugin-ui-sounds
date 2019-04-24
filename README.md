# cordova-plugin-ui-sounds

This is a Cordova plugin to add simple audio feedback to your mobile applications.

In creating this plugin, we had the following goals:

- Mix with other audio playing on the device without interruption or ducking.
- Low-latency playback with little-to-no impact on the main thread.
- No visible audio playback UI on the device or any paired wearable devices.

## Installation

Use the usual command-line to install this plugin within your Cordova-based project:

```bash
cordova plugin add cordova-plugin-ui-sounds
```

## Usage

```javascript
// During app initialization:
var uiSounds = cordova.require('cordova-plugin-ui-sounds.Plugin');
uiSounds.preloadSound('assets/myTapSound.mp3');

// During button press event:
var myVolume = 1.0;
uiSounds.playSound('assets/myTapSound.mp3', myVolume);

// If you will never use the sound again:
uiSounds.unloadSound('assets/myTapSound.mp3');
```

## API

### `preloadSound(assetPath)`

Loads a sound asset so that it is already in memory when a subsequent `playSound` call is made.

In order to achieve low latency between UI events and audio feedback, it is good practice to call `preloadSound` for each of your app's sound effects during initialization.

- **assetPath** (string) - Tells the operating system where to find the sound file. This must be a path relative to your project's `www` folder. It is case-sensitive.

### `playSound(assetPath, [volume])`

Plays a sound asset on the device's system audio channel.

If the sound has not been loading yet using `preloadSound`, it will be loaded before playing.

- **assetPath** (string) - Tells the operating system where to find the sound file. This must be a path relative to your project's `www` folder. It is case-sensitive.
- **volume** (double, optional) - Indicates the desired playback volume of this sound relative to other system sounds. This parameter is ignored on iOS (see [iOS Limitations](#ios-limitations)). It no value is given, this parameter will default to `1.0`.

### `unloadSound(assetPath)`

Frees the resources associated with the given sound asset.

If you no longer need a sound asset, it is good practice to free the resource using this method.

- **assetPath** (string) - Tells the operating system where to find the sound file. This must be a path relative to your project's `www` folder. It is case-sensitive.

## Limitations

As this plugin is intended to play quick UI feedback sound effects:

- Sounds play immediately
- Looping and stereo positioning are unavailable
- Simultaneous playback is unavailable: You can play only one sound at a time
- The sound is played locally on the device speakers; it does not use audio routing.
- Playback volume is linked to the device's system audio channel, meaning no sounds are played while the device is in silent/vibrate mode.

### iOS Limitations

From the [official Apple documentation](https://developer.apple.com/documentation/audiotoolbox/1405248-audioservicesplaysystemsound?language=objc), sound files that you play using this plugin must be:

- No longer than 30 seconds in duration
- In linear PCM or IMA4 (IMA/ADPCM) format
- Packaged in a .caf, .aif, or .wav file (**note:** .mp3 seems to work just fine as well)

In addition:

- Sounds play at the current system audio volume, with no programmatic volume control available

### Android Limitations

A number of audio file formats are supported (see the [full list](https://developer.android.com/guide/topics/media/media-formats#audio-formats)): .mp3, .mp4, .flac, .wav, .ogg

Unlike iOS, programmatic volume control is available on Android (relative to the system sound channel).

## Alternatives

HTML Audio

cordova-plugin-nativeaudio

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/talisman-games/cordova-plugin-ui-sounds/tags).

## License

[MIT](https://choosealicense.com/licenses/mit/)
