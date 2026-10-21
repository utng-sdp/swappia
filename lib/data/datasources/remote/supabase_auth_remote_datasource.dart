import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// Implementación remota de autenticación utilizando Supabase Auth y la tabla 'profiles' en PostgreSQL.
class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final SupabaseClient? _customClient;

  SupabaseAuthRemoteDataSource({SupabaseClient? client})
      : _customClient = client;

  /// Retorna el cliente Supabase configurado o el cliente Singleton por defecto.
  SupabaseClient get _client {
    if (_customClient != null) {
      return _customClient!;
    }
    return SupabaseService.instance.client;
  }

  @override
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (user == null || session == null) {
        throw Exception(
          'No se pudo iniciar sesión. Verifique sus credenciales.',
        );
      }

      // Consultar el perfil del vecino persistido en la tabla profiles de PostgreSQL
      final profile = await _fetchProfileData(user.id, fallbackEmail: email);

      return {
        'token': session.accessToken,
        'user': profile,
      };
    } on AuthException catch (e) {
      throw Exception(_translateAuthError(e.message));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error inesperado al iniciar sesión: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String nombre,
    required String coloniaComunidad,
    required String telefono,
  }) async {
    try {
      final cleanEmail = email.trim();
      final cleanNombre = nombre.trim();
      final cleanColonia = coloniaComunidad.trim();
      final cleanTelefono = telefono.trim();

      final response = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'nombre': cleanNombre,
          'colonia_comunidad': cleanColonia,
          'telefono': cleanTelefono,
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Error al registrar usuario en Supabase Auth.');
      }

      final profileMap = {
        'id': user.id,
        'nombre': cleanNombre,
        'colonia_comunidad': cleanColonia,
        'telefono': cleanTelefono,
        'calificacion_acumulada': 0.0,
        'total_calificaciones': 0,
        'foto_url': null,
        'fecha_registro': DateTime.now().toIso8601String(),
      };

      // Persistir o actualizar los datos adicionales del vecino en la tabla profiles
      try {
        await _client.from('profiles').upsert(profileMap);
      } catch (_) {
        // Si el trigger de PostgreSQL handle_new_user ya insertó la fila, continuamos
      }

      final token = response.session?.accessToken ??
          'jwt_supabase_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

      return {
        'token': token,
        'user': profileMap,
      };
    } on AuthException catch (e) {
      throw Exception(_translateAuthError(e.message));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error inesperado al registrar usuario: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) {
    return signInWithEmail(
      email: emailOrPhone,
      password: password,
    );
  }

  @override
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String coloniaComunidad,
    required String telefono,
    required String email,
    required String password,
  }) {
    return signUpWithEmail(
      email: email,
      password: password,
      nombre: nombre,
      coloniaComunidad: coloniaComunidad,
      telefono: telefono,
    );
  }

  @override
  Future<UserModel?> fetchCurrentUser(String token) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final profileData = await _fetchProfileData(currentUserId);
      return UserModel.fromJson(profileData);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Obtiene los datos de perfil desde la tabla 'profiles' o metadatos de respaldo.
  Future<Map<String, dynamic>> _fetchProfileData(
    String userId, {
    String? fallbackEmail,
  }) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null && data.isNotEmpty) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {
      // Si la consulta falla por temas de red o RLS, usar fallback
    }

    final metadata = _client.auth.currentUser?.userMetadata ?? {};
    return {
      'id': userId,
      'nombre': metadata['nombre'] ?? 'Vecino Swappia',
      'colonia_comunidad': metadata['colonia_comunidad'] ?? 'Dolores Hidalgo',
      'telefono': metadata['telefono'] ?? '',
      'calificacion_acumulada': 0.0,
      'total_calificaciones': 0,
      'foto_url': metadata['foto_url'],
      'fecha_registro': DateTime.now().toIso8601String(),
    };
  }

  /// Traduce los errores comunes de Supabase Auth a mensajes en español orientados al usuario.
  String _translateAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials')) {
      return 'Credenciales incorrectas. Verifique su correo y contraseña.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('email already in use') ||
        lower.contains('already exists')) {
      return 'Ya existe una cuenta registrada con ese correo electrónico.';
    }
    if (lower.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Error de conexión. Verifique su acceso a internet.';
    }
    return message;
  }
}
