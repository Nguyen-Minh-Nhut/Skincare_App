// Keep native TFLite/FFI out of the web dependency graph.
export 'ai_camera_web.dart' if (dart.library.io) 'ai_camera_native.dart';
