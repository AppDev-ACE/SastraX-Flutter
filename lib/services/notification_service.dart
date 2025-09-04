/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  /// Initialize notifications
  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);
  }

  /// Ask for notification permission (Android 13+)
  static Future<void> requestPermissions() async {
    final androidPlugin =
    _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission(); // ✅ this one

    final iosPlugin =
    _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }


  /// Schedule a birthday notification
  static Future<void> scheduleBirthdayCheck(String regNo) async {
    try {
      final res = await http.get(Uri.parse(
          'https://bulletin-screenshot-islamic-lead.trycloudflare.com/dob?regNo=$regNo'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final dob = data['dobData']?[0]?['dob'];

        if (dob != null && dob.isNotEmpty) {
          final parsed = DateFormat('dd-MM-yyyy').parse(dob);
          final today = DateTime.now();

          if (parsed.day == today.day && parsed.month == today.month) {
            // 🎉 Schedule notification immediately if today is birthday
            await _notifications.show(
              1,
              '🎂 Happy Birthday!',
              'Wishing you a wonderful day 🎉',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'birthday_channel',
                  'Birthday Notifications',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              ),
            );
          }
        }
      }
    } catch (_) {
      // ignore errors silently
    }
  }

  /// 🚀 Schedule a test notification at a specific time
  static Future<void> scheduleTestNotificationAt(DateTime time) async {
    await _notifications.zonedSchedule(
      2,
      '⏰ Test Notification',
      'This fired at ${time.hour}:${time.minute}!',
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
 */
