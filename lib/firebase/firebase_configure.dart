import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:tasks_project/firebase/firebase_options.dart';

class FirebaseConfig {
  static Future<FirebaseApp?> initialize() async {
    try {
      final firebase = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (Firebase.apps.isNotEmpty) {
        log('Firebase Connected');
        log('${Firebase.apps.first.options.iosBundleId}');
      } else {
        log('Firebase Not Connected');
      }
      return firebase;
    } on Exception catch (_) {
      return null;
    }
  }
}
