// lib/services/notification_service.dart
// (FINAL) – Zaman dilimine göre akıllı metin + UYKU SAATİ MANTIĞI (ÖZEL SAATLER DAHİL)

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

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      // iOS < 10 için bildirim tıklandığında eski callback (isteğe bağlı)
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      // Bildirime tıklandığında çağrılan callback (iOS >= 10 ve Android)
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      // Uygulama ön plandayken bildirim geldiğinde (iOS < 10)
      // onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse, // Bu yeni versiyonlarda değişmiş olabilir
    );
  }

  // Bildirime tıklandığında ne olacağı (payload ile bilgi taşınabilir)
  void onDidReceiveNotificationResponse(NotificationResponse response) async {
    // Örneğin payload'a göre farklı bir sayfaya yönlendirme yapılabilir
    if (response.payload != null) {
      debugPrint('notification payload: ${response.payload}');
      // navigatorKey.currentState?.pushNamed('/detail', arguments: response.payload);
    }
    // Veya sadece ana ekranı aç
  }

  /* // iOS < 10 için eski callback (artık pek gerekli değil)
  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    // showDialog(...);
  }
  */

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

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      // Android 13 (API 33) ve sonrası için özel izin isteği
      return await androidImplementation.requestNotificationsPermission();
    }
    return false; // Desteklenmeyen platform
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    if (kDebugMode) {
      print('[NotificationService] Tüm bildirimler iptal edildi.');
    }
  }

  /// === ZAMAN DİLİMLİ MESAJLAR ===
  /// 05–10 Sabah, 11–13 Öğle, 14–17 Öğleden sonra,
  /// 18–21 Akşam, 22–04 Gece
  ({String title, String body}) _titleBodyForHour(int hour) {
    String pick(List<String> list) => list[_rng.nextInt(list.length)];
    // Bildirim gövdesine eklenecek sabit metin (isteğe bağlı)
    // String bodySuffix = '\nİçtikten sonra onaylamak için bildirime dokunun.';
    String bodySuffix = ''; // Şimdilik boş bırakalım

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
      // Gece mesajları belki daha sakin olmalı?
      final titles = ['Geceye Hazırlık 🌙', 'Yumuşak Kapanış', 'Rahat Bir Gece'];
      final bodies = [
        'Bugün harikaydı! Bir bardak suyla günü bitir 🌙',
        'Uyku öncesi hafif bir su iyi gelir.',
        'Dinlenmeye geçmeden minik bir bardak su al.',
      ];
      // Gece bildirim gönderilmeyeceği için bu mesajlar aslında pek kullanılmayacak.
      return (title: pick(titles), body: pick(bodies) + bodySuffix);
    }
  }

  /// Su içme hatırlatıcılarını planlar (UYKU SAATLERİ DIŞINDA)
  Future<void> scheduleWaterReminders({
    required int sleepStartHour, // Uyku başlangıç saati (örn: 22)
    required int sleepEndHour,   // Uyku bitiş saati (örn: 8)
    required Duration interval,   // Hatırlatma sıklığı (örn: 60 dakika)
  }) async {
    await cancelAllNotifications();
    if (interval.inMinutes <= 0) {
      if (kDebugMode) {
        print('[NotificationService] Geçersiz interval: ${interval.inMinutes}');
      }
      return; // Geçersiz aralık ise çık
    }


    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'water_reminder_id',
      'Su İçme Hatırlatıcıları',
      channelDescription: 'Düzenli su içme hatırlatıcıları için',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails platformChannelDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    int notificationId = 0; // Her bildirim için ID artırılacak
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // İlk potansiyel alarm zamanını hesapla (bugün veya yarın saat 00:00'dan başlayarak interval ekle)
    // Bu, tüm günü taramamızı sağlar.
    tz.TZDateTime nextScheduleTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 0, 0);
    while(nextScheduleTime.isBefore(now)){
      nextScheduleTime = nextScheduleTime.add(interval);
    }
    // Eğer ilk saat `now`dan sonra ise, bir önceki intervale geri dönelim ki kaçırmayalım
    if (nextScheduleTime.difference(now) > interval) {
      nextScheduleTime = nextScheduleTime.subtract(interval);
    }


    // Gece yarısını geçme durumunu kontrol et (Uyku saatleri için)
    bool sleepWrapsMidnight = sleepEndHour <= sleepStartHour;

    // Döngüyü 24 saatlik bir periyotta en fazla kaç alarm olabileceği ile sınırlayalım
    int maxAlarms = (24 * 60) ~/ interval.inMinutes + 2; // +2 pay bırakalım
    int alarmCount = 0;

    if (kDebugMode) {
      print('[NotificationService] Planlama başlıyor. Uyku: $sleepStartHour:00 - $sleepEndHour:00, Aralık: ${interval.inMinutes} dk');
    }

    while (alarmCount < maxAlarms) {
      alarmCount++;

      // --- UYKU SAATİ KONTROLÜ (TERS MANTIK) ---
      // Şu anki `nextScheduleTime.hour` uyku aralığında mı?
      bool isSleepingTime;
      if (sleepWrapsMidnight) {
        // Uyku gece yarısını geçiyorsa (örn: 22:00 - 06:00)
        // Saat >= uyku başlangıcı VEYA Saat < uyku bitişi ise UYKU ZAMANI
        isSleepingTime = nextScheduleTime.hour >= sleepStartHour || nextScheduleTime.hour < sleepEndHour;
      } else {
        // Normal uyku aralığı (örn: 00:00 - 08:00)
        // Saat >= uyku başlangıcı VE Saat < uyku bitişi ise UYKU ZAMANI
        isSleepingTime = nextScheduleTime.hour >= sleepStartHour && nextScheduleTime.hour < sleepEndHour;
      }
      // --- BİTİŞ: UYKU SAATİ KONTROLÜ ---


      // Eğer UYKU ZAMANI DEĞİLSE (!isSleepingTime), alarmı kur
      if (!isSleepingTime) {
        final msg = _titleBodyForHour(nextScheduleTime.hour);

        if (kDebugMode) {
          print('[NotificationService] Alarm kuruluyor: ID=$notificationId, Zaman=$nextScheduleTime, Mesaj="${msg.title}"');
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
          matchDateTimeComponents: DateTimeComponents.time, // Her gün aynı saatte tekrarla
        );
      } else {
        if (kDebugMode) {
          print('[NotificationService] Uyku saati, alarm kurulmuyor: Zaman=$nextScheduleTime');
        }
      }

      // Bir sonraki alarm zamanını hesapla
      nextScheduleTime = nextScheduleTime.add(interval);

      // Döngüden çıkış kontrolü: Eğer bir sonraki saat, başlangıçtan 24 saatten fazla ilerideyse çık
      if (nextScheduleTime.difference(now).inHours >= 24) {
        if (kDebugMode) {
          print('[NotificationService] 24 saatlik planlama tamamlandı.');
        }
        break;
      }
    }

    // === 2) Özel hatırlatma saatleri (SADECE ETKİN OLANLAR ve UYKU KONTROLLÜ) ===
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

      // --- EKLENEN KONTROL BLOĞU ---
      // Bu özel saat, uyku saatleri aralığında mı?
      bool isCustomTimeSleeping;
      // sleepWrapsMidnight değişkeni yukarıdaki while döngüsünden önce tanımlanmıştı, onu kullanıyoruz.
      if (sleepWrapsMidnight) {
        // Uyku gece yarısını geçiyorsa (örn: 22:00 - 09:00)
        isCustomTimeSleeping = customTime.hour >= sleepStartHour || customTime.hour < sleepEndHour;
      } else {
        // Normal uyku aralığı (örn: 00:00 - 08:00)
        isCustomTimeSleeping = customTime.hour >= sleepStartHour && customTime.hour < sleepEndHour;
      }

      // EĞER UYKU SAATİ İSE, bu özel alarmı kurma ve sonraki saate geç
      if (isCustomTimeSleeping) {
        if (kDebugMode) {
          print('[NotificationService] Özel saat ($timeString) uyku saatine denk geldi, kurulmuyor.');
        }
        continue; // Sonraki timeString'e geç
      }
      // --- BİTİŞ: EKLENEN KONTROL BLOĞU ---


      // (Eğer uyku saati değilse, aşağıdaki kod çalışmaya devam edecek)
      final msg = _titleBodyForHour(hour); // Mesaj için orijinal 'hour' kullanılıyor

      if (kDebugMode) {
        print('[NotificationService] Özel Alarm kuruluyor: ID=$notificationId, Zaman=$customTime, Mesaj="${msg.title}"');
      }

      await _notificationsPlugin.zonedSchedule(
        notificationId++, // ID'yi artır
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
    } // For döngüsü bitti
    if (kDebugMode) {
      print('[NotificationService] Planlama tamamlandı. Toplam ${notificationId} alarm kuruldu/denendi.');
    }
  }
}

final notificationService = NotificationService();