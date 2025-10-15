import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Global navigatorKey so we can navigate from notification taps
class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handlePayload(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final implementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // Android 13+ requires runtime permission for notifications
      await implementation?.requestNotificationsPermission();
    }

    // If the app was launched by tapping a notification, route accordingly
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handlePayload(launchDetails!.notificationResponse?.payload);
    }

    _initialized = true;
  }

  static Future<void> showPaymentSuccess({required String amount, String? orderId}) async {
    const androidDetails = AndroidNotificationDetails(
      'payments_channel',
      'Payments',
      channelDescription: 'Payment status notifications',
      importance: Importance.high,
      priority: Priority.high,
      // keep notification in tray so user can tap later
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final title = 'ชำระเงินสำเร็จ';
    final body = orderId == null ? 'ยอดชำระ $amount บาท' : 'ออเดอร์ $orderId ชำระเงิน $amount บาทสำเร็จ';
    final payload = orderId == null ? 'route=/order-success' : 'route=/order-success&orderId=$orderId&amount=$amount';
    await _plugin.show(1001, title, body, details, payload: payload);
  }

  static void _handlePayload(String? payload) {
    try {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      // For now we route to order-success directly
      Navigator.of(ctx).pushNamed('/order-success');
    } catch (_) {}
  }
}

// Background tap handler must be a top-level or static function entrypoint
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Nothing heavy here; navigation will be handled when app comes to foreground in init()
}
