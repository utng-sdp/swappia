import '../../domain/models/auth_session_entity.dart';
import '../../domain/models/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<AuthSessionEntity> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      emailOrPhone: emailOrPhone,
      password: password,
    );

    final token = response['token'] as String;
    final userJson = response['user'] as Map<String, dynamic>;
    final userModel = UserModel.fromJson(userJson);

    await _localDataSource.saveToken(token);
    await _localDataSource.saveUserData(userJson);

    return AuthSessionEntity(
      token: token,
      user: userModel.toEntity(),
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
    final response = await _remoteDataSource.register(
      nombre: nombre,
      coloniaComunidad: coloniaComunidad,
      telefono: telefono,
      email: email,
      password: password,
    );

    final token = response['token'] as String;
    final userJson = response['user'] as Map<String, dynamic>;
    final userModel = UserModel.fromJson(userJson);

    await _localDataSource.saveToken(token);
    await _localDataSource.saveUserData(userJson);

    return AuthSessionEntity(
      token: token,
      user: userModel.toEntity(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<String?> getPersistedToken() => _localDataSource.getToken();

  @override
  Future<void> persistToken(String token) => _localDataSource.saveToken(token);

  @override
  Future<void> clearPersistedSession() => _localDataSource.clearAll();

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await _localDataSource.getToken();
    if (token == null || token.isEmpty) return null;

    final cachedJson = await _localDataSource.getUserData();
    if (cachedJson != null) {
      return UserModel.fromJson(cachedJson).toEntity();
    }

    final remoteUser = await _remoteDataSource.fetchCurrentUser(token);
    return remoteUser?.toEntity();
  }
}
