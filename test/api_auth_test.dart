import 'dart:convert';

import 'package:fishcap_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = ApiService.instance;
  // Opaque transport fixtures, not JWTs or credentials.
  const loginToken = 'backend-response-token';
  const pondId = 'test-pond';

  http.Response signedIn() => http.Response(
    jsonEncode({
      'success': true,
      'data': {
        'id': 'test-user',
        'email': 'test@example.test',
        'token': loginToken,
      },
    }),
    200,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await api.clearToken();
  });

  test('login replaces saved token and PATCH forwards it unchanged', () async {
    await api.saveToken('stale-session');
    await http.runWithClient(
      () async {
        expect((await api.login('test@example.test', 'test'))['success'], true);
        expect(api.token, loginToken);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_token'), loginToken);
        expect(
          (await api.updatePond(pondId, {'name': 'Updated'}))['success'],
          true,
        );
        expect(api.token, loginToken);
        expect(api.userId, 'test-user');
      },
      () => MockClient((request) async {
        if (request.url.path == '/api/auth/login') return signedIn();
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/ponds/$pondId');
        expect(request.headers['Authorization'], 'Bearer $loginToken');
        expect(jsonDecode(request.body), {'name': 'Updated'});
        return http.Response('{"success":true,"data":{}}', 200);
      }),
    );
  });

  test(
    'missing login token fails rather than reusing stale credentials',
    () async {
      await api.saveToken('stale-session');
      await http.runWithClient(
        () async {
          final result = await api.login('test@example.test', 'test');
          expect(result['success'], false);
          expect(api.token, isNull);
          expect(
            (await SharedPreferences.getInstance()).getString('auth_token'),
            isNull,
          );
        },
        () => MockClient(
          (_) async =>
              http.Response('{"success":true,"data":{"id":"test-user"}}', 200),
        ),
      );
    },
  );

  test('204 PATCH is successful', () async {
    await api.saveToken(loginToken);
    await http.runWithClient(() async {
      expect(
        (await api.updatePond(pondId, {'name': 'Updated'}))['success'],
        true,
      );
    }, () => MockClient((_) async => http.Response('', 204)));
  });

  test(
    '400 PATCH preserves validation errors without dropping fields',
    () async {
      await api.saveToken(loginToken);
      var requests = 0;
      await http.runWithClient(
        () async {
          final result = await api.updatePond(pondId, {'feedingSchedules': []});
          expect(result['statusCode'], 400);
          expect(requests, 1);
        },
        () => MockClient((_) async {
          requests++;
          return http.Response('{"message":["Invalid schedule"]}', 400);
        }),
      );
    },
  );

  test('authenticated endpoints share the login token', () async {
    var authenticatedRequests = 0;
    await http.runWithClient(
      () async {
        await api.login('test@example.test', 'test');
        final requests = <Future<Map<String, dynamic>> Function()>[
          api.getPonds,
          () => api.createPond({'name': 'Test'}),
          () => api.getPondById(pondId),
          () => api.updatePond(pondId, {'name': 'Updated'}),
          () => api.deletePond(pondId),
          () => api.completePond(pondId),
          api.getAllSensorData,
          () =>
              api.addFeedSchedule(pondId: pondId, time: '08:00', title: 'Feed'),
          () => api.getFeedingLogs(pondId: pondId),
          api.getNotifications,
          () => api.createNotification(title: 'Test', message: 'Alert'),
          () => api.markNotificationRead('notification-id'),
          api.markAllNotificationsRead,
          api.getUserProfile,
          () => api.updateProfile(fullName: 'Test'),
          api.getDevices,
          api.getAvailableDevices,
          () => api.createDevice(deviceCode: 'test-device'),
          () => api.assignDevice('device-id', pondId),
        ];
        for (final request in requests) {
          expect((await request())['success'], true);
        }
        expect(authenticatedRequests, requests.length);
      },
      () => MockClient((request) async {
        if (request.url.path == '/api/auth/login') return signedIn();
        authenticatedRequests++;
        expect(request.headers['Authorization'], 'Bearer $loginToken');
        if (request.method == 'POST' &&
            request.url.path == '/api/notifications') {
          expect(jsonDecode(request.body), {
            'title': 'Test',
            'message': 'Alert',
            'isRead': false,
          });
        }
        return http.Response('{"success":true,"data":{}}', 200);
      }),
    );
  });

  test(
    'saved token is loaded before the first authenticated request',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', loginToken);
      await http.runWithClient(
        () async {
          expect((await api.getPonds())['success'], true);
        },
        () => MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer $loginToken');
          return http.Response('{"success":true,"data":[]}', 200);
        }),
      );
    },
  );

  test('unauthenticated requests stop locally', () async {
    await http.runWithClient(
      () async {
        expect((await api.getPonds())['statusCode'], 401);
      },
      () => MockClient((_) async {
        fail('An authenticated endpoint must not be called without a token');
      }),
    );
  });

  test(
    '401 clears the expired session without replaying the request',
    () async {
      await api.saveToken(loginToken);
      var requests = 0;
      await http.runWithClient(
        () async {
          expect((await api.getPonds())['statusCode'], 401);
          expect(requests, 1);
          expect(api.token, isNull);
          expect(
            (await SharedPreferences.getInstance()).getString('auth_token'),
            isNull,
          );
        },
        () => MockClient((_) async {
          requests++;
          return http.Response('{"message":"Unauthorized"}', 401);
        }),
      );
    },
  );

  test('late 401 cannot clear a newer login', () async {
    await api.saveToken('old-session');
    await http.runWithClient(
      () async {
        expect((await api.getPonds())['statusCode'], 401);
        expect(api.token, loginToken);
        expect(api.userId, 'test-user');
      },
      () => MockClient((request) async {
        if (request.url.path == '/api/auth/login') return signedIn();
        await api.login('test@example.test', 'test');
        return http.Response('{"message":"Unauthorized"}', 401);
      }),
    );
  });

  test('pending saved-session load cannot overwrite a newer token', () async {
    await api.saveToken('old-session');
    final pendingLoad = api.loadToken();
    await api.saveToken(loginToken);
    await pendingLoad;
    expect(api.token, loginToken);
    expect(
      (await SharedPreferences.getInstance()).getString('auth_token'),
      loginToken,
    );
  });

  test(
    'OTP records the authenticated user and logout clears identity',
    () async {
      await http.runWithClient(() async {
        expect(
          (await api.verifyOtp('test@example.test', 'test'))['success'],
          true,
        );
        expect(api.userId, 'test-user');
        expect(api.token, loginToken);
        await api.clearToken();
        expect(api.userId, isNull);
      }, () => MockClient((_) async => signedIn()));
    },
  );
}
