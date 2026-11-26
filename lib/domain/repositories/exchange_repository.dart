import '../models/exchange_entity.dart';

/// Contrato para el repositorio de propuestas y acuerdos de intercambio vecinal.
abstract class ExchangeRepository {
  /// Registra y persiste una nueva propuesta de intercambio.
  Future<ExchangeEntity> createProposal(ExchangeEntity exchange);

  /// Consulta las propuestas recibidas o asociadas a una publicación específica.
  Future<List<ExchangeEntity>> getProposalsForOffer(String offerId);

  /// Consulta las propuestas enviadas o recibidas por un usuario.
  Future<List<ExchangeEntity>> getProposalsByUser(String userId);

  /// Obtiene una propuesta por su identificador único.
  Future<ExchangeEntity?> getProposalById(String id);

  /// Actualiza el estado de una propuesta (ej. 'aceptada', 'rechazada').
  Future<ExchangeEntity> updateProposalStatus(String id, String nuevoEstado);

  /// Escucha en tiempo real (WebSockets / Supabase Realtime) las actualizaciones de propuestas
  Stream<ExchangeEntity> listenToExchangeUpdates({
    String? offerId,
    String? exchangeId,
  });

  /// Emite una actualización de prueba o simulación en tiempo real
  void emitRealtimeUpdate(ExchangeEntity exchange);
}
