import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:readaura/screens/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:pdfrx/pdfrx.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await pdfrxFlutterInitialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ReadAuraApp());
}

class ReadAuraApp extends StatelessWidget {
  const ReadAuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReadAura',

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        material_ui.GlobalMaterialLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en'),
      ],

      // GLOBAL READAURA THEME
      // Times New Roman is applied throughout the app.
      theme: ThemeData(
        fontFamily: 'Times New Roman',

        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Times New Roman',
        ),

        primaryTextTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Times New Roman',
        ),

        scaffoldBackgroundColor: const Color(0xFFFFF9FC),

        primaryColor: const Color(0xFFC8B6E2),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF9FC),
          foregroundColor: Color(0xFF5E5368),
          elevation: 0,

          titleTextStyle: TextStyle(
            fontFamily: 'Times New Roman',
            color: Color(0xFF5E5368),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(
            fontFamily: 'Times New Roman',
          ),
          labelStyle: TextStyle(
            fontFamily: 'Times New Roman',
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Times New Roman',
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Times New Roman',
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Times New Roman',
            ),
          ),
        ),

        dialogTheme: const DialogThemeData(
          titleTextStyle: TextStyle(
            fontFamily: 'Times New Roman',
            color: Color(0xFF6B5B7B),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: TextStyle(
            fontFamily: 'Times New Roman',
            color: Color(0xFF7D7183),
            fontSize: 15,
          ),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}