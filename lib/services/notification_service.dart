// lib/services/notification_service.dart

// (FINAL) – Zaman dilimine göre akıllı metin + toggle'lı özel saat desteği



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



  /// Su içme hatırlatıcılarını planlar (Sabit aralık + Etkin özel saatler)

  Future<void> scheduleWaterReminders({

    required int startHour,

    required int endHour,

    required Duration interval,

  }) async {

    await cancelAllNotifications();



    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(

      'water_reminder_id',

      'Su İçme Hatırlatıcıları',

      channelDescription: 'Düzenli su içme hatırlatıcıları için',

      importance: Importance.high,

    );

    const NotificationDetails platformChannelDetails =

    NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());



    int notificationId = 0;



    // === 1) Sabit aralıklarla (uyanma–yatış arasında)

    tz.TZDateTime scheduledTime = tz.TZDateTime.now(tz.local);

    scheduledTime = tz.TZDateTime(

      tz.local,

      scheduledTime.year,

      scheduledTime.month,

      scheduledTime.day,

      startHour,

      0,

    );



    // geçmişse ertesi güne taşı

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {

      scheduledTime = scheduledTime.add(const Duration(days: 1));

    }



    while (scheduledTime.hour < endHour ||

        (scheduledTime.hour == endHour && scheduledTime.minute == 0)) {

      final msg = _titleBodyForHour(scheduledTime.hour);



      await _notificationsPlugin.zonedSchedule(

        notificationId++,

        msg.title,

        msg.body,

        scheduledTime,

        platformChannelDetails,

        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

        uiLocalNotificationDateInterpretation:

        UILocalNotificationDateInterpretation.absoluteTime,

        matchDateTimeComponents: DateTimeComponents.time, // her gün tekrar

      );



      scheduledTime = scheduledTime.add(interval);

      // güvenlik için: olası yanlış interval (0) durumunda sonsuz döngüyü kır

      if (interval.inMinutes <= 0 && interval.inSeconds <= 0) break;

    }



    // === 2) Özel hatırlatma saatleri (SADECE ETKİN OLANLAR)

    // Örn. ["09:30", "14:00", "20:15"]

    final List<String> enabledCustomTimes =

    preferenceService.getEnabledCustomReminders();



    for (final timeString in enabledCustomTimes) {

      final parts = timeString.split(':');

      if (parts.length != 2) continue;



      final hour = int.tryParse(parts[0]);

      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) continue;



      tz.TZDateTime customTime = tz.TZDateTime.now(tz.local);

      customTime = tz.TZDateTime(

        tz.local,

        customTime.year,

        customTime.month,

        customTime.day,

        hour,

        minute,

      );



      if (customTime.isBefore(tz.TZDateTime.now(tz.local))) {

        customTime = customTime.add(const Duration(days: 1));

      }



      final msg = _titleBodyForHour(hour);



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

        matchDateTimeComponents: DateTimeComponents.time, // her gün tekrar

      );

    }

  }

}



final notificationService = NotificationService();