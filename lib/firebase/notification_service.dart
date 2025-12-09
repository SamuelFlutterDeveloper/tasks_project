import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasks_project/util/app_constant.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotification =
      FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationInitialized = false;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _setUpFlutterNotification();

    try {
      final token = await _messaging.getToken();
      log('FCM Token: $token');
      log('FCM Token: $token');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstant.fcmToken, token ?? '');
    } catch (e) {
      log('Error fetching FCM token: $e');
    }

    _setupForegroundAndTapHandlers();

    // ✅ Handle cold start (when app is opened by tapping notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data.toString());
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    log('Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _setUpFlutterNotification() async {
    if (_isFlutterLocalNotificationInitialized) return;

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for important notifications',
      importance: Importance.high,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotification.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    await _localNotification
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    _isFlutterLocalNotificationInitialized = true;
  }

  void _setupForegroundAndTapHandlers() {
    FirebaseMessaging.onMessage.listen(showNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data.toString());
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Used for important notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleNotificationTap(String? payload) {
    log("Notification tapped with payload: $payload");
    // NavigationHandler.handleNotificationTap();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.instance._setUpFlutterNotification();
  await NotificationService.instance.showNotification(message);
}


// import 'dart:developer';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// import 'dart:html' as html;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:tasks_project/util/app_constant.dart';

// class NotificationService {
//   NotificationService._();
//   static final NotificationService instance = NotificationService._();

//   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotification =
//       FlutterLocalNotificationsPlugin();
//   bool _isFlutterLocalNotificationInitialized = false;

//   Future<void> initialize() async {
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//     await _requestPermission();
//     await _setUpFlutterNotification();

//     try {
//       final token = await _messaging.getToken();
//       print('FCM Token: $token');
//       log('FCM Token: $token');
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setString(AppConstant.fcmToken, token ?? '');
//     } catch (e) {
//       log('Error fetching FCM token: $e');
//     }

//     _setupForegroundAndTapHandlers();

//     // ✅ Handle cold start (when app is opened by tapping notification)
//     final initialMessage = await _messaging.getInitialMessage();
//     if (initialMessage != null) {
//       _handleNotificationTap(initialMessage.data.toString());
//     }
//   }

//   Future<void> _requestPermission() async {
//     final settings = await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//     log('Notification permission: ${settings.authorizationStatus}');
//   }

//   Future<void> _setUpFlutterNotification() async {
//     if (_isFlutterLocalNotificationInitialized) return;

//     const androidChannel = AndroidNotificationChannel(
//       'high_importance_channel',
//       'High Importance Notifications',
//       description: 'Used for important notifications',
//       importance: Importance.high,
//       playSound: true,
//       enableLights: true,
//       enableVibration: true,
//     );

//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );
//     const initSettings = InitializationSettings(android: androidSettings);

//     await _localNotification.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         _handleNotificationTap(response.payload);
//       },
//     );

//     await _localNotification
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.createNotificationChannel(androidChannel);

//     _isFlutterLocalNotificationInitialized = true;
//   }

//   void _setupForegroundAndTapHandlers() {
//     FirebaseMessaging.onMessage.listen(showNotification);
//     FirebaseMessaging.onMessageOpenedApp.listen((message) {
//       _handleNotificationTap(message.data.toString());
//     });
//   }

//   void showWebNotification({
//     required String title,
//     required String body,
//     String? url,
//   }) {
//     if (!kIsWeb) return;

//     if (html.Notification.supported) {
//       html.Notification.requestPermission().then((permission) {
//         if (permission == 'granted') {
//           final notification = html.Notification(
//             title,
//             body: body,
//             icon: '/favicon.png',
//           ); // Optional icon

//           notification.onClick.listen((event) {
//             if (url != null) {
//               html.window.open(
//                 url,
//                 '_blank',
//               ); // Navigate to property detail page
//             }
//           });
//         }
//       });
//     } else {
//       log("Web notifications not supported in this browser");
//     }
//   }

//   Future<void> showNotification(RemoteMessage message) async {
//     final notification = message.notification;

//     if (kIsWeb) {
//       showWebNotification(
//         title: notification?.title ?? "New Property",
//         body: notification?.body ?? "",
//         url: "/property/${message.data['id']}", // Property detail URL
//       );
//       return;
//     }

//     final android = message.notification?.android;
//     if (notification != null && android != null) {
//       await _localNotification.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'high_importance_channel',
//             'High Importance Notifications',
//             channelDescription: 'Used for important notifications',
//             importance: Importance.high,
//             priority: Priority.high,
//             playSound: true,
//             enableVibration: true,
//             enableLights: true,
//             icon: '@mipmap/ic_launcher',
//           ),
//         ),
//         payload: message.data.toString(),
//       );
//     }
//   }

//   void _handleNotificationTap(String? payload) {
//     log("Notification tapped with payload: $payload");
//     // NavigationHandler.handleNotificationTap();
//   }
// }

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   await NotificationService.instance._setUpFlutterNotification();
//   await NotificationService.instance.showNotification(message);
// }

