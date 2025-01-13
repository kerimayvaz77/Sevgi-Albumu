import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/my_home_page.dart';
import 'screens/splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sevgi Albümü',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4B6E),
          primary: const Color(0xFFFF4B6E),
          secondary: const Color(0xFFFF8FA3),
          tertiary: const Color(0xFFFFB3C1),
        ),
        scaffoldBackgroundColor: const Color(0xFFFF4B6E),
        useMaterial3: true,
      ),
      home: const SplashScreen(
        child: MyHomePage(),
      ),
    );
  }
}
