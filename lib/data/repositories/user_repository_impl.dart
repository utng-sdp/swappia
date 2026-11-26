import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../domain/models/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';

/// Implementación de UserRepository con persistencia en Supabase (tabla 'profiles')
/// y respaldo en memoria para pruebas o modo sin conexión.
class UserRepositoryImpl implements UserRepository {
  final SupabaseClient? _customClient;
  final List<UserModel> _inMemoryUsers = [
    UserModel(
      id: 'usr-001',
      nombre: 'Don Pedro Gómez',
      coloniaComunidad: 'La Lindavista',
      telefono: '4181234567',
      calificacionAcumulada: 4.8,
      totalCalificaciones: 12,
      fechaRegistro: DateTime(2026, 1, 10),
    ),
    UserModel(
      id: 'usr-002',
      nombre: 'Doña Lupita Artesana',
      coloniaComunidad: 'Centro',
      telefono: '4187654321',
      calificacionAcumulada: 5.0,
      totalCalificaciones: 18,
      fechaRegistro: DateTime(2026, 2, 15),
    ),
  ];

  UserRepositoryImpl({SupabaseClient? client}) : _customClient = client;

  SupabaseClient get _client {
    if (_customClient != null) {
      return _customClient!;
    }
    return SupabaseService.instance.client;
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response).toEntity();
      }
    } catch (_) {
      try {
        final response = await _client
            .from('perfiles')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (response != null) {
          return UserModel.fromJson(response).toEntity();
        }
      } catch (_) {}
    }

    try {
      return _inMemoryUsers.firstWhere((u) => u.id == id).toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      if (_inMemoryUsers.isNotEmpty) return _inMemoryUsers.first.toEntity();
      return null;
    }
    return getUserById(authUser.id);
  }

  @override
  Future<void> createUser(UserEntity user) async {
    final model = UserModel.fromEntity(user);
    try {
      await _client.from('profiles').insert(model.toJson());
    } catch (_) {
      try {
        await _client.from('perfiles').insert(model.toJson());
      } catch (_) {}
    }
    _inMemoryUsers.removeWhere((u) => u.id == user.id);
    _inMemoryUsers.add(model);
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    final model = UserModel.fromEntity(user);
    try {
      await _client
          .from('profiles')
          .update(model.toJson())
          .eq('id', user.id);
    } catch (_) {
      try {
        await _client
            .from('perfiles')
            .update(model.toJson())
            .eq('id', user.id);
      } catch (_) {}
    }
    final index = _inMemoryUsers.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _inMemoryUsers[index] = model;
    } else {
      _inMemoryUsers.add(model);
    }
  }

  @override
  Future<List<UserEntity>> getUsersByColonia(String coloniaComunidad) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('colonia_comunidad', coloniaComunidad);
      return (response as List)
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>).toEntity())
          .toList();
    } catch (_) {
      return _inMemoryUsers
          .where((u) => u.coloniaComunidad.toLowerCase() == coloniaComunidad.toLowerCase())
          .map((u) => u.toEntity())
          .toList();
    }
  }

  @override
  Future<void> updateRating({
    required String userId,
    required double nuevaCalificacionAcumulada,
    required int nuevoTotalCalificaciones,
  }) async {
    final updateData = {
      'calificacion_acumulada': nuevaCalificacionAcumulada,
      'total_calificaciones': nuevoTotalCalificaciones,
    };

    try {
      await _client.from('profiles').update(updateData).eq('id', userId);
    } catch (_) {
      try {
        await _client.from('perfiles').update(updateData).eq('id', userId);
      } catch (_) {}
    }

    final index = _inMemoryUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final u = _inMemoryUsers[index];
      _inMemoryUsers[index] = UserModel(
        id: u.id,
        nombre: u.nombre,
        coloniaComunidad: u.coloniaComunidad,
        telefono: u.telefono,
        calificacionAcumulada: nuevaCalificacionAcumulada,
        totalCalificaciones: nuevoTotalCalificaciones,
        fotoUrl: u.fotoUrl,
        fechaRegistro: u.fechaRegistro,
      );
    }
  }
}
