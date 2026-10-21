import 'package:flutter/foundation.dart';
import '../../domain/models/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/get_session_usecase.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthViewModel extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetSessionUseCase _getSessionUseCase;

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _currentUser;
  String? _token;
  String? _errorMessage;

  AuthViewModel({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GetSessionUseCase getSessionUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _getSessionUseCase = getSessionUseCase;

  AuthStatus get status => _status;
  UserEntity? get currentUser => _currentUser;
  String? get token => _token;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get hasError => _status == AuthStatus.error;

  /// Verifica la presencia de un token de sesión persistido al iniciar la app
  Future<void> checkSession() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedToken = await _getSessionUseCase.getToken();
      if (savedToken != null && savedToken.trim().isNotEmpty) {
        final user = await _getSessionUseCase.getCurrentUser();
        _token = savedToken;
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
      } else {
        _token = null;
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _token = null;
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = _cleanExceptionMessage(e);
    }
    notifyListeners();
  }

  /// Autentica al usuario mediante correo o teléfono y contraseña
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _loginUseCase.execute(
        emailOrPhone: emailOrPhone,
        password: password,
      );

      _token = session.token;
      _currentUser = session.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _cleanExceptionMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Registra un nuevo vecino en la comunidad y activa la sesión
  Future<bool> register({
    required String nombre,
    required String coloniaComunidad,
    required String telefono,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _registerUseCase.execute(
        nombre: nombre,
        coloniaComunidad: coloniaComunidad,
        telefono: telefono,
        email: email,
        password: password,
      );

      _token = session.token;
      _currentUser = session.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _cleanExceptionMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión activa y elimina el token persistente
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _getSessionUseCase.logout();
    } finally {
      _token = null;
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      if (_status == AuthStatus.error) {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    }
  }

  String _cleanExceptionMessage(dynamic error) {
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str;
  }
}
