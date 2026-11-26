import '../../domain/models/rating_entity.dart';
import '../../domain/repositories/ratings_repository.dart';
import '../datasources/remote/ratings_remote_datasource.dart';
import '../models/rating_model.dart';

/// Implementación de [RatingsRepository] conectada a Supabase ('ratings')
/// con respaldo en memoria para operación offline y pruebas unitarias.
class RatingsRepositoryImpl implements RatingsRepository {
  final RatingsRemoteDataSource? _remoteDataSource;
  final List<RatingModel> _inMemoryRatings = [];

  RatingsRepositoryImpl({RatingsRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<RatingEntity> submitRating(RatingEntity rating) async {
    if (!rating.esPuntuacionValida) {
      throw ArgumentError(
          'La calificación debe ser un entero entre 1 y 5 estrellas.');
    }
    if (rating.esAutocalificacion) {
      throw StateError('No puedes calificarte a ti mismo.');
    }

    final model = RatingModel.fromEntity(rating);

    if (_remoteDataSource != null) {
      try {
        final saved = await _remoteDataSource!.insertRating(model);
        _inMemoryRatings.insert(0, saved);
        return saved.toEntity();
      } catch (_) {
        // Fallback en memoria si Supabase no está accesible o el ID es simulado
      }
    }

    _inMemoryRatings.insert(0, model);
    return model.toEntity();
  }

  @override
  Future<List<RatingEntity>> getRatingsForUser(String userId) async {
    if (_remoteDataSource != null) {
      try {
        final remote = await _remoteDataSource!.fetchRatingsForUser(userId);
        return remote.map((m) => m.toEntity()).toList();
      } catch (_) {}
    }
    return _inMemoryRatings
        .where((r) => r.evaluadoId == userId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<List<RatingEntity>> getRatingsForExchange(
      String intercambioId) async {
    if (_remoteDataSource != null) {
      try {
        final remote =
            await _remoteDataSource!.fetchRatingsForExchange(intercambioId);
        return remote.map((m) => m.toEntity()).toList();
      } catch (_) {}
    }
    return _inMemoryRatings
        .where((r) => r.intercambioId == intercambioId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<double> getAverageRatingForUser(String userId) async {
    final ratings = await getRatingsForUser(userId);
    if (ratings.isEmpty) return 0.0;
    final total = ratings.fold<int>(0, (acc, r) => acc + r.estrellas);
    return double.parse((total / ratings.length).toStringAsFixed(2));
  }
}
