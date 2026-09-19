import 'package:fishcap_app/screens/auth/forget_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'app/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/pond/create_pond_screen.dart';
import 'screens/sensors/sensor_dashboard_screen.dart';
import 'screens/feeding_calculator/feeding_calculator_screen.dart';
import 'services/api_service.dart';
import 'services/realtime_service.dart';
import 'utils/page_transitions.dart';

/// Decide whether to land on /schedule or /login based on a *valid* persisted
/// JWT. This also eliminates the old race where screens fired API calls
/// before the asynchronously-loaded token was available.
Future<bool> _hasValidSession() async {
  await ApiService.instance.loadToken();
  if (ApiService.instance.token == null) return false;

  try {
    // Cheap validity probe. The service clears dead tokens automatically
    // after a confirmed 401, so the next login starts fresh.
    final result = await ApiService.instance
        .getUserProfile()
        .timeout(const Duration(seconds: 6));
    return result['success'] == true;
  } catch (_) {
    // Backend unreachable/offline: fall back to /login, which is always a
    // safe entry point; login will refresh everything from scratch.
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must finish before runApp so no screen can issue an unauthorized request.
  final initialRoute = await _hasValidSession() ? '/schedule' : '/login';

  final backendHost = ApiService.resolveBackendBaseUrl(
    override: const String.fromEnvironment('FISHCAP_BACKEND_URL'),
  );

  // Initialize realtime notifications (best-effort). Use the same backend host
  // as the API, or override it at build time with:
  // flutter run --dart-define=FISHCAP_BACKEND_URL=http://<LAN_IP>:3001
  await RealtimeService.instance.init(url: backendHost);

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = '/login'});

  /// First route shown at startup ('/schedule' when a valid saved JWT exists).
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, languageProvider, themeProvider, child) {
          return MaterialApp(
            title: 'FishCAP',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
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
            initialRoute: initialRoute,
            onGenerateRoute: (settings) {
              // Apply custom transitions based on route
              switch (settings.name) {
                case '/login':
                  return PageTransitions.fade(const LoginScreen());
                case '/register':
                  return PageTransitions.slideFromRight(const RegisterScreen());
                case '/forgot_password':
                  return PageTransitions.slideFromRight(const ForgotPasswordScreen());
                case '/home':
                  return PageTransitions.fade(const ScheduleScreen());
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
                case '/feeding_calculator':
                  return PageTransitions.slideFromRight(const FeedingCalculatorScreen());
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
