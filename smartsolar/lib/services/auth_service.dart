import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsolar/models/user_model.dart';
import 'package:smartsolar/utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  Future<bool> needsSetup() async {
    final response = await http
        .get(
          Uri.parse('${Constants.baseUrl}${Constants.endpointSetupStatus}'),
          headers: Constants.headers,
        )
        .timeout(Constants.timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data is Map<String, dynamic> && data['needsSetup'] == true;
    }

    throw Exception(
      _readError(response.body, fallback: 'Failed to check setup status'),
    );
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      final base = Constants.baseUrl;
      if (base.trim().isEmpty) {
        throw Exception('API base URL is not configured. Please set server URL in settings.');
      }
      final response = await http
          .post(
            Uri.parse('$base${Constants.endpointLogin}'),
            headers: Constants.headers,
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(Constants.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = UserModel.fromJson(_readUser(data), token: data['token']);
        await _saveSession(user);
        return user;
      } else {
        throw Exception(_readError(response.body, fallback: 'Login failed'));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> signup(
    String name,
    String email,
    String productId,
    String password,
  ) async {
    try {
      final base = Constants.baseUrl;
      if (base.trim().isEmpty) {
        throw Exception('API base URL is not configured. Please set server URL in settings.');
      }
      final response = await http
          .post(
            Uri.parse('$base${Constants.endpointSignup}'),
            headers: Constants.headers,
            body: json.encode({
              'username': name,
              'email': email,
              'product_id': productId,
              'password': password,
            }),
          )
          .timeout(Constants.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        throw Exception(_readError(response.body, fallback: 'Signup failed'));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> loginWithGoogle(String idToken) async {
    try {
      final base = Constants.baseUrl;
      if (base.trim().isEmpty) {
        throw Exception('API base URL is not configured. Please set server URL in settings.');
      }
      final response = await http
          .post(
            Uri.parse('$base/api/auth/google-login'),
            headers: Constants.headers,
            body: json.encode({'idToken': idToken}),
          )
          .timeout(Constants.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = UserModel.fromJson(_readUser(data), token: data['token']);
        await _saveSession(user);
        return user;
      } else {
        throw Exception(
          _readError(response.body, fallback: 'Google login failed'),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> setup({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('${Constants.baseUrl}${Constants.endpointSetup}'),
          headers: Constants.headers,
          body: json.encode({
            'username': username,
            'email': email,
            'password': password,
          }),
        )
        .timeout(Constants.timeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      final user = UserModel.fromJson(_readUser(data), token: data['token']);
      await _saveSession(user);
      return user;
    }

    throw Exception(_readError(response.body, fallback: 'Setup failed'));
  }

  Map<String, dynamic> _readUser(Map<String, dynamic> data) {
    final user = data['user'] ?? data['employee'];
    if (user is Map<String, dynamic>) return user;
    throw Exception('Invalid auth response');
  }

  String _readError(String body, {required String fallback}) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Keep the UI message useful even if the server sends a non-JSON error.
    }
    return fallback;
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token ?? '');
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<UserModel?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return UserModel.fromJson(json.decode(userStr));
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<Map<String, dynamic>?> forgotPassword({String? email, String? phone}) async {
    final response = await http
        .post(
          Uri.parse('${Constants.baseUrl}${Constants.endpointForgotPassword}'),
          headers: Constants.headers,
          body: json.encode({'email': email, 'phone': phone}),
        )
        .timeout(Constants.timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'user_id': data['user_id'],
        'code': data['code']?.toString(),
      };
    }
    throw Exception(_readError(response.body, fallback: 'Request failed'));
  }

  Future<bool> resetPassword({
    required int userId,
    required String code,
    required String newPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('${Constants.baseUrl}${Constants.endpointResetPassword}'),
          headers: Constants.headers,
          body: json.encode({
            'user_id': userId,
            'code': code,
            'new_password': newPassword,
          }),
        )
        .timeout(Constants.timeout);

    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_readError(response.body, fallback: 'Reset failed'));
  }
}
