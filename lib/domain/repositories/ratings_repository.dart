import '../models/rating_entity.dart';

/// Contrato de repositorio para calificaciones y reputación vecinal.
abstract class RatingsRepository {
  Future<RatingEntity> submitRating(RatingEntity rating);
  Future<List<RatingEntity>> getRatingsForUser(String userId);
  Future<List<RatingEntity>> getRatingsForExchange(String intercambioId);
  Future<double> getAverageRatingForUser(String userId);
}
