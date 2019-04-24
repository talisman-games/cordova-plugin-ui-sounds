var exec = require('cordova/exec');

function UISoundsPlugin() {
  console.info('UISounds.js: plugin is created');
}

UISoundsPlugin.prototype.preloadSound = function(assetPath) {
  exec(function() {}, function() {}, 'UISounds', 'preloadSound', [assetPath]);
};

UISoundsPlugin.prototype.playSound = function(assetPath, volume) {
  exec(function() {}, function() {}, 'UISounds', 'playSound', [
    assetPath,
    volume
  ]);
};

UISoundsPlugin.prototype.unloadSound = function(assetPath) {
  exec(function() {}, function() {}, 'UISounds', 'unloadSound', [assetPath]);
};

var uiSoundsPlugin = new UISoundsPlugin();
module.exports = uiSoundsPlugin;
