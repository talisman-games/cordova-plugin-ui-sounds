package games.talisman.cordova.plugin.uisounds;

import android.content.res.AssetFileDescriptor;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.util.Log;
import java.util.HashMap;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;

public class UISounds extends CordovaPlugin {
  private static final String LOGTAG = "UISounds";
  private static HashMap<String, MediaPlayer> loadedAssets;

  @Override
  protected void pluginInitialize() {
    Log.d(LOGTAG, "Native plugin initialized");
    loadedAssets = new HashMap<>();
  }

  @Override
  public boolean execute(
      final String action, final JSONArray params, final CallbackContext callbackContext) {
    try {
      switch (action) {
        case "preloadSound":
          executeAsyncPluginAction(() -> executePreload(params), callbackContext);
          break;
        case "preloadMultiple":
          executeAsyncPluginAction(() -> executePreloadMultiple(params), callbackContext);
          break;
        case "playSound":
          executeAsyncPluginAction(() -> executePlay(params), callbackContext);
          break;
        case "unloadSound":
          executeAsyncPluginAction(() -> executeUnload(params), callbackContext);
          break;
        default:
          return false;
      }
    } catch (Exception ex) {
      callbackContext.sendPluginResult(
          new PluginResult(Status.ERROR, "UISounds: Error - " + ex.toString()));
    }

    return true;
  }

  private interface PluginAction { PluginResult execute(); }

  private void executeAsyncPluginAction(
      PluginAction action, final CallbackContext callbackContext) {
    cordova.getThreadPool().execute(() -> {
      final PluginResult result = action.execute();
      callbackContext.sendPluginResult(result);
    });
  }

  private PluginResult createError(final String errorMsg) {
    return new PluginResult(Status.ERROR, errorMsg);
  }

  private PluginResult executePreload(final JSONArray params) {
    final String assetPath = params.optString(0, null);
    if (assetPath == null) {
      return createError(
          "UISounds: Expected assetPath (string) as first argument to preloadSound()");
    }

    if (loadedAssets.containsKey(assetPath)) {
      return createError("UISounds: '" + assetPath + "' is already loaded");
    }

    final String loadingError = loadAsset(assetPath);
    if (loadingError != null) {
      return createError(
          "UISounds: Error while attempting to load '" + assetPath + "' - " + loadingError);
    }

    return new PluginResult(Status.OK, "UISounds: '" + assetPath + "' loaded");
  }

  private String addAssetPathToFailures(final String assetPath, final String failures) {
    if (failures != null) {
      return failures + ", '" + assetPath + "'";
    }
    return "UISounds: Failed to load assets - '" + assetPath + "'";
  }

  private PluginResult executePreloadMultiple(final JSONArray params) {
    String errorMessage = null;
    for (int i = 0; i < params.length(); i++) {
      final String assetPath = params.optString(i, null);
      if (assetPath == null) {
        errorMessage = addAssetPathToFailures("invalid string", errorMessage);
        continue;
      }

      if (loadedAssets.containsKey(assetPath)) {
        continue; // already loaded
      }

      final String loadingError = loadAsset(assetPath);
      if (loadingError != null) {
        errorMessage = addAssetPathToFailures(assetPath, errorMessage);
      }
    }

    if (errorMessage != null) {
      return new PluginResult(Status.ERROR, errorMessage);
    }
    return new PluginResult(Status.OK, "UISounds: All assets loaded");
  }

  private String loadAsset(final String assetPath) {
    try {
      final String fullPath = "www/".concat(assetPath);
      final AssetFileDescriptor afd =
          cordova.getActivity().getApplicationContext().getResources().getAssets().openFd(fullPath);
      MediaPlayer mediaPlayer = new MediaPlayer();
      mediaPlayer.setAudioStreamType(AudioManager.STREAM_SYSTEM);
      mediaPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
      mediaPlayer.prepare();
      afd.close();
      loadedAssets.put(assetPath, mediaPlayer);
    } catch (Exception e) {
      return e.toString();
    }
    return null;
  }

  private PluginResult executePlay(final JSONArray params) {
    final String assetPath = params.optString(0, null);
    final double volume = params.optDouble(1, 1.0);

    if (assetPath == null) {
      return createError("UISounds: Expected assetPath (String) as first argument to playSound()");
    }

    if (volume < 0.0 || volume > 1.0) {
      return createError("UISounds: Volume must be >= 0.0 and <= 1.0");
    }

    boolean hadToLoadAsset = false;
    if (!loadedAssets.containsKey(assetPath)) {
      hadToLoadAsset = true;
      final PluginResult result = executePreload(params);
      if (result.getStatus() != Status.OK.ordinal()) {
        return result;
      }
    }

    MediaPlayer player = loadedAssets.get(assetPath);
    if (player == null) {
      return createError("UISounds: null MediaPlayer for '" + assetPath + "'!");
    }

    try {
      if (player.isPlaying()) {
        player.pause();
        player.seekTo(0);
      }
      player.setVolume((float) volume, (float) volume);
      player.start();
    } catch (Exception e) {
      return createError("UISounds: Error - " + e.toString());
    }

    final String message = hadToLoadAsset ? "UISounds: '" + assetPath
            + "' loaded and playback started. Call preloadSound() first for lower-latency playback."
                                          : "UISounds: '" + assetPath + "' playback started";
    return new PluginResult(Status.OK, message);
  }

  private PluginResult executeUnload(final JSONArray params) {
    final String assetPath = params.optString(0, null);
    if (assetPath == null) {
      return createError("UISounds: Expected assetPath (String) as first argument to playSound()");
    }

    if (!loadedAssets.containsKey(assetPath)) {
      return createError("UISounds: '" + assetPath + "' is not loaded, cannot be unloaded");
    }

    MediaPlayer player = loadedAssets.get(assetPath);
    if (player != null) {
      try {
        player.stop();
      } catch (IllegalStateException e) {
      }
      player.release();
    }
    loadedAssets.remove(assetPath);

    return new PluginResult(Status.OK, "UISounds: '" + assetPath + "' unloaded");
  }
}
