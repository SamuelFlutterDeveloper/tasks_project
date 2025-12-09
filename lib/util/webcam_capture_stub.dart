// lib/util/webcam_capture_stub.dart
import 'dart:typed_data';

Future<Uint8List?> captureFromWebcam() async {
  // For mobile platforms (Android/iOS), use image_picker instead
  // Webcam is handled by the camera option in UniversalFilePicker
  return null;
}