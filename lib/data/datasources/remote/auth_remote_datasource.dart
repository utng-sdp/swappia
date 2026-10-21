import '../../models/user_model.dart';
export 'supabase_auth_remote_datasource.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  });

  Future<Map<String, dynamic>> register({
    required String nombre,
    required String coloniaComunidad,
    required String telefono,
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String nombre,
    required String coloniaComunidad,
    required String telefono,
  });

  Future<UserModel?> fetchCurrentUser(String token);

  Future<void> signOut();
}

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  final List<Map<String, dynamic>> _registeredUsers = [
    {
      'id': 'usr-001',
      'nombre': 'Don Pedro Gómez',
      'colonia_comunidad': 'La Lindavista',
      'telefono': '4181234567',
      'email': 'pedro@swappia.mx',
      'password': 'password123',
      'calificacion_acumulada': 4.8,
      'total_calificaciones': 12,
      'foto_url': 'https://storage.supabase.co/perfil-pedro.jpg',
      'fecha_registro': '2026-01-10T10:00:00.000Z',
    },
    {
      'id': 'usr-002',
      'nombre': 'Doña Lupita Artesana',
      'colonia_comunidad': 'Centro',
      'telefono': '4187654321',
      'email': 'lupita@swappia.mx',
      'password': 'password123',
      'calificacion_acumulada': 5.0,
      'total_calificaciones': 18,
      'foto_url': 'https://storage.supabase.co/perfil-lupita.jpg',
      'fecha_registro': '2026-02-15T12:00:00.000Z',
    }
  ];

  @override
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final cleanId = emailOrPhone.trim();
    final user = _registeredUsers.firstWhere(
      (u) =>
          (u['email'] == cleanId || u['telefono'] == cleanId) &&
          u['password'] == password,
      orElse: () => throw Exception(
          'Credenciales incorrectas. Verifique su correo o teléfono y contraseña.'),
    );

    final token = 'jwt_swappia_${user['id']}_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'token': token,
      'user': Map<String, dynamic>.from(user),
    };
  }

  @override
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String coloniaComunidad,
    required String telefono,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final exists = _registeredUsers.any(
      (u) => u['email'] == email.trim() || u['telefono'] == telefono.trim(),
    );

    if (exists) {
      throw Exception('Ya existe una cuenta con ese correo o número telefónico.');
    }

    final id = 'usr-${DateTime.now().millisecondsSinceEpoch}';
    final newUser = {
      'id': id,
      'nombre': nombre.trim(),
      'colonia_comunidad': coloniaComunidad.trim(),
      'telefono': telefono.trim(),
      'email': email.trim(),
      'password': password,
      'calificacion_acumulada': 0.0,
      'total_calificaciones': 0,
      'foto_url': null,
      'fecha_registro': DateTime.now().toIso8601String(),
    };

    _registeredUsers.add(newUser);

    final token = 'jwt_swappia_${id}_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'token': token,
      'user': Map<String, dynamic>.from(newUser),
    };
  }

  @override
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) => login(emailOrPhone: email, password: password);

  @override
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String nombre,
    required String coloniaComunidad,
    required String telefono,
  }) => register(
    nombre: nombre,
    coloniaComunidad: coloniaComunidad,
    telefono: telefono,
    email: email,
    password: password,
  );

  @override
  Future<UserModel?> fetchCurrentUser(String token) async {
    await Future.delayed(const Duration(milliseconds: 50));
    for (final u in _registeredUsers) {
      if (token.contains(u['id'] as String)) {
        return UserModel.fromJson(u);
      }
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
