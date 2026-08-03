import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  // For physical device, use your computer's IP address
  // static const String baseUrl = 'http://192.168.1.100:3000/api';
  
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String userEndpoint = '/users/me';
  static const String waterQualityEndpoint = '/water-quality';
  static const String scheduleEndpoint = '/schedules';
  static const String historyEndpoint = '/history';
  static const String notificationsEndpoint = '/notifications';

  String? _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        await saveToken(data['data']['token']);
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$registerEndpoint'),
        headers: _headers,
        body: jsonEncode(userData),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success'] == true) {
        await saveToken(data['data']['token']);
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$userEndpoint'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getWaterQuality() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$waterQualityEndpoint'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch data'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$scheduleEndpoint'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch schedule'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$historyEndpoint'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch history'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$notificationsEndpoint'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch notifications'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<void> logout() async {
    await clearToken();
  }
}