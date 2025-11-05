// lib/services/notification_service.dart
// (FINAL) – Release modunda başlatma ve izin sorunları için düzeltildi

import 'dart:math';
import 'package:flutter/foundation.dart'; // print için eklendi (debug)
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'preference_service.dart'; // getEnabledCustomReminders için

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Aynı saat diliminde farklı cümleler için ufak bir rastgelelik
  final Random _rng = Random();


  // --- DEĞİŞİKLİK BURADA ---
  Future<void> init() async {
    // Android ayarı (Aynı)
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    // Not: Durum çubuğu ikonu için bir önceki adımlarda
    // '@drawable/ic_notification' kullanmıştık. Lütfen buranın
    // Android'de doğru çalıştığından emin olun.
    // Eğer durum çubuğu ikonu hâlâ beyaz kare ise, burayı:
    // const AndroidInitializationSettings initializationSettingsAndroid =
    //     AndroidInitializationSettings('@drawable/ic_notification');
    // olarak değiştirin.

    // --- iOS BAŞLATMA AYARI (GÜNCELLENDİ) ---
    // Release modundaki sorunları çözmek için izinleri 'init' sırasında istiyoruz.
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,  // <-- Bildirim izni iste
      requestBadgePermission: true,  // <-- Rozet izni iste
      requestSoundPermission: true,  // <-- Ses izni iste
      onDidReceiveLocalNotification: onDidReceiveLocalNotification, // iOS < 10 için
    );
    // --- BİTİŞ: DEĞİŞİKLİK ---

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }
  // --- BİTİŞ: DEĞİŞİKLİK ---


  // Bildirime tıklandığında ne olacağı
  void onDidReceiveNotificationResponse(NotificationResponse response) async {
    if (response.payload != null) {
      debugPrint('notification payload: ${response.payload}');
    }
  }

  // iOS < 10 için (Uygulama ön plandayken bildirim gelirse)
  static void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // Bu fonksiyonun burada olması GEREKİR, içi boş olsa bile.
    debugPrint('iOS < 10 local notification received: $id');
  }


  // Bu fonksiyon artık 'main.dart'ta çağrılsa da,
  // 'init' içinde zaten izinleri istedik. Bu, bir "yedek" kontrol olacak.
  Future<bool?> requestPermissions() async {
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      return await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    // ... (Android kısmı aynı) ...
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      return await androidImplementation.requestNotificationsPermission();
    }
    return false;
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    if (kDebugMode) {
      print('[NotificationService] Tüm bildirimler iptal edildi.');
    }
  }

  // ... (_titleBodyForHour fonksiyonu aynı, değişiklik yok) ...
  ({String title, String body}) _titleBodyForHour(int hour) {
    String pick(List<String> list) => list[_rng.nextInt(list.length)];
    String bodySuffix = '';

    if (hour >= 5 && hour <= 10) {
      final titles = ['Gün Başlıyor! ☀️', 'Sabah Enerjisi 💧', 'Yeni Güne Merhaba!'];
      final bodies = [
        'Güne zinde başla! İlk bardağını içmeyi unutma ☀️',
        'Hafif bir bardak su, odak ve enerji için harika bir başlangıç.',
        'Bugün harika geçsin! Bir bardak suyla başla.',
      ];
      return (title: pick(titles), body: pick(bodies) + bodySuffix);
    } else if (hour >= 11 && hour <= 13) {
      final titles = ['Öğle Molası ⏱️', 'Öğle Hidrasyonu', 'Mini Mola Zamanı'];
      final bodies = [
        'Su içmek odaklanmayı artırır 💪',
        'Kısa bir su molası ver ve enerjini tazele.',
        'Öğle temposunda bir bardak su iyi gider!',
      ];
      return (title: pick(titles), body: pick(bodies) + bodySuffix);
    } else if (hour >= 14 && hour <= 17) {
      final titles = ['Öğleden Sonra Performansı 🚀', 'Dinç Kal!', 'Devam! 💧'];
      final bodies = [
        'Ritmini koru: küçük yudumlar büyük fark yaratır.',
        'Su içmek zihni tazeler. Hedefe adım adım!',
        'Bir bardak su ile enerjini yüksek tut.',
      ];
      return (title: pick(titles), body: pick(bodies) + bodySuffix);
    } else if (hour >= 18 && hour <= 21) {
      final titles = ['Akşam Rutinine Ekle 🌆', 'Günü Güzel Bitir', 'Akşam Hidrasyonu'];
      final bodies = [
        'Bugün harikaydı! Bir bardak suyla devam et.',
        'Akşam keyfi: suyla hafifle ve rahatla.',
        'Gün hedefin için bir bardak daha!',
      ];
      return (title: pick(titles), body: pick(bodies) + bodySuffix);
    } else {
      final titles = ['Geceye Hazırlık 🌙', 'Yumuşak Kapanış', 'Rahat Bir Gece'];
      final bodies = [
        'Bugün harikaydı! Bir bardak suyla günü bitir 🌙',
        'Uyku öncesi hafif bir su iyi gelir.',
        'Dinlenmeye geçmeden minik bir bardak su al.',
      ];
      return (title: pick(titles), body: pick(bodies) + bodySuffix);
    }
  }

  // ... (scheduleWaterReminders fonksiyonu aynı, değişiklik yok) ...
  Future<void> scheduleWaterReminders({
    required int sleepStartHour,
    required int sleepEndHour,
    required Duration interval,
  }) async {
    await cancelAllNotifications();
    if (interval.inMinutes <= 0) {
      if (kDebugMode) {
        print('[NotificationService] Geçersiz interval: ${interval.inMinutes}');
      }
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'water_reminder_id',
      'Su İçme Hatırlatıcıları',
      channelDescription: 'Düzenli su içme hatırlatıcıları için',
      importance: Importance.high,
      priority: Priority.high,
      // smallIcon: '@drawable/ic_notification', // Android ikon düzeltmesi
      // largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails platformChannelDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    int notificationId = 0;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime nextScheduleTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 0, 0);
    while(nextScheduleTime.isBefore(now)){
      nextScheduleTime = nextScheduleTime.add(interval);
    }
    if (nextScheduleTime.difference(now) > interval) {
      nextScheduleTime = nextScheduleTime.subtract(interval);
    }

    bool sleepWrapsMidnight = sleepEndHour <= sleepStartHour;
    int maxAlarms = (24 * 60) ~/ interval.inMinutes + 2;
    int alarmCount = 0;

    if (kDebugMode) {
      print('[NotificationService] Planlama başlıyor. Uyku: $sleepStartHour:00 - $sleepEndHour:00, Aralık: ${interval.inMinutes} dk');
    }

    while (alarmCount < maxAlarms) {
      alarmCount++;

      bool isAwakeTime;
      if (sleepWrapsMidnight) {
        isAwakeTime = nextScheduleTime.hour >= sleepEndHour && nextScheduleTime.hour <= sleepStartHour;
      } else {
        isAwakeTime = nextScheduleTime.hour >= sleepEndHour || nextScheduleTime.hour <= sleepStartHour;
      }

      if (isAwakeTime) {
        final msg = _titleBodyForHour(nextScheduleTime.hour);

        if (kDebugMode) {
          print('[NotificationService] (v2) Alarm kuruluyor: ID=$notificationId, Zaman=$nextScheduleTime, Mesaj="${msg.title}"');
        }

        await _notificationsPlugin.zonedSchedule(
          notificationId++,
          msg.title,
          msg.body,
          nextScheduleTime,
          platformChannelDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        if (kDebugMode) {
          print('[NotificationService] (v2) Uyku saati, alarm kurulmuyor: Zaman=$nextScheduleTime');
        }
      }

      nextScheduleTime = nextScheduleTime.add(interval);

      if (nextScheduleTime.difference(now).inHours >= 24) {
        if (kDebugMode) {
          print('[NotificationService] 24 saatlik planlama tamamlandı.');
        }
        break;
      }
    }

    // === 2) Özel hatırlatma saatleri ===
    final List<String> enabledCustomTimes =
    preferenceService.getEnabledCustomReminders();

    for (final timeString in enabledCustomTimes) {
      final parts = timeString.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;
      tz.TZDateTime customTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (customTime.isBefore(now)) {
        customTime = customTime.add(const Duration(days: 1));
      }

      bool isCustomTimeAwake;
      if (sleepWrapsMidnight) {
        isCustomTimeAwake = customTime.hour >= sleepEndHour && customTime.hour <= sleepStartHour;
      } else {
        isCustomTimeAwake = customTime.hour >= sleepEndHour || customTime.hour <= sleepStartHour;
      }

      if (!isCustomTimeAwake) {
        if (kDebugMode) {
          print('[NotificationService] Özel saat ($timeString) uyku saatine denk geldi, kurulmuyor.');
        }
        continue;
      }

      final msg = _titleBodyForHour(hour);

      if (kDebugMode) {
        print('[NotificationService] Özel Alarm kuruluyor: ID=$notificationId, Zaman=$customTime, Mesaj="${msg.title}"');
      }

      await _notificationsPlugin.zonedSchedule(
        notificationId++,
        msg.title.isNotEmpty ? msg.title : 'Özel Hatırlatıcı! ⏰',
        msg.body.isNotEmpty
            ? msg.body
            : '$timeString senin özel su içme saatin, kaçırma!',
        customTime,
        platformChannelDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
    if (kDebugMode) {
      print('[NotificationService] Planlama tamamlandı. Toplam ${notificationId} alarm kuruldu/denendi.');
    }
  }
}

final notificationService = NotificationService();