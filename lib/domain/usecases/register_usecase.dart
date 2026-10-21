import '../models/auth_session_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<AuthSessionEntity> execute({
    required String nombre,
    required String coloniaComunidad,
    required String telefono,
    required String email,
    required String password,
  }) async {
    final cleanNombre = nombre.trim();
    if (cleanNombre.isEmpty) {
      throw Exception('El nombre es requerido');
    }

    final cleanColonia = coloniaComunidad.trim();
    if (cleanColonia.isEmpty) {
      throw Exception('La colonia o comunidad es requerida');
    }

    final digitosTelefono = telefono.replaceAll(RegExp(r'\D'), '');
    if (digitosTelefono.length != 10) {
      throw Exception('El teléfono debe tener 10 dígitos numéricos');
    }

    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Ingrese un correo electrónico válido');
    }

    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres');
    }

    final session = await _repository.register(
      nombre: cleanNombre,
      coloniaComunidad: cleanColonia,
      telefono: digitosTelefono,
      email: cleanEmail,
      password: password,
    );

    await _repository.persistToken(session.token);
    return session;
  }
}
