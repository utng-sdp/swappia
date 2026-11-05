import '../models/offer_entity.dart';

abstract class OfferRepository {
  /// Publica y persiste una nueva oferta en la comunidad.
  Future<OfferEntity> publishOffer(OfferEntity offer);

  /// Obtiene todas las ofertas activas registradas.
  Future<List<OfferEntity>> getOffers();

  /// Filtra y obtiene las ofertas de una colonia o comunidad especifica.
  Future<List<OfferEntity>> getOffersByColonia(String coloniaComunidad);

  /// Recupera publicaciones activas ordenadas por fecha reciente, filtradas
  /// por colonia y/o categoría con soporte de paginación simple.
  Future<List<OfferEntity>> getFilteredOffers({
    String? colonia,
    String? categoria,
    int page = 0,
    int limit = 20,
  });

  /// Obtiene el detalle de una oferta por su identificador unico.
  Future<OfferEntity?> getOfferById(String id);

  /// Elimina o desactiva una oferta por su identificador.
  Future<void> deleteOffer(String id);
}
