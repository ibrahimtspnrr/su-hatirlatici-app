// lib/services/notification_service.dart
// (FINAL) – Zaman dilimine göre akıllı metin + GECE YARISI DÖNGÜ DÜZELTMESİ

import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'preference_service.dart'; // getEnabledCustomReminders için

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Aynı saat diliminde farklı cümleler için ufak bir rastgelelik
  final Random _rng = Random();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {},
    );
  }

  Future<bool?> requestPermissions() async {
    return await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    ) ??
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// === ZAMAN DİLİMLİ MESAJLAR ===
  /// 05–10 Sabah, 11–13 Öğle, 14–17 Öğleden sonra,
  /// 18–21 Akşam, 22–04 Gece
  ({String title, String body}) _titleBodyForHour(int hour) {
    String pick(List<String> list) => list[_rng.nextInt(list.length)];
    // İstediğiniz son cümle:
    String bodySuffix = '\nİçtikten sonra onaylamak için bildirime dokunun.';

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
    } else { // Gece saatleri (22, 23, 0, 1, 2, 3, 4)
      final titles = ['Geceye Hazırlık 🌙', 'Yumuşak Kapanış', 'Rahat Bir Gece'];
      final bodies = [
        'Bugün harikaydı! Bir bardak suyla günü bitir 🌙',
        'Uyku öncesi hafif bir su iyi gelir.',
        'Dinlenmeye geçmeden minik bir bardak su al.',
      ];
      return (title: pick(titles), body: pick(bodies) + bodySuffix);
    }
  }

  /// Su içme hatırlatıcılarını planlar (Sabit aralık + Etkin özel saatler + GECE YARISI DÜZELTMESİ)
  Future<void> scheduleWaterReminders({
    required int startHour,
    required int endHour,
    required Duration interval,
  }) async {
    await cancelAllNotifications();
    if (interval.inMinutes <= 0) return; // Geçersiz aralık ise çık

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'water_reminder_id',
      'Su İçme Hatırlatıcıları',
      channelDescription: 'Düzenli su içme hatırlatıcıları için',
      importance: Importance.high,
      priority: Priority.high, // Öncelik eklendi
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ); // iOS ayarları ayrıldı
    const NotificationDetails platformChannelDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    int notificationId = 0; // Her bildirim için ID artırılacak
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // === 1) Sabit aralıklarla (uyanma–yatış arasında) - GECE YARISI DÜZELTMELİ ===

    // İlk alarm zamanını hesapla (bugün veya yarın `startHour`:00)
    tz.TZDateTime nextScheduleTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      startHour,
      0, // Dakikayı 0 yapıyoruz
    );
    if (nextScheduleTime.isBefore(now)) {
      nextScheduleTime = nextScheduleTime.add(const Duration(days: 1));
    }

    // Gece yarısını geçme durumunu kontrol et
    bool wrapsMidnight = endHour <= startHour;

    // Döngüyü 24 saatlik bir periyotta en fazla kaç alarm olabileceği ile sınırlayalım
    // (Örn: 30 dk aralık = 48 alarm max) - Sonsuz döngüden kaçınmak için
    int maxAlarms = (24 * 60) ~/ interval.inMinutes + 1;
    int alarmCount = 0;


    while (alarmCount < maxAlarms) {
      alarmCount++;

      // Geçerli saat aralığında mıyız?
      bool isInRange;
      if (wrapsMidnight) {
        // Gece yarısını geçiyorsa (örn: 22:00 - 06:00)
        // Saat >= başlangıç VEYA Saat < bitiş olmalı
        isInRange = nextScheduleTime.hour >= startHour || nextScheduleTime.hour < endHour;
      } else {
        // Normal aralık (örn: 08:00 - 22:00)
        // Saat >= başlangıç VE Saat < bitiş olmalı
        isInRange = nextScheduleTime.hour >= startHour && nextScheduleTime.hour < endHour;
      }

      // Eğer geçerli aralıktaysak, alarmı kur
      if (isInRange) {
        final msg = _titleBodyForHour(nextScheduleTime.hour);
        await _notificationsPlugin.zonedSchedule(
          notificationId++,
          msg.title,
          msg.body,
          nextScheduleTime,
          platformChannelDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Her gün aynı saatte tekrarla
        );
      }

      // Bir sonraki alarm zamanını hesapla
      nextScheduleTime = nextScheduleTime.add(interval);

      // --- Döngüden Çıkış Kontrolü ---
      // Eğer bir sonraki saat, bir tam gün sonrasına denk geliyorsa
      // (yani tüm günü taradık), döngüden çıkabiliriz.
      // Bu, `endHour` kontrolünden daha güvenlidir.
      if (nextScheduleTime.difference(now).inDays >= 1 && alarmCount > 1) {
        break;
      }
    }

    // === 2) Özel hatırlatma saatleri (SADECE ETKİN OLANLAR) ===
    // Bu kısım aynı kalabilir, çünkü her saat için ayrı ayrı kontrol yapıyor.
    final List<String> enabledCustomTimes =
    preferenceService.getEnabledCustomReminders();

    for (final timeString in enabledCustomTimes) {
      final parts = timeString.split(':');
      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      tz.TZDateTime customTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (customTime.isBefore(now)) {
        customTime = customTime.add(const Duration(days: 1));
      }

      // Özel saat, kullanıcının belirlediği Uyanma/Yatış aralığında mı diye kontrol edelim (isteğe bağlı)
      // bool isInUserRange;
      // if (wrapsMidnight) {
      //   isInUserRange = customTime.hour >= startHour || customTime.hour < endHour;
      // } else {
      //   isInUserRange = customTime.hour >= startHour && customTime.hour < endHour;
      // }
      // if (!isInUserRange) continue; // Eğer aralık dışındaysa bu özel saati kurma

      final msg = _titleBodyForHour(hour);
      await _notificationsPlugin.zonedSchedule(
        notificationId++, // ID'nin çakışmaması için artırmaya devam et
        msg.title.isNotEmpty ? msg.title : 'Özel Hatırlatıcı! ⏰',
        msg.body.isNotEmpty
            ? msg.body
            : '$timeString senin özel su içme saatin, kaçırma!',
        customTime,
        platformChannelDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Her gün tekrarla
      );
    }
  }
}

final notificationService = NotificationService();