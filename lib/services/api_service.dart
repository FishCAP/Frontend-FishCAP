import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Singleton: the whole app shares one instance so the JWT token and userId
  // are kept in sync everywhere (previously each screen created a new
  // ApiService, losing the token and causing repeated 401/500s).
  static final ApiService instance = ApiService._internal();

  factory ApiService() => instance;

  ApiService._internal();

  String? token;
  String? userId;

  /// The API host differs per platform:
  /// - Android emulator reaches the host machine via 10.0.2.2
  /// - iOS simulator / desktop / web can use localhost directly
  ///
  /// Uses `kIsWeb` + `defaultTargetPlatform` instead of `dart:io Platform`,
  /// which is not available on the web (would throw `Unsupported operation:
  /// _Namespace` at startup).
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.43.246:3001/api';
    }
    return 'http://localhost:3001/api';
  }

  static const Duration _timeout = Duration(seconds: 15);

  // Token storage key
  static const String _tokenKey = 'auth_token';

  // --------------------------------------------------
  // Token management
  // --------------------------------------------------
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String newToken) async {
    token = newToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
  }

  Future<void> clearToken() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // --------------------------------------------------
  // Authentication
  // --------------------------------------------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_timeout);

    final result = _processResponse(response);

    // Persist the JWT token if the backend returned one so the session
    // survives hot-reloads / app restarts.
    if (result['success'] == true && result['data'] is Map) {
      final data = result['data'] as Map;
      // Extract userId – adjust based on your actual response structure
      if (data.containsKey('user') && data['user'] is Map) {
        final user = data['user'] as Map;
        userId = user['id'] as String?;
      } else if (data.containsKey('id')) {
        userId = data['id'] as String?;
      }
      if (data.containsKey('token')) {
        await saveToken(data['token'] as String);
      }
    }

    return result;
  }

  Future<Map<String, dynamic>> requestOtp(String email) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/request-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(_timeout);

    return _processResponse(response);
  }

  /// OTP verification.
  /// If the user does not exist yet, the backend creates a new user using
  /// [fullName], [password] and [phone].
  Future<Map<String, dynamic>> verifyOtp(
    String email,
    String code, {
    String? fullName,
    String? password,
    String? phone,
  }) async {
    final body = <String, dynamic>{'email': email, 'code': code};

    if (fullName != null && fullName.isNotEmpty) {
      body['fullName'] = fullName;
    }
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    final result = _processResponse(response);

    // If token is returned, store it
    if (result['success'] == true && result['data'] is Map) {
      final data = result['data'] as Map;
      if (data.containsKey('token')) {
        await saveToken(data['token'] as String);
      }
      // If user data is inside a nested 'user' key, we don't need to store token separately
      if (data.containsKey('user') &&
          data['user'] is Map &&
          data['user'].containsKey('token')) {
        final userData = data['user'] as Map;
        if (userData.containsKey('token')) {
          await saveToken(userData['token'] as String);
        }
      }
    }

    return result;
  }

  // --------------------------------------------------
  // User profile
  // --------------------------------------------------
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _sendAuthenticated(
      (headers) => http
          .get(Uri.parse('$baseUrl/users/me'), headers: headers)
          .timeout(_timeout),
    );

    return _processResponse(response);
  }

  // --------------------------------------------------
  // Notifications
  // --------------------------------------------------
  Future<Map<String, dynamic>> getNotifications() async {
    final response = await _sendAuthenticated(
      (headers) => http
          .get(Uri.parse('$baseUrl/notifications'), headers: headers)
          .timeout(_timeout),
    );
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final response = await _sendAuthenticated(
      (headers) => http
          .patch(
            Uri.parse('$baseUrl/notifications/$id'),
            headers: headers,
            body: jsonEncode({'isRead': true}),
          )
          .timeout(_timeout),
    );
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final response = await _sendAuthenticated(
      (headers) => http
          .patch(
            Uri.parse('$baseUrl/notifications/mark-all-read'),
            headers: headers,
          )
          .timeout(_timeout),
    );
    return _processResponse(response);
  }

  /// Fetch all ponds for the current user.
  Future<Map<String, dynamic>> getPonds() async {
    final response = await _sendAuthenticated(
      (headers) => http
          .get(Uri.parse('$baseUrl/ponds'), headers: headers)
          .timeout(_timeout),
    );

    return _processResponse(response);
  }

  /// Update the current user's full name and phone number.
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    final body = <String, dynamic>{'fullName': fullName};

    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }

    final response = await _sendAuthenticated(
      (headers) => http
          .patch(
            Uri.parse('$baseUrl/users/me'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout),
    );

    return _processResponse(response);
  }

  /// Upload a profile image for the current user.
  ///
  /// Uses [MultipartFile.fromBytes] which works on web, iOS, Android and
  /// desktop — unlike `fromPath` which requires `dart:io` and throws
  /// `Unsupported operation: _Namespace` on the web.
  Future<Map<String, dynamic>> uploadProfileImageBytes(
    Uint8List bytes, {
    String filename = 'profile.jpg',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/me/profile-image'),
    );

    // Add auth header
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);

    return _processResponse(response);
  }

  // --------------------------------------------------
  // Logout
  // --------------------------------------------------
  Future<void> logout() async {
    // Optionally call the backend to invalidate the token/session.
    // If your backend does not require a call, you can simply clear the token.
    if (token != null) {
      try {
        await http
            .post(Uri.parse('$baseUrl/auth/logout'), headers: _authHeaders())
            .timeout(_timeout);
      } catch (_) {
        // Ignore errors; we'll clear the token anyway
      }
    }

    // Clear token locally
    await clearToken();
  }

  /// Create a new pond.
  ///
  /// The first request uses the current NestJS contract.  Some existing
  /// FishCap deployments still expose the older pondName/fishType/fishCount
  /// contract; a validation-only 400 is safely retried with that payload.
  Future<Map<String, dynamic>> createPond(Map<String, dynamic> pondData) async {
    var response = await _sendAuthenticated(
      (headers) => http
          .post(
            Uri.parse('$baseUrl/ponds'),
            headers: headers,
            body: jsonEncode(pondData),
          )
          .timeout(_timeout),
    );

    if (response.statusCode == 400) {
      // Same fields as today's DTO but with only keys guaranteed to exist,
      // so the retry can succeed even when optional values are missing.
      final legacyPayload = <String, dynamic>{
        'name': pondData['name'] ?? pondData['pondName'],
        'species': pondData['species'] ?? pondData['fishType'],
        'estimatedCount':
            pondData['estimatedCount'] ?? pondData['fishCount'] ?? 0,
      };
      response = await _sendAuthenticated(
        (headers) => http
            .post(
              Uri.parse('$baseUrl/ponds'),
              headers: headers,
              body: jsonEncode(legacyPayload),
            )
            .timeout(_timeout),
      );
    }

    return _processResponse(response);
  }

  /// Update an existing pond by ID.
  /// [pondId] is the ID of the pond to update.
  /// [pondData] contains the fields to update.
  // Future<Map<String, dynamic>> updatePond(
  //   String pondId,
  //   Map<String, dynamic> pondData,
  // ) async {
  //   final response = await http
  //       .patch(
  //         Uri.parse('$baseUrl/ponds/$pondId'),
  //         headers: _authHeaders(),
  //         body: jsonEncode(pondData),
  //       )
  //       .timeout(_timeout);

  //   return _processResponse(response);
  // }

  /// Delete a pond by ID.
  Future<Map<String, dynamic>> deletePond(String pondId) async {
    final response = await _sendAuthenticated(
      (headers) => http
          .delete(Uri.parse('$baseUrl/ponds/$pondId'), headers: headers)
          .timeout(_timeout),
    );

    return _processResponse(response);
  }

  /// Fetch a single pond's full details by ID.
  Future<Map<String, dynamic>> getPondById(String pondId) async {
    final response = await _sendAuthenticated(
      (headers) => http
          .get(Uri.parse('$baseUrl/ponds/$pondId'), headers: headers)
          .timeout(_timeout),
    );

    return _processResponse(response);
  }

  // --------------------------------------------------
  // Sensor data (ESP32)
  // --------------------------------------------------

  /// Fetch the latest sensor readings from the backend.
  Future<Map<String, dynamic>> getLatestSensorData() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/sensor-data/latest'),
          headers: const {'Content-Type': 'application/json'},
        )
        .timeout(_timeout);

    return _processResponse(response);
  }

  /// Fetch all sensor readings from the backend.
  Future<Map<String, dynamic>> getAllSensorData() async {
    final response = await _sendAuthenticated(
      (headers) => http
          .get(Uri.parse('$baseUrl/sensors/data'), headers: headers)
          .timeout(_timeout),
    );

    return _processResponse(response);
  }

  /// Create a new feed schedule for a pond.
  Future<Map<String, dynamic>> addFeedSchedule({
    required String pondId,
    required String time,
    required String title,
  }) async {
    final response = await _sendAuthenticated(
      (headers) => http
          .post(
            Uri.parse('$baseUrl/ponds/$pondId/feed-schedules'),
            headers: headers,
            body: jsonEncode({'time': time, 'title': title}),
          )
          .timeout(_timeout),
    );

    return _processResponse(response);
  }

  Future<Map<String, dynamic>> updatePond(
    String pondId,
    Map<String, dynamic> pondData,
  ) async {
    // First try the current payload as-is
    var response = await _sendAuthenticated(
      (headers) => http
          .patch(
            Uri.parse('$baseUrl/ponds/$pondId'),
            headers: headers,
            body: jsonEncode(pondData),
          )
          .timeout(_timeout),
    );

    // If 400 (validation error), try mapping to legacy field names
    if (response.statusCode == 400) {
      final legacyPayload = <String, dynamic>{
        if (pondData.containsKey('name')) 'name': pondData['name'],
        if (pondData.containsKey('species')) 'species': pondData['species'],
        if (pondData.containsKey('fishCount'))
          'estimatedCount': pondData['fishCount'],
        if (pondData.containsKey('estimatedCount'))
          'estimatedCount': pondData['estimatedCount'],
        if (pondData.containsKey('status')) 'status': pondData['status'],
      };
      response = await _sendAuthenticated(
        (headers) => http
            .patch(
              Uri.parse('$baseUrl/ponds/$pondId'),
              headers: headers,
              body: jsonEncode(legacyPayload),
            )
            .timeout(_timeout),
      );
    }

    return _processResponse(response);
  }

  // --------------------------------------------------
  // Helper methods
  // --------------------------------------------------
  Map<String, String> _authHeaders() {
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  /// Runs an authenticated request and recovers from stale sessions.
  ///
  /// If the first attempt answers 401 (token missing in memory, expired, or
  /// minted by an older deployment with a different JWT_SECRET), the
  /// persisted token is reloaded once and the request retried. When the
  /// retry still fails, the dead token is cleared so the app returns to the
  /// login flow instead of looping on "Unauthorized".
  Future<http.Response> _sendAuthenticated(
    Future<http.Response> Function(Map<String, String> headers) action,
  ) async {
    final response = await action(_authHeaders());
    if (response.statusCode != 401) return response;

    await loadToken();
    final retried = await action(_authHeaders());
    if (retried.statusCode == 401) {
      await clearToken();
    }
    return retried;
  }

  /// Convert an http.Response into a standardized map.
  ///
  /// The backend wraps every successful response in `{ success: true, data: ... }`.
  /// This unwraps the envelope so callers receive the actual payload in `result['data']`,
  /// otherwise the previously double-wrapped response made login / OTP verification
  /// always fail with "invalid response format".
  Map<String, dynamic> _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      return {'success': false, 'message': 'Invalid server response'};
    }

    // Some legacy endpoints return a JSON array directly.  Treat it as a
    // valid successful payload rather than showing a misleading error.
    if (decoded is List) {
      return response.statusCode >= 200 && response.statusCode < 300
          ? {'success': true, 'data': decoded}
          : {'success': false, 'message': 'Request failed'};
    }

    if (decoded is! Map<String, dynamic>) {
      return {'success': false, 'message': 'Invalid server response'};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded.containsKey('data') && decoded['data'] != null) {
        return {'success': true, 'data': decoded['data']};
      }
      return {'success': true, 'data': decoded};
    }

    // Error responses from NestJS: { statusCode, message, error }
    String message = 'Request failed';
    if (decoded.containsKey('message')) {
      final msg = decoded['message'];
      if (msg is String) {
        message = msg;
      } else if (msg is List && msg.isNotEmpty) {
        message = msg.join(', ');
      }
    } else if (decoded.containsKey('error')) {
      message = decoded['error'] as String;
    }

    // Turn the raw passport "Unauthorized" into something actionable for
    // the user instead of showing the cryptic HTTP phrase.
    if (response.statusCode == 401 &&
        (message == 'Unauthorized' || message.isEmpty)) {
      message = 'Your session has expired. Please sign in again.';
    }

    return {
      'success': false,
      'statusCode': response.statusCode,
      'message': message,
    };
  }
}
