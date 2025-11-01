import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Intentionally keep a reference to the auth subscription so we can cancel it
  // if needed. Analyzer may warn that it's not read; suppress that warning.
  // ignore: unused_field
  static StreamSubscription<User?>? _authSub;
  static bool _initialized = false;
  static String? _lastSyncedUid;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _authSub = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        final token = await _messaging.getToken();
        if (token != null && _lastSyncedUid != null) {
          await _firestore.collection('users').doc(_lastSyncedUid).set({
                'fcmTokens': FieldValue.arrayRemove([token]),
              },
              SetOptions(merge: true));
        }
        _lastSyncedUid = null;
        return;
      }

      _lastSyncedUid = user.uid;
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token, userId: user.uid);
      }
    });

    _messaging.onTokenRefresh.listen(_saveToken);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleMessage(initialMessage, appLaunched: true);
    }

    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleMessage(message, appLaunched: true),
    );
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
    );
  }

  static Future<void> _saveToken(String token, {String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return;
    _lastSyncedUid = uid;
    await _firestore.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> _handleMessage(RemoteMessage message, {bool appLaunched = false}) async {
    if (!_shouldHandleMessage(message)) return;

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _persistNotification(message, uid);
    }

    final payload = _extractPayload(message.data);
    if (appLaunched) {
      NotificationService.handlePayload(payload);
      return;
    }

    final title = message.notification?.title ?? message.data['title'] ?? 'Homemade Bliss';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    await NotificationService.showAlert(
      title: title,
      body: body,
      payload: payload,
      channelId: message.data['channelId'] ?? 'general_notifications',
      channelName: message.data['channelName'] ?? 'General Notifications',
    );
  }

  static bool _shouldHandleMessage(RemoteMessage message) {
    final targetUid = message.data['targetUid'];
    if (targetUid == null || targetUid.isEmpty) {
      return true;
    }
    final currentUid = _auth.currentUser?.uid;
    return currentUid != null && currentUid == targetUid;
  }

  static Future<void> _persistNotification(RemoteMessage message, String userId) async {
    final collection = _firestore.collection('users').doc(userId).collection('notifications');

    final payload = _extractPayload(message.data);
    final data = <String, dynamic>{
      'title': message.notification?.title ?? message.data['title'] ?? '',
      'body': message.notification?.body ?? message.data['body'] ?? '',
      'orderId': message.data['orderId'],
      'type': message.data['type'] ?? 'general',
      'status': message.data['status'],
      'payload': payload,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    data.removeWhere((key, value) => value == null);

    final notificationId = message.data['notificationId'];
    if (notificationId is String && notificationId.isNotEmpty) {
      await collection.doc(notificationId).set(data, SetOptions(merge: true));
    } else {
      await collection.add(data);
    }
  }

  static String? _extractPayload(Map<String, dynamic> data) {
    final rawPayload = data['payload'];
    if (rawPayload is String && rawPayload.isNotEmpty) {
      return rawPayload;
    }

    final allowedKeys = <String>['route', 'orderId', 'amount', 'status', 'type'];
    final entries = <String, String>{};
    for (final key in allowedKeys) {
      final value = data[key];
      if (value != null && value.toString().isNotEmpty) {
        entries[key] = value.toString();
      }
    }
    if (entries.isEmpty) return null;
    return Uri(queryParameters: entries).query;
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    final firebaseApp = Firebase.app();
    FirebaseFirestore.instanceFor(app: firebaseApp);

    final auth = FirebaseAuth.instanceFor(app: firebaseApp);
    final uid = auth.currentUser?.uid ?? message.data['targetUid'] as String?;
    if (uid == null) return;

    await _persistNotification(message, uid);
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await PushNotificationService.handleBackgroundMessage(message);
}
