import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Create notification channel for app limits
    const androidChannel = AndroidNotificationChannel(
      'app_limit_warnings',
      'Peringatan Batas Waktu Aplikasi',
      description:
          'Notifikasi untuk peringatan batas waktu penggunaan aplikasi',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<void> showOneMinuteWarning(String appName) async {
    const androidDetails = AndroidNotificationDetails(
      'app_limit_warnings',
      'Peringatan Batas Waktu Aplikasi',
      channelDescription:
          'Notifikasi untuk peringatan batas waktu penggunaan aplikasi',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      appName.hashCode,
      '⏰ Peringatan Batas Waktu',
      '$appName akan diblokir dalam 1 menit. Segera selesaikan aktivitas Anda.',
      notificationDetails,
    );
  }

  Future<void> showBlockedNotification(String appName) async {
    const androidDetails = AndroidNotificationDetails(
      'app_limit_warnings',
      'Peringatan Batas Waktu Aplikasi',
      channelDescription:
          'Notifikasi untuk peringatan batas waktu penggunaan aplikasi',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      appName.hashCode + 1,
      '🚫 Aplikasi Diblokir',
      '$appName telah mencapai batas waktu penggunaan dan diblokir selama 24 jam.',
      notificationDetails,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
