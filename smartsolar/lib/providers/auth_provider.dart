import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartsolar/models/user_model.dart';
import 'package:smartsolar/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '843628220335-llij8l9sbiq8qjihh3dqbr0im7bfe7k9.apps.googleusercontent.com',
  );
  final bool checkSetup;

  UserModel? _user;
  bool _isLoading = true;
  bool _needsSetup = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get needsSetup => _needsSetup;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider({this.checkSetup = true}) {
    _init();
  }

  Future<void> _init() async {
    try {
      _user = await _authService.getSession();
      if (_user == null && checkSetup) {
        _needsSetup = await _authService.needsSetup();
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
      _needsSetup = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(
    String name,
    String email,
    String productId,
    String password,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signup(name, email, productId, password);
      _needsSetup = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setup({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.setup(
        username: username,
        email: email,
        password: password,
      );
      _needsSetup = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID Token from Google');
      }

      _user = await _authService.loginWithGoogle(idToken);
      _needsSetup = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> forgotPassword({String? email, String? phone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.forgotPassword(
        email: email,
        phone: phone,
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> resetPassword({
    required int userId,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.resetPassword(
        userId: userId,
        code: code,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    try {
      _needsSetup = await _authService.needsSetup();
    } catch (_) {
      _needsSetup = false;
    }
    notifyListeners();
  }
}
