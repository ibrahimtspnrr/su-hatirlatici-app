// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Water Reminder';

  @override
  String get welcomeMessage => 'Welcome to your hydration tracker!';

  @override
  String get startButton => 'Get Started';

  @override
  String get dailyGoal => 'Daily Water Goal';

  @override
  String get reminder => 'Reminder';

  @override
  String get addWater => 'Add Water';
}
