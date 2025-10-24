// lib/services/preference_service.dart (GÜNCEL – toggle + yaş/boy + cinsiyet destekli)

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ReminderTime {
  final String time; // "HH:MM"
  bool enabled;
  ReminderTime({required this.time, required this.enabled});

  String encode() => '$time|${enabled ? 1 : 0}';

  static ReminderTime parse(String s) {
    if (!s.contains('|')) {
      return ReminderTime(time: s, enabled: true);
    }
    final parts = s.split('|');
    final t = parts[0];
    final en = parts.length > 1 ? parts[1] : '1';
    return ReminderTime(time: t, enabled: en == '1');
  }
}

class PreferenceService {
  // --- Keys ---
  static const _onboardingKey = 'onboarding_complete';
  static const _weightKey = 'user_weight';
  static const _heightKey = 'user_height_cm';
  static const _ageKey = 'user_age';
  static const _genderKey = 'user_gender';               // 🔹 NEW: "male" | "female"
  static const _dailyGoalKey = 'daily_water_goal';
  static const _customVolumesKey = 'custom_volumes';
  static const _startHourKey = 'reminder_start_hour';
  static const _endHourKey = 'reminder_end_hour';
  static const _reminderIntervalKey = 'reminder_interval_minutes';
  static const _themeKey = 'app_theme_mode';
  static const _customRemindersKey = 'custom_reminder_times';
  static const _appPrimaryColorKey = 'app_primary_color';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Eski tip sapıtmalarını temizle
    if (_prefs.containsKey(_themeKey)) {
      final dynamic value = _prefs.get(_themeKey);
      if (value is int || value is bool) {
        await _prefs.remove(_themeKey);
      }
    }

    // Varsayılan tema rengi (Soft Mavi)
    const String softBlueHex = '0xFF64B5F6';
    await _prefs.setString(_appPrimaryColorKey, softBlueHex);
  }

  // --- Onboarding ---
  bool isOnboardingComplete() => _prefs.getBool(_onboardingKey) ?? false;
  Future<void> setOnboardingComplete() async => _prefs.setBool(_onboardingKey, true);

  // --- Kişisel veriler ---
  Future<void> saveWeight(double weight) async => _prefs.setDouble(_weightKey, weight);
  double getWeight() => _prefs.getDouble(_weightKey) ?? 70.0;

  Future<void> saveHeightCm(int cm) async => _prefs.setInt(_heightKey, cm);
  int getHeightCm() => _prefs.getInt(_heightKey) ?? 170;

  Future<void> saveAge(int age) async => _prefs.setInt(_ageKey, age);
  int getAge() => _prefs.getInt(_ageKey) ?? 25;

  Future<void> saveGender(String gender) async => _prefs.setString(_genderKey, gender); // "male" | "female"
  String getGender() => _prefs.getString(_genderKey) ?? 'male';

  Future<void> saveDailyGoal(int goalInMl) async => _prefs.setInt(_dailyGoalKey, goalInMl);
  int getDailyGoal() => _prefs.getInt(_dailyGoalKey) ?? 2000;

  // --- Hızlı bardaklar ---
  List<int> getCustomVolumes() {
    final list = _prefs.getStringList(_customVolumesKey) ?? ['200', '330', '500'];
    return list.map((e) => int.tryParse(e) ?? 0).toList();
  }
  Future<void> saveCustomVolumes(List<int> volumes) async =>
      _prefs.setStringList(_customVolumesKey, volumes.map((e) => e.toString()).toList());

  // --- Hatırlatma (sabit aralık) ---
  Future<void> saveReminderHours(int start, int end) async {
    await _prefs.setInt(_startHourKey, start);
    await _prefs.setInt(_endHourKey, end);
  }
  int getStartHour() => _prefs.getInt(_startHourKey) ?? 8;
  int getEndHour() => _prefs.getInt(_endHourKey) ?? 22;

  Future<void> saveReminderInterval(int minutes) async =>
      _prefs.setInt(_reminderIntervalKey, minutes);
  int getReminderInterval() => _prefs.getInt(_reminderIntervalKey) ?? 60;

  // --- Özel hatırlatmalar (toggle destekli) ---
  List<ReminderTime> getReminderTimes() {
    final raw = _prefs.getStringList(_customRemindersKey) ?? <String>[];
    final items = raw.map(ReminderTime.parse).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  Future<void> saveReminderTimes(List<ReminderTime> items) async {
    final raw = items.map((e) => e.encode()).toList();
    await _prefs.setStringList(_customRemindersKey, raw);
  }

  // Sadece etkin saatler
  List<String> getEnabledCustomReminders() {
    return getReminderTimes()
        .where((e) => e.enabled)
        .map((e) => e.time)
        .toList();
  }

  // --- Günlük tüketim ---
  int getTodayIntake() => _prefs.getInt('today_intake') ?? 0;
  Future<void> saveTodayIntake(int intake) async => _prefs.setInt('today_intake', intake);
  String getTodayDate() => _prefs.getString('today_date') ?? '';
  Future<void> saveTodayDate(String date) async => _prefs.setString('today_date', date);

  // --- Tema modu & renk ---
  String getThemeMode() => _prefs.getString(_themeKey) ?? 'system';
  Future<void> saveThemeMode(String mode) async => _prefs.setString(_themeKey, mode);

  Future<void> saveAppPrimaryColor(String colorHex) async =>
      _prefs.setString(_appPrimaryColorKey, colorHex);

  String getAppPrimaryColorHex() =>
      _prefs.getString(_appPrimaryColorKey) ?? '0xFF64B5F6';
}

final preferenceService = PreferenceService();
