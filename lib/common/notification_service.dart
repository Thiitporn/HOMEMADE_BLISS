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
        handlePayload(response.payload);
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
      handlePayload(launchDetails!.notificationResponse?.payload);
    }

    _initialized = true;
  }

  static Future<void> showPaymentSuccess({required String amount, String? orderId}) async {
    final title = 'ชำระเงินสำเร็จ';
    final body = orderId == null ? 'ยอดชำระ $amount บาท' : 'ออเดอร์ $orderId ชำระเงิน $amount บาทสำเร็จ';
    final payload = orderId == null
        ? 'route=/order-success'
        : 'route=/order-success&orderId=$orderId&amount=$amount';

    await showAlert(
      title: title,
      body: body,
      payload: payload,
      channelId: 'payments_channel',
      channelName: 'Payments',
    );
  }

  static Future<void> showAlert({
    required String title,
    required String body,
    String channelId = 'general_notifications',
    String channelName = 'General Notifications',
    String? channelDescription,
    String? payload,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    int? id,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    final notificationId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    await _plugin.show(notificationId, title, body, details, payload: payload);
  }

  static void handlePayload(String? payload) {
    try {
      if (payload == null || payload.isEmpty) return;
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      final query = Uri.splitQueryString(payload);
      final route = query['route'];
      if (route == null || route.isEmpty) return;
      Navigator.of(ctx).pushNamed(route, arguments: query);
    } catch (_) {}
  }
}

// Background tap handler must be a top-level or static function entrypoint
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Nothing heavy here; navigation will be handled when app comes to foreground in init()
}
