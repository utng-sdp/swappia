import '../models/auth_session_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<AuthSessionEntity> execute({
    required String emailOrPhone,
    required String password,
  }) async {
    final cleanIdentifier = emailOrPhone.trim();
    if (cleanIdentifier.isEmpty) {
      throw Exception('El correo o teléfono no puede estar vacío');
    }
    if (password.trim().isEmpty) {
      throw Exception('La contraseña no puede estar vacía');
    }
    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres');
    }

    final session = await _repository.login(
      emailOrPhone: cleanIdentifier,
      password: password,
    );

    await _repository.persistToken(session.token);
    return session;
  }
}
