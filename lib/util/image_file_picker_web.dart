// 🌐 Corrected: webcam_capture_web.dart

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

// Helper function remains the same
Future<Uint8List> _blobToUint8List(html.Blob blob) async {
  final completer = Completer<Uint8List>();
  final reader = html.FileReader();

  reader.onLoadEnd.listen((event) {
    completer.complete(reader.result as Uint8List);
  });

  reader.readAsArrayBuffer(blob);
  return await completer.future;
}

// 🎯 EXPOSED FUNCTION: Renamed from captureFromWebcamWeb() to captureFromWebcam()
Future<Uint8List?> captureFromWebcam() async {
  html.MediaStream? mediaStream;
  try {
    final videoElement = html.VideoElement();

    mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
      'video': true,
    });

    if (mediaStream == null) {
      return null;
    }

    videoElement.srcObject = mediaStream;
    await videoElement.play();

    // Wait for the video feed to initialize
    await videoElement.onLoadedMetadata.first.timeout(
      const Duration(seconds: 5),
    );

    final canvas = html.CanvasElement(
      width: videoElement.videoWidth,
      height: videoElement.videoHeight,
    );
    final context = canvas.context2D;
    context.drawImage(videoElement, 0, 0);

    final blob = await canvas.toBlob('image/jpeg', 0.85);
    final bytes = await _blobToUint8List(blob!);

    mediaStream.getTracks().forEach((track) => track.stop());

    return bytes;
  } catch (e) {
    mediaStream?.getTracks().forEach((track) => track.stop());
    print('Webcam capture failed: $e');
    return null;
  }
}
