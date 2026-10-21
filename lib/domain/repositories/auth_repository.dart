import '../models/auth_session_entity.dart';
import '../models/user_entity.dart';

abstract class AuthRepository {
  Future<AuthSessionEntity> login({
    required String emailOrPhone,
    required String password,
  });

  Future<AuthSessionEntity> register({
    required String nombre,
    required String coloniaComunidad,
    required String telefono,
    required String email,
    required String password,
  });

  Future<String?> getPersistedToken();
  Future<void> persistToken(String token);
  Future<void> clearPersistedSession();
  Future<UserEntity?> getCurrentUser();
}
