import '../../domain/models/offer_entity.dart';
import '../../domain/repositories/offer_repository.dart';
import '../datasources/remote/offers_remote_datasource.dart';
import '../models/offer_model.dart';

/// Implementación del repositorio de ofertas para persistencia remota y local.
class OfferRepositoryImpl implements OfferRepository {
  final OffersRemoteDataSource? _remoteDataSource;
  final List<OfferModel> _inMemoryOffers = [];

  OfferRepositoryImpl({OffersRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<OfferEntity> publishOffer(OfferEntity offer) async {
    final model = OfferModel.fromEntity(offer);

    if (_remoteDataSource != null) {
      final savedModel = await _remoteDataSource!.createOffer(model);
      _inMemoryOffers.insert(0, savedModel);
      return savedModel.toEntity();
    }

    _inMemoryOffers.insert(0, model);
    return model.toEntity();
  }

  @override
  Future<List<OfferEntity>> getOffers() async {
    return getFilteredOffers();
  }

  @override
  Future<List<OfferEntity>> getOffersByColonia(String coloniaComunidad) async {
    return getFilteredOffers(colonia: coloniaComunidad);
  }

  @override
  Future<List<OfferEntity>> getFilteredOffers({
    String? colonia,
    String? categoria,
    int page = 0,
    int limit = 20,
  }) async {
    if (_remoteDataSource != null) {
      try {
        final remoteList = await _remoteDataSource!.getFilteredOffers(
          colonia: colonia,
          categoria: categoria,
          page: page,
          limit: limit,
        );
        return remoteList.map((m) => m.toEntity()).toList();
      } catch (_) {
        // Fallback a memoria si la red falla
      }
    }

    var results = _inMemoryOffers.where((m) => m.activa);

    if (colonia != null && colonia.trim().isNotEmpty) {
      results = results.where((m) =>
          m.coloniaComunidad.trim().toLowerCase() ==
          colonia.trim().toLowerCase());
    }

    if (categoria != null && categoria.trim().isNotEmpty) {
      results = results.where((m) =>
          m.categoria.trim().toLowerCase() ==
          categoria.trim().toLowerCase());
    }

    final sorted = results.toList()
      ..sort((a, b) {
        final dateA =
            a.fechaPublicacion ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            b.fechaPublicacion ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

    final skip = page * limit;
    return sorted.skip(skip).take(limit).map((m) => m.toEntity()).toList();
  }

  @override
  Future<OfferEntity?> getOfferById(String id) async {
    if (_remoteDataSource != null) {
      try {
        final remoteModel = await _remoteDataSource!.getOfferById(id);
        if (remoteModel != null) {
          return remoteModel.toEntity();
        }
      } catch (_) {
        // Fallback a memoria
      }
    }
    try {
      final model = _inMemoryOffers.firstWhere((m) => m.id == id && m.activa);
      return model.toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteOffer(String id) async {
    if (_remoteDataSource != null) {
      try {
        await _remoteDataSource!.deleteOffer(id);
      } catch (_) {}
    }
    _inMemoryOffers.removeWhere((m) => m.id == id);
  }
}
