// lib/services/water_record_service.dart (SON HALİ - Veri Silme Metodu)

import 'package:hive_flutter/hive_flutter.dart';
import 'package:su_icme_uygulamasi/models/water_record.dart';
import 'package:flutter/foundation.dart';

const String waterRecordBox = 'waterRecords';

class WaterRecordService {
  late Box<WaterRecord> _box;

  ValueListenable<Box<WaterRecord>> get waterBox => _box.listenable();

  Future<void> init() async {
    _box = await Hive.openBox<WaterRecord>(waterRecordBox);
  }

  // Tarihe göre bir kaydı getirir veya oluşturur
  WaterRecord _getOrCreateRecord(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day).toIso8601String();

    WaterRecord? record = _box.get(dateKey);

    if (record == null) {
      record = WaterRecord(date: date, amountInMl: 0);
      _box.put(dateKey, record);
    }
    return record;
  }

  // Bugüne özel güncelleme metotları
  int getTodayIntake() {
    return _getOrCreateRecord(DateTime.now()).amountInMl;
  }

  // Bugünü güncelle
  Future<void> updateTodayIntake(int amount) async {
    final todayRecord = _getOrCreateRecord(DateTime.now());
    todayRecord.amountInMl = amount;
    await todayRecord.save();
  }

  // Belirli bir tarihi güncelle
  Future<void> updateWaterForDate(DateTime date, int newAmount) async {
    final record = _getOrCreateRecord(date);
    record.amountInMl = newAmount;
    await record.save();
  }

  // --- İstatistik Metotları ---

  List<WaterRecord> getAllRecords() {
    final records = _box.values.toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  List<WaterRecord> getRecordsInPeriod(DateTime startDate, DateTime endDate) {
    final filteredRecords = _box.values.where((record) {
      final dateOnly = DateTime(record.date.year, record.date.month, record.date.day);
      return (dateOnly.isAfter(startDate) || dateOnly.isAtSameMomentAs(startDate)) &&
          (dateOnly.isBefore(endDate) || dateOnly.isAtSameMomentAs(endDate));
    }).toList();

    filteredRecords.sort((a, b) => b.date.compareTo(a.date));
    return filteredRecords;
  }

  // YENİ METOT: Tüm Hive verilerini siler
  Future<void> clearAllRecords() async {
    await _box.clear();
    // Ana sayfadaki güncel tüketimi de sıfırlamak için bugünün kaydını 0 yapalım
    await updateTodayIntake(0);
  }
}

final waterRecordService = WaterRecordService();