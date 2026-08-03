import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/pond/create_pond_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'AquaControl',
            theme: ThemeData(
              primarySwatch: Colors.teal,
              useMaterial3: true,
            ),
            locale: languageProvider.currentLocale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('km', ''),
            ],
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/create_pond': (context) => const CreatePondScreen(),
              '/schedule': (context) => const ScheduleScreen(),
              '/history': (context) => const HistoryScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
