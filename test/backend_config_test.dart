import 'package:fishcap_app/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiService backend config', () {
    test('uses an explicit override before platform defaults', () {
      expect(
        ApiService.resolveBackendBaseUrl(override: 'http://server.local:3001/'),
        'http://server.local:3001',
      );
    });

    test('uses Android emulator host on Android', () {
      expect(
        ApiService.resolveBackendBaseUrl(platform: TargetPlatform.android),
        'http://10.0.2.2:3001',
      );
    });

    test('uses localhost for non-Android targets', () {
      expect(
        ApiService.resolveBackendBaseUrl(platform: TargetPlatform.iOS),
        'http://localhost:3001',
      );
    });
  });
}
