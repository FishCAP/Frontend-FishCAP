import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  UserProvider() {
    initializeUser();
  }

  Future<void> initializeUser() async {
    await _apiService.loadToken();
    if (_apiService.token != null) {
      await fetchUserProfile();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password);

      if (result['success'] == true) {
        final data = result['data'];

        // Case A: API returned wrapped payload with `user`
        if (data is Map && data.containsKey('user')) {
          _user = User.fromJson(Map<String, dynamic>.from(data['user']));
          _error = null;
          return true;
        }

        // Case B: API returned token + user fields at top-level
        if (data is Map && (data.containsKey('id') || data.containsKey('email'))) {
          _user = User.fromJson(Map<String, dynamic>.from(data));
          _error = null;
          return true;
        }

        // Case C: API returned token only — try to fetch profile
        if (data is Map && data.containsKey('token')) {
          await fetchUserProfile();
          if (_user != null) return true;
        }

        _error = 'Login failed: invalid response format';
        return false;
      }

      _error = result['message'] ?? 'Login failed';
      return false;
    } catch (e) {
      _error = 'Network error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.getUserProfile();

      if (result['success'] == true && result['data'] != null) {
        _user = User.fromJson(Map<String, dynamic>.from(result['data']));
        _error = null;
      } else {
        _error = result['message'] ?? 'Failed to load profile';
      }
    } catch (e) {
      _error = 'Failed to fetch profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> requestOtp(String email) async {
    try {
      final result = await _apiService.requestOtp(email);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// OTP verification.
  /// [fullName], [password] and [phone] are used when the user does
  /// not exist yet (registration).
  Future<bool> verifyOtp(
    String email,
    String code, {
    String? fullName,
    String? password,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _apiService.verifyOtp(
        email,
        code,
        fullName: fullName,
        password: password,
        phone: phone,
      );

      if (result['success'] == true) {
        final data = result['data'];

        // If response contains a `user` object (possibly with token)
        if (data is Map && data.containsKey('user')) {
          _user = User.fromJson(Map<String, dynamic>.from(data['user']));
          _error = null;
          return true;
        }

        // If response contains user fields directly
        if (data is Map && data.containsKey('id') && data.containsKey('email')) {
          _user = User.fromJson(Map<String, dynamic>.from(data));
          _error = null;
          return true;
        }

        // If response only contains token, fetch profile
        if (data is Map && data.containsKey('token')) {
          await fetchUserProfile();
          if (_user != null) return true;
        }

        _error = 'OTP verification failed: invalid response format';
        return false;
      }

      _error = result['message'] ?? 'OTP verification failed';
      return false;
    } catch (e) {
      _error = 'Network error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset a forgotten password using a code issued by [requestOtp].
  ///
  /// Returns true only when the backend confirmed the change; otherwise the
  /// reason is exposed through [error].
  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _apiService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      if (result['success'] == true) {
        _error = null;
        return true;
      }

      _error = result['message'] ?? 'Failed to reset password';
      return false;
    } catch (e) {
      _error = 'Network error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user's full name and phone number.
  Future<void> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.updateProfile(
        fullName: fullName,
        phone: phone,
      );

      if (result['success'] == true && result['data'] != null) {
        _user = User.fromJson(Map<String, dynamic>.from(result['data']));
        _error = null;
      } else {
        _error = result['message'] ?? 'Failed to update profile';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload a new profile image.
  ///
  /// [image] is the platform-agnostic [XFile] returned by image_picker, and
  /// [bytes] are its raw contents. We pass bytes to the API service so it can
  /// use [MultipartFile.fromBytes] which works on web, iOS, Android and
  /// desktop — unlike `fromPath` which requires `dart:io`.
  Future<void> uploadProfileImage(XFile image, Uint8List bytes) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.uploadProfileImageBytes(
        bytes,
        filename: image.name,
      );

      if (result['success'] == true && result['data'] != null) {
        _user = User.fromJson(Map<String, dynamic>.from(result['data']));
        _error = null;
      } else {
        _error = result['message'] ?? 'Failed to upload image';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout – clears local user and token.
  /// Does NOT delete the user data on the server.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Call backend to invalidate session/token if needed
      await _apiService.logout();
    } catch (e) {
      // Even if API fails, continue with local cleanup
      _error = 'Logout request failed: $e';
    } finally {
      // Always clear local user and token
      _user = null;
      _error = null;
      await _apiService.clearToken(); // Ensure token is removed from storage
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
