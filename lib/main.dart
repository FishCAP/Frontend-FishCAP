import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/pond/create_pond_screen.dart';
import 'screens/sensors/sensor_dashboard_screen.dart';
import 'utils/page_transitions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
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
            onGenerateRoute: (settings) {
              // Apply custom transitions based on route
              switch (settings.name) {
                case '/login':
                  return PageTransitions.fade(const LoginScreen());
                case '/register':
                  return PageTransitions.slideFromRight(const RegisterScreen());
                case '/home':
                  return PageTransitions.fade(const HomeScreen());
                case '/create_pond':
                  return PageTransitions.slideFromRight(const CreatePondScreen());
                case '/schedule':
                  return PageTransitions.fade(const ScheduleScreen());
                case '/history':
                  return PageTransitions.fade(const HistoryScreen());
                case '/notifications':
                  return PageTransitions.slideFromRight(const NotificationsScreen());
                case '/profile':
                  return PageTransitions.fade(const ProfileScreen());
                case '/settings':
                  return PageTransitions.slideFromRight(const SettingsScreen());
                case '/sensor_dashboard':
                  return PageTransitions.slideFromRight(const SensorDashboardScreen());
                default:
                  return PageTransitions.fade(const LoginScreen());
              }
            },
          );
        },
      ),
    );
  }
}
