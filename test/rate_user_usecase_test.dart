import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/domain/models/user_entity.dart';
import 'package:swappia_app/domain/repositories/user_repository.dart';
import 'package:swappia_app/domain/usecases/rate_user_usecase.dart';

class MockUserRepository implements UserRepository {
  final Map<String, UserEntity> _users = {};
  double? lastUpdatedAverage;
  int? lastUpdatedTotal;
  String? lastUpdatedUserId;

  void addUser(UserEntity user) {
    _users[user.id] = user;
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    return _users[id];
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _users.values.firstOrNull;
  }

  @override
  Future<void> createUser(UserEntity user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    _users[user.id] = user;
  }

  @override
  Future<List<UserEntity>> getUsersByColonia(String coloniaComunidad) async {
    return _users.values
        .where((u) => u.coloniaComunidad == coloniaComunidad)
        .toList();
  }

  @override
  Future<void> updateRating({
    required String userId,
    required double nuevaCalificacionAcumulada,
    required int nuevoTotalCalificaciones,
  }) async {
    lastUpdatedUserId = userId;
    lastUpdatedAverage = nuevaCalificacionAcumulada;
    lastUpdatedTotal = nuevoTotalCalificaciones;

    final existing = _users[userId];
    if (existing != null) {
      _users[userId] = existing.copyWith(
        calificacionAcumulada: nuevaCalificacionAcumulada,
        totalCalificaciones: nuevoTotalCalificaciones,
      );
    }
  }
}

void main() {
  group('RateUserUseCase Tests', () {
    late MockUserRepository mockUserRepository;
    late RateUserUseCase rateUserUseCase;

    setUp(() {
      mockUserRepository = MockUserRepository();
      rateUserUseCase = RateUserUseCase(mockUserRepository);

      mockUserRepository.addUser(UserEntity(
        id: 'usr-target',
        nombre: 'Vecino Don José',
        coloniaComunidad: 'Centro',
        telefono: '4181112233',
        calificacionAcumulada: 4.0,
        totalCalificaciones: 1, // Calificación inicial: 4.0 con 1 reseña
        fechaRegistro: DateTime(2026, 1, 1),
      ));
    });

    test('Califica exitosamente a un vecino y calcula nuevo promedio ponderado', () async {
      // Si tiene 1 calificación de 4.0 y recibe una de 5.0:
      // (4.0 * 1 + 5.0) / 2 = 9.0 / 2 = 4.5
      final updatedUser = await rateUserUseCase.execute(
        targetUserId: 'usr-target',
        reviewerUserId: 'usr-reviewer',
        rating: 5.0,
        comment: 'Excelente vecino, intercambio rápido y confiable',
      );

      expect(updatedUser.totalCalificaciones, 2);
      expect(updatedUser.calificacionAcumulada, 4.5);
      expect(mockUserRepository.lastUpdatedUserId, 'usr-target');
      expect(mockUserRepository.lastUpdatedTotal, 2);
      expect(mockUserRepository.lastUpdatedAverage, 4.5);
    });

    test('Lanza ArgumentError cuando la calificación es menor a 1.0', () async {
      expect(
        () => rateUserUseCase.execute(
          targetUserId: 'usr-target',
          reviewerUserId: 'usr-reviewer',
          rating: 0.5,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Lanza ArgumentError cuando la calificación es mayor a 5.0', () async {
      expect(
        () => rateUserUseCase.execute(
          targetUserId: 'usr-target',
          reviewerUserId: 'usr-reviewer',
          rating: 5.5,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Lanza StateError si el usuario intenta calificarse a sí mismo', () async {
      expect(
        () => rateUserUseCase.execute(
          targetUserId: 'usr-target',
          reviewerUserId: 'usr-target',
          rating: 5.0,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Lanza StateError si el usuario a calificar no existe', () async {
      expect(
        () => rateUserUseCase.execute(
          targetUserId: 'usr-inexistente',
          reviewerUserId: 'usr-reviewer',
          rating: 4.0,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
