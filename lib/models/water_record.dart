import 'package:hive/hive.dart';

part 'water_record.g.dart'; // Hive kodu buraya üretecek

// 0 numaralı tip ID'si: Uygulamadaki bu modelin benzersiz kimliği
@HiveType(typeId: 0)
class WaterRecord extends HiveObject {
  @HiveField(0) // Bu alanın veritabanındaki indeksi
  final DateTime date; // Kaydın yapıldığı gün (Saat bilgisi olmadan)

  @HiveField(1) // Bu alanın veritabanındaki indeksi
  int amountInMl; // O gün tüketilen su miktarı (ml)

  WaterRecord({
    required this.date,
    required this.amountInMl,
  });

// Not: amountInMl bir HiveObject olduğu için güncellenebilir olmalıdır.
// Bu, daha sonra 'HiveObject' özelliklerini kullanarak kaydı kolayca güncellememizi sağlar.
}