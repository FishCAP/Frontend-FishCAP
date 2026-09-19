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

  String? _token;
  String? get token => _token;
  String? userId;
  int _sessionRevision = 0;

  /// The API host differs per platform:
  /// - Android emulator reaches the host machine via 10.0.2.2
  /// - iOS simulator / desktop / web can use localhost directly
  /// - Real devices need a LAN IP or a runtime override
  ///
  /// Uses `kIsWeb` + `defaultTargetPlatform` instead of `dart:io Platform`,
  /// which is not available on the web (would throw `Unsupported operation:
  /// _Namespace` at startup).
  static String resolveBackendBaseUrl({
    String? override,
    TargetPlatform? platform,
  }) {
    final runtimeOverride = override?.trim();
    if (runtimeOverride != null && runtimeOverride.isNotEmpty) {
      return runtimeOverride.replaceAll(RegExp(r'/+$'), '');
    }

    final resolvedPlatform = platform ?? defaultTargetPlatform;
    if (!kIsWeb && resolvedPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001';
    }
    return 'http://localhost:3001';
  }

  static String get baseUrl {
    return '${resolveBackendBaseUrl()}/api';
  }

  static const Duration _timeout = Duration(seconds: 15);

  // Token storage key
  static const String _tokenKey = 'auth_token';

  // --------------------------------------------------
  // Token management
  // --------------------------------------------------
  Future<void> loadToken() async {
    final revision = _sessionRevision;
    final prefs = await SharedPreferences.getInstance();
    // A pending startup read must not overwrite a newer login or logout.
    if (revision != _sessionRevision) return;
    final savedToken = prefs.getString(_tokenKey);
    _token = savedToken != null && savedToken.trim().isNotEmpty
        ? savedToken
        : null;
  }

  Future<void> saveToken(String newToken) async {
    if (newToken.trim().isEmpty) {
      throw ArgumentError('A nonempty backend token is required');
    }
    final revision = ++_sessionRevision;
    _token = newToken;
    final prefs = await SharedPreferences.getInstance();
    if (revision != _sessionRevision) return;
    await prefs.setString(_tokenKey, newToken);
  }

  Future<void> clearToken() async {
    final revision = ++_sessionRevision;
    _token = null;
    userId = null;
    final prefs = await SharedPreferences.getInstance();
    if (revision != _sessionRevision) return;
    await prefs.remove(_tokenKey);
  }

  /// Login and OTP return { success: true, data: { id, email, token, ... } }.
  /// Preserve the backend token verbatim; never derive it from a resource ID.
  Future<Map<String, dynamic>> _storeSession(
    Map<String, dynamic> result,
  ) async {
    if (result['success'] != true) return result;
    final data = result['data'];
    if (data is! Map ||
        data['token'] is! String ||
        (data['token'] as String).trim().isEmpty ||
        data['id'] is! String ||
        (data['id'] as String).isEmpty) {
      await clearToken();
      return {
        'success': false,
        'message': 'Invalid sign-in response. Please sign in again.',
      };
    }
    await saveToken(data['token'] as String);
    userId = data['id'] as String;
    return result;
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

    return _storeSession(_processResponse(response));
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

    return _storeSession(_processResponse(response));
  }

  /// Reset the password of an existing account ("Forgot Password?" on login).
  ///
  /// Ownership is proven with the 6-digit code issued by [requestOtp] instead
  /// of the current password. The backend consumes the code and writes the new
  /// password, so no session is created here — the user signs in normally
  /// afterwards.
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/reset-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'code': code,
            'password': newPassword,
          }),
        )
        .timeout(_timeout);

    return _processResponse(response);
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

  /// Persist an alert on the backend so it appears on the Notifications
  /// page for the signed-in user (the endpoint binds the row to the JWT
  /// user — the client only supplies title/message/isRead).
  Future<Map<String, dynamic>> createNotification({
    required String title,
    String? message,
  }) async {
    final response = await _sendAuthenticated(
      (headers) => http
          .post(
            Uri.parse('$baseUrl/notifications'),
            headers: headers,
            body: jsonEncode({
              'title': title,
              'message': message,
              'isRead': false,
            }),
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
    // The backend does not expose a dedicated profile-image upload endpoint
    // (POST /users/me/profile-image) which caused 404 errors in the browser.
    // As a safe fallback we PATCH /users/me with a base64 payload so the
    // request succeeds without hitting the missing endpoint. The server may
    // ignore unknown fields, but this prevents noisy 404s in the browser.
    final base64 = base64Encode(bytes);
    final body = {'profileImageBase64': base64, 'filename': filename};

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

  /// Fetch feeding logs and optionally filter by pondId.
  Future<Map<String, dynamic>> getFeedingLogs({String? pondId}) async {
    final uri = Uri.parse(
      '$baseUrl/feeding/logs/grouped${pondId != null ? '?pondId=${Uri.encodeComponent(pondId)}' : ''}',
    );
    final response = await _sendAuthenticated(
      (headers) => http.get(uri, headers: headers).timeout(_timeout),
    );
    return _processResponse(response);
  }

  /// Search fish species by query (supports Khmer and English)
  Future<Map<String, dynamic>> searchSpecies(String q) async {
    final uri = Uri.parse(
      '$baseUrl/feeding/species/search?q=${Uri.encodeComponent(q)}',
    );
    final response = await http.get(uri).timeout(_timeout);
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> updatePond(
    String pondId,
    Map<String, dynamic> pondData,
  ) async {
    // Preserve the complete update and surface validation errors unchanged.
    final response = await _sendAuthenticated(
      (headers) => http
          .patch(
            Uri.parse('$baseUrl/ponds/$pondId'),
            headers: headers,
            body: jsonEncode(pondData),
          )
          .timeout(_timeout),
    );

    return _processResponse(response);
  }

  // --------------------------------------------------
  // Device & Hardware Reassignment
  // --------------------------------------------------

  /// List all devices
  Future<Map<String, dynamic>> getDevices() async {
    final response = await _sendAuthenticated(
      (headers) => http
          .get(Uri.parse('$baseUrl/devices'), headers: headers)
          .timeout(_timeout),
    );
    return _processResponse(response);
  }

  /// List only available devices (for pond creation)
  Future<Map<String, dynamic>> getAvailableDevices() async {
    final response = await _sendAuthenticated(
      (headers) => http
          .get(Uri.parse('$baseUrl/devices/available'), headers: headers)
          .timeout(_timeout),
    );
    return _processResponse(response);
  }

  /// Register a brand-new hardware device so it can be assigned to a pond.
  ///
  /// This backs the "create" path of the hardware-ID button: it generates a
  /// device record (with its own `deviceCode` / hardware id) on the backend
  /// without tying it to a pond yet. The returned record carries the new
  /// `id` (UUID) and `deviceCode`, which the UI can select instantly.
  Future<Map<String, dynamic>> createDevice({
    required String deviceCode,
    String? deviceName,
    String? pondId,
    String? status,
  }) async {
    final body = <String, dynamic>{'deviceCode': deviceCode};
    if (deviceName != null) body['deviceName'] = deviceName;
    if (pondId != null) body['pondId'] = pondId;
    if (status != null) body['status'] = status;

    final response = await _sendAuthenticated(
      (headers) => http
          .post(
            Uri.parse('$baseUrl/sensors/devices'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout),
    );

    return _processResponse(response);
  }

  /// Assign a device to a pond
  Future<Map<String, dynamic>> assignDevice(
    String deviceId,
    String pondId,
  ) async {
    final response = await _sendAuthenticated(
      (headers) => http
          .post(
            Uri.parse('$baseUrl/devices/$deviceId/assign'),
            headers: headers,
            body: jsonEncode({'pond_id': pondId}),
          )
          .timeout(_timeout),
    );
    return _processResponse(response);
  }

  /// Mark a pond as completed/done (releases hardware)
  Future<Map<String, dynamic>> completePond(String pondId) async {
    final response = await _sendAuthenticated(
      (headers) => http
          .patch(Uri.parse('$baseUrl/ponds/$pondId/complete'), headers: headers)
          .timeout(_timeout),
    );
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

  /// Load the saved session before sending. A 401 invalidates only the session
  /// used by that request, never a newer login. Replaying the same expired
  /// token cannot refresh it; require a fresh backend login instead.
  Future<http.Response> _sendAuthenticated(
    Future<http.Response> Function(Map<String, String> headers) action,
  ) async {
    if (token == null) await loadToken();
    if (token == null) {
      return http.Response('{"message":"Unauthorized"}', 401);
    }
    final revision = _sessionRevision;
    final response = await action(_authHeaders());
    if (response.statusCode == 401 && revision == _sessionRevision) {
      await clearToken();
    }
    return response;
  }

  // Reset Password

  Future<bool> requestPasswordReset(String email) async {
    final result = await requestOtp(email.trim());
    return result['success'] == true;
  }



  /// Convert an http.Response into a standardized map.
  ///
  /// The backend wraps every successful response in `{ success: true, data: ... }`.
  /// This unwraps the envelope so callers receive the actual payload in `result['data']`,
  /// otherwise the previously double-wrapped response made login / OTP verification
  /// always fail with "invalid response format".
  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode == 204) {
      return {'success': true, 'data': null};
    }
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
