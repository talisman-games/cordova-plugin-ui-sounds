package games.talisman.cordova.plugin.uisounds;

import java.util.HashMap;

import org.json.JSONArray;
import org.json.JSONException;

import android.content.res.AssetFileDescriptor;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;

public class UISounds extends CordovaPlugin {
  private static final String LOGTAG = "UISounds";
  private static HashMap<String, MediaPlayer> loadedAssets;

  @Override
  protected void pluginInitialize() {
    loadedAssets = new HashMap<>();
  }

  @Override
  public boolean execute(final String action, final JSONArray params, final CallbackContext callbackContext) {
    PluginResult result = null;

    try {
      if (action.equals("preloadSound")) {
        executeAsyncPluginAction(() -> executePreload(params), callbackContext);
      } else if (action.equals("playSound")) {
        executeAsyncPluginAction(() -> executePlay(params), callbackContext);
      } else if (action.equals("unloadSound")) {
        executeAsyncPluginAction(() -> executeUnload(params), callbackContext);
      } else {
        result = new PluginResult(Status.ERROR, "Unsupported plugin action");
      }
    } catch (Exception ex) {
      result = new PluginResult(Status.ERROR, ex.toString());
    }

    if (result != null) {
      callbackContext.sendPluginResult(result);
    }
    return true;
  }

  private interface PluginAction {
    PluginResult execute();
  }

  private void executeAsyncPluginAction(PluginAction action, final CallbackContext callbackContext) {
    cordova.getThreadPool().execute(() -> {
      final PluginResult result = action.execute();
      callbackContext.sendPluginResult(result);
    });
  }

  private PluginResult createError(final String errorMsg) {
    Log.e(LOGTAG, errorMsg);
    return new PluginResult(Status.ERROR, errorMsg);
  }

  private PluginResult executePreload(final JSONArray params) {
    final String assetPath = params.optString(0, null);
    if (assetPath == null) {
      return createError("Invalid Argument: Expected assetPath (String) as first argument.");
    }

    if (loadedAssets.containsKey(assetPath)) {
      return createError("Asset already preloaded: '" + assetPath + "'");
    }

    try {
      final String fullPath = "www/".concat(assetPath);
      final AssetFileDescriptor afd = cordova.getActivity().getApplicationContext().getResources().getAssets()
          .openFd(fullPath);
      MediaPlayer mediaPlayer = new MediaPlayer();
      mediaPlayer.setAudioStreamType(AudioManager.STREAM_SYSTEM);
      mediaPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
      mediaPlayer.prepare();
      afd.close();
      loadedAssets.put(assetPath, mediaPlayer);
      Log.d(LOGTAG, "preloadSound('" + assetPath + "') - done");
    } catch (Exception e) {
      return createError(e.getMessage());
    }

    return new PluginResult(Status.OK);
  }

  private PluginResult executePlay(final JSONArray params) {
    final String assetPath = params.optString(0, null);
    final double volume = params.optDouble(1, 1.0);

    if (assetPath == null) {
      return createError("Invalid Argument: Expected assetPath (String) as first argument.");
    }

    if (volume < 0.0 || volume > 1.0) {
      return createError("Invalid Argument: Volume must be >= 0.0 and <= 1.0");
    }

    if (!loadedAssets.containsKey(assetPath)) {
      Log.w(LOGTAG, "You should call preloadSound() before calling playSound() for reduced latency");
      final PluginResult result = executePreload(params);
      if (result.getStatus() != Status.OK.ordinal()) {
        return result;
      }
    }

    MediaPlayer player = loadedAssets.get(assetPath);
    if (player == null) {
      return createError("null MediaPlayer for '" + assetPath + "'!");
    }

    try {
      if (player.isPlaying()) {
        player.pause();
        player.seekTo(0);
      }
      player.setVolume((float) volume, (float) volume);
      player.start();
    } catch (Exception e) {
      return createError(e.getMessage());
    }

    return new PluginResult(Status.OK);
  }

  private PluginResult executeUnload(final JSONArray params) {
    final String assetPath = params.optString(0, null);
    if (assetPath == null) {
      return createError("Invalid Argument: Expected assetPath (String) as first argument.");
    }

    if (!loadedAssets.containsKey(assetPath)) {
      return createError("Asset not found: '" + assetPath + "' is not currently loaded!");
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

    Log.d(LOGTAG, "unloadSound('" + assetPath + "') - done");
    return new PluginResult(Status.OK);
  }

}
