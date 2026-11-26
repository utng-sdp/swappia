import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/data/datasources/remote/ratings_remote_datasource.dart';
import 'package:swappia_app/data/models/rating_model.dart';
import 'package:swappia_app/data/repositories/ratings_repository_impl.dart';
import 'package:swappia_app/data/repositories/user_repository_impl.dart';
import 'package:swappia_app/domain/models/rating_entity.dart';
import 'package:swappia_app/domain/models/user_entity.dart';
import 'package:swappia_app/domain/usecases/rate_user_usecase.dart';

void main() {
  group('Issue #21 & #24: RatingsRepositoryImpl y RateUserUseCase', () {
    test('Serialización de RatingModel y entidad RatingEntity', () {
      final now = DateTime(2026, 11, 20, 12, 0);
      final entity = RatingEntity(
        id: 'rat-1',
        evaluadorId: 'usr-001',
        evaluadoId: 'usr-002',
        intercambioId: 'exc-1',
        estrellas: 5,
        comentario: 'Excelente vecino',
        fechaCreacion: now,
      );

      final model = RatingModel.fromEntity(entity);
      final json = model.toJson();
      final decoded = RatingModel.fromJson(json).toEntity();

      expect(decoded, entity);
      expect(decoded.esPuntuacionValida, isTrue);
      expect(decoded.esAutocalificacion, isFalse);
    });

    test('RatingsRepositoryImpl persiste calificaciones y calcula promedio', () async {
      final repo = RatingsRepositoryImpl(
        remoteDataSource: MockRatingsRemoteDataSource(),
      );

      await repo.submitRating(
        RatingEntity(
          id: 'r1',
          evaluadorId: 'usr-a',
          evaluadoId: 'usr-target',
          estrellas: 5,
          comentario: 'Muy cumplido',
          fechaCreacion: DateTime.now(),
        ),
      );
      await repo.submitRating(
        RatingEntity(
          id: 'r2',
          evaluadorId: 'usr-b',
          evaluadoId: 'usr-target',
          estrellas: 4,
          comentario: 'Buen trato',
          fechaCreacion: DateTime.now(),
        ),
      );

      final ratings = await repo.getRatingsForUser('usr-target');
      final avg = await repo.getAverageRatingForUser('usr-target');

      expect(ratings.length, 2);
      expect(avg, 4.5);
    });

    test('RatingsRepositoryImpl rechaza rango inválido o autocalificación', () async {
      final repo = RatingsRepositoryImpl();

      expect(
        () => repo.submitRating(
          RatingEntity(
            id: 'r-bad',
            evaluadorId: 'usr-1',
            evaluadoId: 'usr-2',
            estrellas: 6,
            fechaCreacion: DateTime.now(),
          ),
        ),
        throwsArgumentError,
      );

      expect(
        () => repo.submitRating(
          RatingEntity(
            id: 'r-self',
            evaluadorId: 'usr-1',
            evaluadoId: 'usr-1',
            estrellas: 5,
            fechaCreacion: DateTime.now(),
          ),
        ),
        throwsStateError,
      );
    });

    test('RateUserUseCase guarda registro en RatingsRepository y actualiza perfil',
        () async {
      final userRepo = UserRepositoryImpl();
      await userRepo.createUser(
        const UserEntity(
          id: 'usr-vecino-rate',
          nombre: 'Don Beto',
          coloniaComunidad: 'Centro',
          telefono: '4181112233',
          calificacionAcumulada: 4.0,
          totalCalificaciones: 1,
        ),
      );
      final ratingsRepo = RatingsRepositoryImpl(
        remoteDataSource: MockRatingsRemoteDataSource(),
      );
      final useCase = RateUserUseCase(
        userRepo,
        ratingsRepository: ratingsRepo,
      );

      final updated = await useCase.execute(
        targetUserId: 'usr-vecino-rate',
        reviewerUserId: 'usr-001',
        rating: 5.0,
        comment: 'Puntual en el punto de encuentro',
        exchangeId: 'exc-99',
      );

      expect(updated.totalCalificaciones, 2);
      expect(updated.calificacionAcumulada, 4.5);

      final storedRatings = await ratingsRepo.getRatingsForUser('usr-vecino-rate');
      expect(storedRatings.length, 1);
      expect(storedRatings.first.intercambioId, 'exc-99');
      expect(storedRatings.first.estrellas, 5);
    });
  });
}
