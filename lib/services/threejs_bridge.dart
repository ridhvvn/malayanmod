import 'dart:js_interop';

/// Bridge between Dart and the Three.js TMS7 viewer script.
///
/// The JavaScript functions are defined in `web/three/tms7_viewer.js`
/// and registered on `window` as global functions.

@JS('initTms7Scene')
external void _initTms7Scene(JSString containerId);

@JS('updateLiveryTexture')
external void _updateLiveryTexture(JSString dataUrl);

@JS('disposeTms7Scene')
external void _disposeTms7Scene();

/// Dart-friendly wrapper around the Three.js interop functions.
class ThreeJsBridge {
  ThreeJsBridge._();

  /// Initialize the Three.js scene inside the DOM element with [containerId].
  static void initScene(String containerId) {
    _initTms7Scene(containerId.toJS);
  }

  /// Update the model's baked texture with a user-selected image.
  ///
  /// [dataUrl] should be a base64 data URL (e.g. from FileReader.readAsDataURL).
  static void updateLiveryTexture(String dataUrl) {
    _updateLiveryTexture(dataUrl.toJS);
  }

  /// Dispose of the Three.js scene and release resources.
  static void disposeScene() {
    _disposeTms7Scene();
  }
}
