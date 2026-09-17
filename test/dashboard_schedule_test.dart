import 'dart:convert';

import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:fishcap_app/screens/home/dashboard_screen.dart';
import 'package:fishcap_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Add New Time sends only schedule DTO fields and reloads', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.instance.saveToken('opaque-test-session');
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() async {
      await ApiService.instance.clearToken();
      await tester.binding.setSurfaceSize(null);
    });
    final schedules = <Map<String, dynamic>>[
      {'id': 'existing', 'feedTime': '08:00', 'feedAmount': 0.5},
    ];
    Map<String, dynamic>? sent;
    var reads = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DashboardScreen(pondId: 'test-pond', pondName: 'Test pond'),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add New Time'));
      await tester.tap(find.text('Add New Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.byIcon(Icons.schedule)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, '1.5');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(sent, isNotNull);
      final entries = sent!['feedingSchedules'] as List;
      expect(entries, hasLength(2));
      expect(entries.first, {'time': '08:00', 'amount': 0.5});
      expect(entries.last['amount'], 1.5);
      expect(entries.last['time'], matches(r'^\d{2}:\d{2}$'));
      for (final entry in entries) {
        expect((entry as Map).keys, unorderedEquals(['time', 'amount']));
      }
      expect(reads, 2);
      expect(find.text('Feed schedule added'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => MockClient((request) async {
      expect(request.url.path, '/api/ponds/test-pond');
      expect(request.headers['Authorization'], 'Bearer opaque-test-session');
      if (request.method == 'PATCH') {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        schedules
          ..clear()
          ..addAll((sent!['feedingSchedules'] as List).map(
            (s) => Map<String, dynamic>.from(s as Map)));
      } else {
        expect(request.method, 'GET');
        reads++;
      }
      return http.Response(jsonEncode({
        'success': true,
        'data': {'id': 'test-pond', 'feedSchedules': schedules},
      }), 200);
    }));
  });
}
