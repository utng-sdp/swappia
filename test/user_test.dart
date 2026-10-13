import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/domain/models/user_entity.dart';
import 'package:swappia_app/domain/repositories/user_repository.dart';
import 'package:swappia_app/data/models/user_model.dart';

class MockUserRepository implements UserRepository {
  final Map<String, UserEntity> _db = {};
  UserEntity? _currentUser;

  @override
  Future<UserEntity?> getUserById(String id) async => _db[id];

  @override
  Future<UserEntity?> getCurrentUser() async => _currentUser;

  @override
  Future<void> createUser(UserEntity user) async {
    _db[user.id] = user;
    _currentUser = user;
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    _db[user.id] = user;
    if (_currentUser?.id == user.id) {
      _currentUser = user;
    }
  }

  @override
  Future<List<UserEntity>> getUsersByColonia(String coloniaComunidad) async {
    return _db.values
        .where((u) => u.coloniaComunidad.toLowerCase() == coloniaComunidad.toLowerCase())
        .toList();
  }

  @override
  Future<void> updateRating({
    required String userId,
    required double nuevaCalificacionAcumulada,
    required int nuevoTotalCalificaciones,
  }) async {
    final user = _db[userId];
    if (user != null) {
      _db[userId] = user.copyWith(
        calificacionAcumulada: nuevaCalificacionAcumulada,
        totalCalificaciones: nuevoTotalCalificaciones,
      );
    }
  }
}

void main() {
  group('UserEntity - Reglas de Negocio en Dominio', () {
    test('Crea una entidad válida con datos de vecino de Dolores Hidalgo', () {
      const user = UserEntity(
        id: 'usr-001',
        nombre: 'Don Pedro Gómez',
        coloniaComunidad: 'La Lindavista',
        telefono: '4181234567',
        calificacionAcumulada: 4.8,
        totalCalificaciones: 12,
      );

      expect(user.id, 'usr-001');
      expect(user.nombre, 'Don Pedro Gómez');
      expect(user.coloniaComunidad, 'La Lindavista');
      expect(user.telefono, '4181234567');
      expect(user.calificacionAcumulada, 4.8);
      expect(user.totalCalificaciones, 12);
      expect(user.tieneNombreValido, isTrue);
      expect(user.tieneTelefonoValido, isTrue);
      expect(user.tienePerfilCompleto, isTrue);
      expect(user.esVecinoConfiable, isTrue);
      expect(user.reputacionLegible, '4.8 ★ (12)');
    });

    test('Valida correctamente perfiles incompletos o teléfonos inválidos', () {
      const userInvalido = UserEntity(
        id: 'usr-002',
        nombre: '',
        coloniaComunidad: 'Centro',
        telefono: '123',
      );

      expect(userInvalido.tieneNombreValido, isFalse);
      expect(userInvalido.tieneTelefonoValido, isFalse);
      expect(userInvalido.tienePerfilCompleto, isFalse);
      expect(userInvalido.tieneCalificaciones, isFalse);
      expect(userInvalido.reputacionLegible, 'Nuevo en la comunidad');
      expect(userInvalido.esVecinoConfiable, isFalse);
    });

    test('Soporta inmutabilidad y copyWith', () {
      const original = UserEntity(
        id: 'usr-003',
        nombre: 'María Ramos',
        coloniaComunidad: 'Rinconada',
        telefono: '4189876543',
      );

      final modificado = original.copyWith(
        coloniaComunidad: 'El Calvario',
        calificacionAcumulada: 5.0,
        totalCalificaciones: 1,
      );

      expect(modificado.id, original.id);
      expect(modificado.nombre, original.nombre);
      expect(modificado.coloniaComunidad, 'El Calvario');
      expect(modificado.calificacionAcumulada, 5.0);
      expect(original.coloniaComunidad, 'Rinconada');
    });
  });

  group('Mappers UserModel <---> UserEntity', () {
    test('toEntity transforma correctamente UserModel a UserEntity', () {
      const model = UserModel(
        id: 'model-10',
        nombre: 'Juan Talavera',
        coloniaComunidad: 'Comunidad Río Laja',
        telefono: '4185551234',
        calificacionAcumulada: 4.5,
        totalCalificaciones: 6,
      );

      final entity = model.toEntity();

      expect(entity, isA<UserEntity>());
      expect(entity.id, model.id);
      expect(entity.nombre, model.nombre);
      expect(entity.coloniaComunidad, model.coloniaComunidad);
      expect(entity.telefono, model.telefono);
      expect(entity.calificacionAcumulada, model.calificacionAcumulada);
      expect(entity.totalCalificaciones, model.totalCalificaciones);
    });

    test('fromEntity transforma correctamente UserEntity a UserModel', () {
      const entity = UserEntity(
        id: 'ent-20',
        nombre: 'Costurera Lupita',
        coloniaComunidad: 'San Antonio',
        telefono: '4187654321',
        calificacionAcumulada: 4.9,
        totalCalificaciones: 20,
      );

      final model = UserModel.fromEntity(entity);

      expect(model, isA<UserModel>());
      expect(model.id, entity.id);
      expect(model.nombre, entity.nombre);
      expect(model.coloniaComunidad, entity.coloniaComunidad);
      expect(model.telefono, entity.telefono);
      expect(model.calificacionAcumulada, entity.calificacionAcumulada);
      expect(model.totalCalificaciones, entity.totalCalificaciones);
    });

    test('Serialización y deserialización JSON (compatible Supabase snake_case)', () {
      final json = {
        'id': 'supa-99',
        'nombre': 'Electricista Carlos',
        'colonia_comunidad': 'Colonia Lindavista',
        'telefono': '4181112233',
        'calificacion_acumulada': 4.7,
        'total_calificaciones': 8,
        'foto_url': 'https://storage.supabase.co/perfil.jpg',
        'fecha_registro': '2026-03-15T10:00:00.000Z',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'supa-99');
      expect(model.nombre, 'Electricista Carlos');
      expect(model.coloniaComunidad, 'Colonia Lindavista');
      expect(model.telefono, '4181112233');
      expect(model.calificacionAcumulada, 4.7);
      expect(model.totalCalificaciones, 8);
      expect(model.fotoUrl, 'https://storage.supabase.co/perfil.jpg');
      expect(model.fechaRegistro, isNotNull);

      final serializedJson = model.toJson();
      expect(serializedJson['colonia_comunidad'], 'Colonia Lindavista');
      expect(serializedJson['calificacion_acumulada'], 4.7);
      expect(serializedJson['total_calificaciones'], 8);

      final mappedEntity = model.toEntity();
      expect(mappedEntity.nombre, 'Electricista Carlos');
      expect(mappedEntity.esVecinoConfiable, isTrue);
    });
  });

  group('UserRepository Contract Test', () {
    test('Simulación de operaciones del repositorio usando entidad pura', () async {
      final repository = MockUserRepository();

      const vecino = UserEntity(
        id: 'vec-1',
        nombre: 'Don Chema',
        coloniaComunidad: 'Centro',
        telefono: '4183334455',
        calificacionAcumulada: 3.5,
        totalCalificaciones: 2,
      );

      await repository.createUser(vecino);

      final fetched = await repository.getUserById('vec-1');
      expect(fetched, isNotNull);
      expect(fetched?.nombre, 'Don Chema');

      final current = await repository.getCurrentUser();
      expect(current?.id, 'vec-1');

      final vecinosEnCentro = await repository.getUsersByColonia('Centro');
      expect(vecinosEnCentro.length, 1);
      expect(vecinosEnCentro.first.id, 'vec-1');

      await repository.updateRating(
        userId: 'vec-1',
        nuevaCalificacionAcumulada: 4.5,
        nuevoTotalCalificaciones: 4,
      );

      final updated = await repository.getUserById('vec-1');
      expect(updated?.calificacionAcumulada, 4.5);
      expect(updated?.totalCalificaciones, 4);
      expect(updated?.esVecinoConfiable, isTrue);
    });
  });
}
