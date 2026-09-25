import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageService(),
      child: const AgriScanApp(),
    ),
  );
}

class AgriScanApp extends StatelessWidget {
  const AgriScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

    return MaterialApp(
      onGenerateTitle:
          (context) =>
              AppLocalizations(languageService.locale).translate('app_title'),
      debugShowCheckedModeBanner: false,
      locale: languageService.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('te'),
        Locale('hi'),
        Locale('bn'),
        Locale('ta'),
        Locale('mr'),
        Locale('ur'),
        Locale('gu'),
        Locale('kn'),
        Locale('ml'),
        Locale('pa'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8CC63F),
          primary: const Color(0xFF8CC63F),
          secondary: const Color(0xFF40916C),
          surface: Colors.white,
          background: const Color(0xFFF8F9F5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1B262C),
          elevation: 0,
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
