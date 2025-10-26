// lib/main.dart (Soft Mavi tema + Çoklu dil desteği – TR/EN, cihaz diline göre)



import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:timezone/data/latest_all.dart' as tz;

import 'package:timezone/timezone.dart' as tz;

import 'package:hive_flutter/hive_flutter.dart';



import 'screens/main_screen.dart';

import 'screens/onboarding_screen.dart';

import 'services/preference_service.dart';

import 'services/notification_service.dart';

import 'services/water_record_service.dart';

import 'models/water_record.dart';



// ⬇️ gen-l10n çıktısı (AppLocalizations) – dosyalar: lib/l10n/app_*.dart

import 'l10n/app_localizations.dart';



MaterialColor createMaterialColor(Color color) {

  List strengths = <double>[.05];

  final Map<int, Color> swatch = {};

  final r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) strengths.add(0.1 * i);

  for (var s in strengths) {

    final ds = 0.5 - s;

    swatch[(s * 1000).round()] = Color.fromRGBO(

      r + ((ds < 0 ? r : (255 - r)) * ds).round(),

      g + ((ds < 0 ? g : (255 - g)) * ds).round(),

      b + ((ds < 0 ? b : (255 - b)) * ds).round(),

      1,

    );

  }

  return MaterialColor(color.value, swatch);

}



void main() async {

  WidgetsFlutterBinding.ensureInitialized();



  // Hive

  await Hive.initFlutter();

  Hive.registerAdapter(WaterRecordAdapter());



  // Servisler

  await preferenceService.init();

  await waterRecordService.init();



  // Zaman dilimi

  tz.initializeTimeZones();

  tz.setLocalLocation(tz.local);



  // Bildirimler

  await notificationService.init();

  await notificationService.requestPermissions();



  runApp(const WaterTrackerApp());

}



class WaterTrackerApp extends StatefulWidget {

  const WaterTrackerApp({super.key});

  static _WaterTrackerAppState of(BuildContext context) =>

      context.findAncestorStateOfType<_WaterTrackerAppState>()!;

  @override

  State<WaterTrackerApp> createState() => _WaterTrackerAppState();

}



class _WaterTrackerAppState extends State<WaterTrackerApp> {

  late bool _onboardingComplete;

  ThemeMode _themeMode = ThemeMode.system;

  Color _primaryColor = const Color(0xFF64B5F6); // soft mavi



  @override

  void initState() {

    super.initState();

    _onboardingComplete = preferenceService.isOnboardingComplete();

    _loadThemeSettings();

  }



  void _loadThemeSettings() {

    final modeString = preferenceService.getThemeMode();

    final colorHex = preferenceService.getAppPrimaryColorHex();

    setState(() {

      _themeMode = ThemeMode.values.firstWhere(

            (e) => e.toString() == 'ThemeMode.$modeString',

        orElse: () => ThemeMode.system,

      );

      try {

        _primaryColor = Color(int.parse(colorHex));

      } catch (_) {

        _primaryColor = const Color(0xFF64B5F6);

      }

    });

  }



  void setThemeAndColor(ThemeMode mode, String colorHex) {

    setState(() {

      _themeMode = mode;

      _primaryColor = Color(int.parse(colorHex));

      preferenceService.saveThemeMode(mode.toString().split('.').last);

      preferenceService.saveAppPrimaryColor(colorHex);

    });

  }



  ThemeData _buildDarkTheme(MaterialColor swatch) {

    final scheme = ColorScheme.fromSeed(

      seedColor: _primaryColor,

      brightness: Brightness.dark,

    );

    return ThemeData(

      useMaterial3: true,

      colorScheme: scheme,

      scaffoldBackgroundColor: Colors.grey.shade900,

      cardColor: Colors.grey.shade800,

      appBarTheme: AppBarTheme(

        backgroundColor: Colors.grey.shade900,

        foregroundColor: Colors.white,

      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(

        selectedItemColor: scheme.primary,

        unselectedItemColor: Colors.grey.shade500,

      ),

      dialogBackgroundColor: Colors.grey.shade800,

    );

  }



  @override

  Widget build(BuildContext context) {

    final swatch = createMaterialColor(_primaryColor);

    final lightScheme = ColorScheme.fromSeed(seedColor: _primaryColor);

    final darkTheme = _buildDarkTheme(swatch);



    final lightTheme = ThemeData(

      useMaterial3: true,

      colorScheme: lightScheme,

      scaffoldBackgroundColor: const Color(0xFFF0F4F8),

    );



    return MaterialApp(

      debugShowCheckedModeBanner: false,



      // 🌐 Çoklu dil – cihaz diline göre TR/EN

      localizationsDelegates: const [

        AppLocalizations.delegate,                 // ⬅️ önemli

        GlobalMaterialLocalizations.delegate,

        GlobalWidgetsLocalizations.delegate,

        GlobalCupertinoLocalizations.delegate,

      ],

      supportedLocales: AppLocalizations.supportedLocales,

      localeResolutionCallback: (locale, supportedLocales) {

        for (final l in supportedLocales) {

          if (l.languageCode == locale?.languageCode) return l;

        }

        return supportedLocales.first;

      },



      title: 'Su Hatırlatıcı',

      theme: lightTheme,

      darkTheme: darkTheme,

      themeMode: _themeMode,

      home: _onboardingComplete ? const MainScreen() : const OnboardingScreen(),

    );

  }

}