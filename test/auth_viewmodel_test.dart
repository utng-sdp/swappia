import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swappia_app/data/datasources/local/auth_local_datasource.dart';
import 'package:swappia_app/data/datasources/remote/auth_remote_datasource.dart';
import 'package:swappia_app/data/repositories/auth_repository_impl.dart';
import 'package:swappia_app/domain/models/auth_session_entity.dart';
import 'package:swappia_app/domain/models/user_entity.dart';
import 'package:swappia_app/domain/repositories/auth_repository.dart';
import 'package:swappia_app/domain/usecases/get_session_usecase.dart';
import 'package:swappia_app/domain/usecases/login_usecase.dart';
import 'package:swappia_app/domain/usecases/register_usecase.dart';
import 'package:swappia_app/presentation/viewmodels/auth_viewmodel.dart';

class MockAuthRepository implements AuthRepository {
  String? _persistedToken;
  UserEntity? _persistedUser;
  bool shouldFail = false;

  @override
  Future<AuthSessionEntity> login({
    required String emailOrPhone,
    required String password,
  }) async {
    if (shouldFail || password != 'password123') {
      throw Exception('Credenciales incorrectas');
    }
    const user = UserEntity(
      id: 'usr-001',
      nombre: 'Don Pedro Gómez',
      coloniaComunidad: 'La Lindavista',
      telefono: '4181234567',
      calificacionAcumulada: 4.8,
      totalCalificaciones: 12,
    );
    final token = 'jwt_token_test_${user.id}';
    _persistedToken = token;
    _persistedUser = user;
    return AuthSessionEntity(
      token: token,
      user: user,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<AuthSessionEntity> register({
    required String nombre,
    required String coloniaComunidad,
    required String telefono,
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw Exception('Error al registrar usuario');
    }
    final user = UserEntity(
      id: 'usr-new-999',
      nombre: nombre,
      coloniaComunidad: coloniaComunidad,
      telefono: telefono,
      calificacionAcumulada: 0.0,
      totalCalificaciones: 0,
    );
    final token = 'jwt_token_test_${user.id}';
    _persistedToken = token;
    _persistedUser = user;
    return AuthSessionEntity(
      token: token,
      user: user,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<String?> getPersistedToken() async => _persistedToken;

  @override
  Future<void> persistToken(String token) async {
    _persistedToken = token;
  }

  @override
  Future<void> clearPersistedSession() async {
    _persistedToken = null;
    _persistedUser = null;
  }

  @override
  Future<UserEntity?> getCurrentUser() async => _persistedUser;
}

void main() {
  group('AuthViewModel - Reactividad y Gestión de Sesión', () {
    late MockAuthRepository mockRepo;
    late LoginUseCase loginUseCase;
    late RegisterUseCase registerUseCase;
    late GetSessionUseCase getSessionUseCase;
    late AuthViewModel viewModel;

    setUp(() {
      mockRepo = MockAuthRepository();
      loginUseCase = LoginUseCase(mockRepo);
      registerUseCase = RegisterUseCase(mockRepo);
      getSessionUseCase = GetSessionUseCase(mockRepo);
      viewModel = AuthViewModel(
        loginUseCase: loginUseCase,
        registerUseCase: registerUseCase,
        getSessionUseCase: getSessionUseCase,
      );
    });

    test('Estado inicial es unauthenticated o initial', () {
      expect(viewModel.status, AuthStatus.initial);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.currentUser, isNull);
      expect(viewModel.token, isNull);
    });

    test('login exitoso actualiza el estado a authenticated y guarda el token', () async {
      final notificationStates = <AuthStatus>[];
      viewModel.addListener(() {
        notificationStates.add(viewModel.status);
      });

      final success = await viewModel.login(
        emailOrPhone: 'pedro@swappia.mx',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.currentUser, isNotNull);
      expect(viewModel.currentUser?.nombre, 'Don Pedro Gómez');
      expect(viewModel.token, contains('jwt_token_test_usr-001'));
      expect(viewModel.errorMessage, isNull);

      // Reactividad: Pasó por loading antes de authenticated
      expect(notificationStates, contains(AuthStatus.loading));
      expect(notificationStates.last, AuthStatus.authenticated);
    });

    test('login fallido actualiza el estado a error y expone mensaje legible', () async {
      final success = await viewModel.login(
        emailOrPhone: 'pedro@swappia.mx',
        password: 'wrong_password',
      );

      expect(success, isFalse);
      expect(viewModel.status, AuthStatus.error);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.errorMessage, contains('Credenciales incorrectas'));
      expect(viewModel.currentUser, isNull);
    });

    test('register exitoso autentica inmediatamente al nuevo vecino', () async {
      final success = await viewModel.register(
        nombre: 'María Dolores',
        coloniaComunidad: 'Centro',
        telefono: '4189998877',
        email: 'maria@swappia.mx',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.currentUser?.nombre, 'María Dolores');
      expect(viewModel.currentUser?.coloniaComunidad, 'Centro');
      expect(viewModel.token, isNotNull);
    });

    test('logout limpia el token y devuelve el estado a unauthenticated', () async {
      // Iniciar sesión primero
      await viewModel.login(
        emailOrPhone: 'pedro@swappia.mx',
        password: 'password123',
      );
      expect(viewModel.isAuthenticated, isTrue);

      // Cerrar sesión
      await viewModel.logout();

      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.currentUser, isNull);
      expect(viewModel.token, isNull);
      expect(await mockRepo.getPersistedToken(), isNull);
    });

    test('checkSession restaura la sesión activa si hay un token persistido', () async {
      // Simular token guardado previamente en almacenamiento
      await mockRepo.persistToken('jwt_persisted_saved_token');
      await mockRepo.login(emailOrPhone: 'pedro@swappia.mx', password: 'password123');

      final freshViewModel = AuthViewModel(
        loginUseCase: loginUseCase,
        registerUseCase: registerUseCase,
        getSessionUseCase: getSessionUseCase,
      );

      await freshViewModel.checkSession();

      expect(freshViewModel.isAuthenticated, isTrue);
      expect(freshViewModel.status, AuthStatus.authenticated);
      expect(freshViewModel.currentUser?.nombre, 'Don Pedro Gómez');
    });
  });

  group('Persistencia del Token con SharedPreferences', () {
    test('SharedPreferencesAuthLocalDataSource almacena, recupera y elimina el token', () async {
      SharedPreferences.setMockInitialValues({});
      final localDataSource = SharedPreferencesAuthLocalDataSource();

      expect(await localDataSource.getToken(), isNull);

      await localDataSource.saveToken('jwt_swappia_secure_token_123');
      expect(await localDataSource.getToken(), 'jwt_swappia_secure_token_123');

      await localDataSource.saveUserData({
        'id': 'usr-100',
        'nombre': 'Juana',
      });
      final userData = await localDataSource.getUserData();
      expect(userData?['nombre'], 'Juana');

      await localDataSource.clearAll();
      expect(await localDataSource.getToken(), isNull);
      expect(await localDataSource.getUserData(), isNull);
    });

    test('AuthRepositoryImpl persiste token y datos de sesión activa en login y register', () async {
      SharedPreferences.setMockInitialValues({});
      final localDataSource = SharedPreferencesAuthLocalDataSource();
      final remoteDataSource = MockAuthRemoteDataSource();

      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      final session = await repository.login(
        emailOrPhone: 'pedro@swappia.mx',
        password: 'password123',
      );

      expect(session.isValid, isTrue);
      expect(session.user.nombre, 'Don Pedro Gómez');

      // Comprobar persistencia real del token
      final persistedToken = await repository.getPersistedToken();
      expect(persistedToken, isNotNull);
      expect(persistedToken, session.token);

      final currentUser = await repository.getCurrentUser();
      expect(currentUser?.nombre, 'Don Pedro Gómez');

      // Limpieza de sesión
      await repository.clearPersistedSession();
      expect(await repository.getPersistedToken(), isNull);
    });
  });
}
