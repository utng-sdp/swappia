import '../../domain/models/offer_entity.dart';
import '../../domain/repositories/offer_repository.dart';
import '../models/offer_model.dart';

/// Implementacion del repositorio de ofertas para persistencia local y remota.
class OfferRepositoryImpl implements OfferRepository {
  final List<OfferModel> _inMemoryOffers = [];

  OfferRepositoryImpl();

  @override
  Future<OfferEntity> publishOffer(OfferEntity offer) async {
    final model = OfferModel.fromEntity(offer);
    _inMemoryOffers.insert(0, model);
    return model.toEntity();
  }

  @override
  Future<List<OfferEntity>> getOffers() async {
    return _inMemoryOffers.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<OfferEntity>> getOffersByColonia(String coloniaComunidad) async {
    return _inMemoryOffers
        .where((m) =>
            m.coloniaComunidad.toLowerCase() == coloniaComunidad.toLowerCase())
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<OfferEntity?> getOfferById(String id) async {
    try {
      final model = _inMemoryOffers.firstWhere((m) => m.id == id);
      return model.toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteOffer(String id) async {
    _inMemoryOffers.removeWhere((m) => m.id == id);
  }
}
