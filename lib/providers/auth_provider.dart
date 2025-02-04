import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/api/auth_api.dart';
import 'package:who_location_app/models/user.dart';
import 'package:who_location_app/utils/token_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:who_location_app/services/navigation_service.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/services/websocket_service.dart';

class AuthProvider extends ChangeNotifier {
  late final AuthApi _authApi;
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _needsReauth = false;

  AuthProvider() {
    _authApi = AuthApi(() => logout());
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get needsReauth => _needsReauth;

  set needsReauth(bool value) {
    if (_needsReauth != value) {
      _needsReauth = value;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    _needsReauth = false;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Starting login process');
      final user = await _authApi.login(username, password);
      _user = user;
      _needsReauth = false;
      await TokenStorage.saveToken(user.token);
      debugPrint('AuthProvider: Token saved: ${user.token}');
      _isLoading = false;
      notifyListeners();

      // Restart task synchronization only after a successful login.
      final context = navigatorKey.currentContext;
      if (context != null) {
        Provider.of<TaskProvider>(context, listen: false).startPeriodicSync();
      }

      return true;
    } catch (e) {
      debugPrint('AuthProvider: Login failed - $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Starting register process');
      final user = await _authApi.register(username, password, role);
      _user = user;
      // Save token from response
      await TokenStorage.saveToken(user.token);
      debugPrint('AuthProvider: Register successful');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Register failed - $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Disconnect WebSocket if connected during logout.
    WebSocketService.current?.disconnect();

    // Ensure TaskProvider is reset during logout.
    final context = navigatorKey.currentContext;
    if (context != null) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.reset();
    }

    await TokenStorage.deleteToken();
    _user = null;
    notifyListeners();
  }

  Future<void> handleUnauthorized() async {
    // If session expiration is already marked, do nothing.
    if (_needsReauth) return;

    debugPrint('Handling unauthorized access');

    // Stop any active synchronization (e.g., cancel timers).
    final context = navigatorKey.currentContext;
    if (context != null) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.reset();
    }

    // Perform logout, delete token, and reset user state.
    await logout();

    // Mark session as expired to prevent repeated processes.
    _needsReauth = true;
    notifyListeners();

    // Schedule navigation to login screen after current frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentContext = navigatorKey.currentContext;
      if (currentContext != null) {
        GoRouter.of(currentContext).go('/login');
      }
    });
  }

  Future<String?> getToken() async {
    return await TokenStorage.getToken();
  }

  Future<bool> registerUser(String username, String password, String role) async {
    try {
      debugPrint('AuthProvider: Registering user without login');
      final user = await _authApi.register(username, password, role);
      debugPrint('AuthProvider: User registered successfully');
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Register failed - $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

