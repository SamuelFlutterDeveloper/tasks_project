// lib/util/webcam_capture_base.dart
import 'dart:typed_data';

Future<Uint8List?> captureFromWebcam() {
  // This will be overridden by platform-specific implementations
  throw UnimplementedError('Webcam capture not available on this platform');
}