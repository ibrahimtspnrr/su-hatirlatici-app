// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Su Hatırlatıcı';

  @override
  String get welcomeMessage => 'Hidrasyon takipçinize hoş geldiniz!';

  @override
  String get startButton => 'Kullanmaya Başla';

  @override
  String get dailyGoal => 'Günlük Su Hedefi';

  @override
  String get reminder => 'Hatırlatıcı';

  @override
  String get addWater => 'Su Ekle';
}
