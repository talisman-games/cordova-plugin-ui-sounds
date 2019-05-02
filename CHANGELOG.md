# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The format of this file is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.2.1] - 2019-05-02

### Fixed

- Changed internal syntax on promise callbacks to support Android 4.4 system browsers.

## [1.2.0] - 2019-04-30

### Added

- New API function `preloadMultiple` for loading multiple sounds in one shot. A good
  alternative to multiple `preloadSound` calls if you want to load many assets and be
  notified once, when they are all complete. The trade-off is less detailed error-handling.

## [1.1.0] - 2019-04-29

### Added

- API functions now return a `Promise` to allow for app-level error handling.

### Removed

- Removed system log messages and instead pass results back to callers via the API's
  returned `Promise`.

### Fixed

- **iOS**: All actions now execute in a background thread, to prevent blocking the UI
  thread. (They already did so on Android.)
- **iOS**: `playSound` will now call `preloadSound` if invoked with an asset that
  has not yet been loaded.

### Security

- **iOS**: `preloadSound` now only searches the app's `www` folder, to avoid permission
  issues and for consistency with Android.

## [1.0.0] - 2019-04-25

### Added

- First functional release of cordova-plugin-ui-sounds! See the [README](README.md)
  for full details.

[unreleased]: https://github.com/talisman-games/cordova-plugin-ui-sounds/compare/1.2.1...HEAD
[1.2.1]: https://github.com/talisman-games/cordova-plugin-ui-sounds/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/talisman-games/cordova-plugin-ui-sounds/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/talisman-games/cordova-plugin-ui-sounds/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/talisman-games/cordova-plugin-ui-sounds/releases/tag/1.0.0
