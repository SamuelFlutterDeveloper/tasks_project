// lib/util/webcam_capture_web.dart
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List?> captureFromWebcam() async {
  html.MediaStream? mediaStream;
  try {
    final videoElement = html.VideoElement();

    // Request camera access
    mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
      'video': {
        'facingMode': 'user', // Use front camera
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    });

    if (mediaStream == null) {
      throw Exception('Could not access webcam');
    }

    videoElement.srcObject = mediaStream;
    
    // Wait for video to load
    await videoElement.play();
    await Future.delayed(const Duration(milliseconds: 500));

    // Create canvas to capture image
    final canvas = html.CanvasElement(
      width: videoElement.videoWidth,
      height: videoElement.videoHeight,
    );
    
    final context = canvas.context2D;
    context.drawImage(videoElement, 0, 0);

    // Convert canvas to blob
    final blob = await canvas.toBlob('image/jpeg', 0.85);
    
    // Convert blob to Uint8List
    final bytes = await _blobToUint8List(blob!);

    // Clean up
    mediaStream.getTracks().forEach((track) => track.stop());

    return bytes;
  } catch (e) {
    // Clean up on error
    mediaStream?.getTracks().forEach((track) => track.stop());
    print('Webcam capture error: $e');
    return null;
  }
}

Future<Uint8List> _blobToUint8List(html.Blob blob) async {
  final completer = Completer<Uint8List>();
  final reader = html.FileReader();

  reader.onLoadEnd.listen((event) {
    completer.complete(reader.result as Uint8List);
  });

  reader.readAsArrayBuffer(blob);
  return await completer.future;
}