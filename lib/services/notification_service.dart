import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ---------------------------------------------------------------------------
  // INITIALIZE
  // ---------------------------------------------------------------------------
  static Future<void> initializeNotification() async {
    // Timezone init
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    // Android init
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await _notifications.initialize(initSettings);

    // Permissions
    await _requestPermission();

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_channel',
      'Daily Notifications',
      description: 'Daily scheduled reminders',
      importance: Importance.max,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print("📢 NotificationService initialized");
  }

  // ---------------------------------------------------------------------------
  // PERMISSION
  // ---------------------------------------------------------------------------
  static Future<void> _requestPermission() async {
    final notif = await Permission.notification.request();
    final alarm = await Permission.scheduleExactAlarm.request();

    print("🔔 NOTIFICATION PERMISSION: $notif");
    print("⏰ ALARM EXACT PERMISSION: $alarm");
  }

  // ---------------------------------------------------------------------------
  // IMMEDIATE NOTIFICATION
  // ---------------------------------------------------------------------------
  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_channel',
      'Daily Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      "Test Bildirimi",
      "Bu bildirim başarıyla çalışıyor!",
      platformDetails,
    );
  }

  // ---------------------------------------------------------------------------
  // SCHEDULE AFTER X SECONDS (TEST)
  // ---------------------------------------------------------------------------
  static Future<void> scheduleInSeconds(int seconds) async {
    final time = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    const android = AndroidNotificationDetails(
      'daily_channel',
      'Daily Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const platform = NotificationDetails(android: android);

    await _notifications.zonedSchedule(
      2,
      "Zamanlanmış Bildirim",
      "$seconds saniye sonra tetiklendi.",
      time,
      platform,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: null,
    );

    print("⏳ $seconds saniye sonrası için bildirim ayarlandı");
  }

  // ---------------------------------------------------------------------------
  // DAILY NOTIFICATION (HER GÜN SABİT SAATTE)
  // ---------------------------------------------------------------------------
  static Future<void> scheduleDaily(int hour, int minute,
    {required String title, required String body, required int id}) async {
  // İstanbul saat dilimi
  final istanbul = tz.getLocation('Europe/Istanbul');

  // Şu anki zaman İstanbul
  final now = tz.TZDateTime.now(istanbul);
  print("🕒 Now (Istanbul): $now");

  // Planlanacak tarih
  tz.TZDateTime scheduleDate =
      tz.TZDateTime(istanbul, now.year, now.month, now.day, hour, minute);
  print("⏰ Initial scheduled date: $scheduleDate");

  // Eğer geçmişteyse bir gün ekle
  if (scheduleDate.isBefore(now)) {
    scheduleDate = scheduleDate.add(const Duration(days: 1));
    print("⏰ Adjusted scheduled date (next day): $scheduleDate");
  }

  const android = AndroidNotificationDetails(
    'daily_channel',
    'Daily Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const platform = NotificationDetails(android: android);

  await _notifications.zonedSchedule(
    id,
    title,
    body,
    scheduleDate,
    platform,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.wallClockTime,
    matchDateTimeComponents: DateTimeComponents.time, // Her gün tekrar
  );

  print("📅 Günlük bildirim ayarlandı → $scheduleDate (hour:$hour, minute:$minute)");
}


  // ---------------------------------------------------------------------------
  // CANCEL ALL
  // ---------------------------------------------------------------------------
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print("🧹 Tüm bildirimler iptal edildi");
  }
}
