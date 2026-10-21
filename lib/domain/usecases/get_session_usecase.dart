import '../models/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetSessionUseCase {
  final AuthRepository _repository;

  GetSessionUseCase(this._repository);

  Future<String?> getToken() => _repository.getPersistedToken();
  Future<UserEntity?> getCurrentUser() => _repository.getCurrentUser();
  Future<void> logout() => _repository.clearPersistedSession();
}
