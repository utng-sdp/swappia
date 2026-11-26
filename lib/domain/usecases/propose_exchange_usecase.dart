import '../models/exchange_entity.dart';
import '../models/offer_entity.dart';
import '../repositories/exchange_repository.dart';
import '../repositories/offer_repository.dart';

/// Resultado de la ejecución de una propuesta de intercambio.
class ProposeExchangeResult {
  final ExchangeEntity proposal;
  final OfferEntity updatedOffer;

  const ProposeExchangeResult({
    required this.proposal,
    required this.updatedOffer,
  });
}

/// Caso de uso para proponer un intercambio vecinal sobre una publicación activa.
/// Aplica validaciones de reglas de negocio, persiste la propuesta en Supabase
/// y actualiza el estado de la publicación a "Pendiente de Aceptación".
class ProposeExchangeUseCase {
  final ExchangeRepository _exchangeRepository;
  final OfferRepository _offerRepository;

  ProposeExchangeUseCase({
    required ExchangeRepository exchangeRepository,
    required OfferRepository offerRepository,
  })  : _exchangeRepository = exchangeRepository,
        _offerRepository = offerRepository;

  Future<ProposeExchangeResult> execute({
    required String offerId,
    required String usuarioProponenteId,
    required String propuesta,
    String? usuarioReceptorId,
  }) async {
    // 1. Validaciones de negocio sobre campos obligatorios
    final cleanOfferId = offerId.trim();
    if (cleanOfferId.isEmpty) {
      throw Exception('El identificador de la publicación es obligatorio.');
    }

    final cleanProponenteId = usuarioProponenteId.trim();
    if (cleanProponenteId.isEmpty) {
      throw Exception('El identificador del vecino proponente es obligatorio.');
    }

    final cleanPropuesta = propuesta.trim();
    if (cleanPropuesta.isEmpty) {
      throw Exception('La descripción de la propuesta no puede estar vacía.');
    }
    if (cleanPropuesta.length < 3) {
      throw Exception('La propuesta debe tener al menos 3 caracteres descriptivos.');
    }

    // 2. Comprobar existencia y disponibilidad de la publicación
    final offer = await _offerRepository.getOfferById(cleanOfferId);
    if (offer != null) {
      if (!offer.activa) {
        throw Exception('No es posible proponer intercambio en una publicación pausada o inactiva.');
      }
      if (offer.usuarioId.isNotEmpty && offer.usuarioId == cleanProponenteId) {
        throw Exception('No puedes proponer un intercambio sobre tu propia publicación.');
      }
    }

    final resolvedReceptorId = usuarioReceptorId ?? offer?.usuarioId;

    // 3. Crear entidad y persistir en la base de datos de Supabase
    final newExchange = ExchangeEntity(
      id: 'prop_${DateTime.now().millisecondsSinceEpoch}',
      offerId: cleanOfferId,
      usuarioProponenteId: cleanProponenteId,
      usuarioReceptorId: resolvedReceptorId,
      propuesta: cleanPropuesta,
      estado: 'pendiente_aceptacion',
      fechaCreacion: DateTime.now(),
    );

    final savedExchange = await _exchangeRepository.createProposal(newExchange);

    // 4. Actualizar estado de la publicación a "Pendiente de Aceptación"
    OfferEntity updatedOffer;
    try {
      updatedOffer = await _offerRepository.updateOfferStatus(
        cleanOfferId,
        'pendiente_aceptacion',
      );
    } catch (_) {
      updatedOffer = (offer ??
              OfferEntity(
                id: cleanOfferId,
                usuarioId: resolvedReceptorId ?? '',
                titulo: 'Oferta',
                descripcion: '',
                categoria: '',
                coloniaComunidad: '',
                fotoUrl: '',
              ))
          .copyWith(estado: 'pendiente_aceptacion');
    }

    return ProposeExchangeResult(
      proposal: savedExchange,
      updatedOffer: updatedOffer,
    );
  }
}
