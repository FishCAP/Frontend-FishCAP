import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:fishcap_app/screens/auth/forget_password_screen.dart';
import 'package:fishcap_app/screens/auth/reset_password_screen.dart';
import 'package:fishcap_app/services/api_service.dart';

Widget app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
  routes: {'/login': (_) => const Scaffold(body: Text('Login destination'))},
);

void main() {
  test('reset API uses OTP endpoint and email/code/password payload', () async {
    final paths = <String>[];
    await http.runWithClient(() async {
      expect(await ApiService.instance.requestPasswordReset(' test@example.test '), true);
      expect((await ApiService.instance.resetPassword(
        email: 'test@example.test', code: '123456', newPassword: 'newpassword1',
      ))['success'], true);
    }, () => MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path.endsWith('request-otp')) {
        expect(jsonDecode(request.body), {'email': 'test@example.test'});
      } else {
        expect(jsonDecode(request.body), {
          'email': 'test@example.test', 'code': '123456', 'password': 'newpassword1',
        });
      }
      return http.Response('{"success":true}', 200);
    }));
    expect(paths, ['/api/auth/request-otp', '/api/auth/reset-password']);
  });

  testWidgets('invalid email stays on form', (tester) async {
    await tester.pumpWidget(app(const ForgotPasswordScreen()));
    await tester.enterText(find.byType(TextFormField), 'bad@');
    await tester.tap(find.text('Send verification code'));
    await tester.pump();
    expect(find.byType(ResetPasswordScreen), findsNothing);
    expect(find.text('Check your email'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('request code then reset navigates to login', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(app(const ForgotPasswordScreen()));
      await tester.enterText(find.byType(TextFormField), 'test@example.test');
      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enter verification code'));
      await tester.pumpAndSettle();
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '123456');
      await tester.enterText(fields.at(1), 'newpassword1');
      await tester.enterText(fields.at(2), 'newpassword1');
      await tester.ensureVisible(find.text('Update password'));
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();
      expect(find.text('Login destination'), findsOneWidget);
    }, () => MockClient((request) async {
      if (request.url.path == '/api/auth/request-otp') {
        expect(jsonDecode(request.body), {'email': 'test@example.test'});
      } else {
        expect(request.url.path, '/api/auth/reset-password');
        expect(jsonDecode(request.body), {
          'email': 'test@example.test',
          'code': '123456',
          'password': 'newpassword1',
        });
      }
      return http.Response('{"success":true}', 200);
    }));
  });

  testWidgets('short passwords are rejected locally', (tester) async {
    await tester.pumpWidget(app(const ResetPasswordScreen(email: 'test@example.test')));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), '1234567');
    await tester.enterText(fields.at(2), '1234567');
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pump();
    expect(find.text('At least 8 characters'), findsOneWidget);
  });

  testWidgets('request network failure shows feedback and allows retry', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(app(const ForgotPasswordScreen()));
      await tester.enterText(find.byType(TextFormField), 'test@example.test');
      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();
      expect(find.text('Could not connect. Please try again.'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNotNull);
    }, () => MockClient((_) async => throw http.ClientException('offline')));
  });
}
