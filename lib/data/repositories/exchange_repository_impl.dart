import 'dart:async';
import '../../domain/models/exchange_entity.dart';
import '../../domain/repositories/exchange_repository.dart';
import '../datasources/remote/exchange_remote_datasource.dart';
import '../models/exchange_model.dart';

/// Implementación de ExchangeRepository con soporte de persistencia en Supabase,
/// WebSockets de Supabase Realtime y respaldo reactivo en memoria.
class ExchangeRepositoryImpl implements ExchangeRepository {
  final ExchangeRemoteDataSource? _remoteDataSource;
  final List<ExchangeModel> _inMemoryProposals = [];
  final StreamController<ExchangeEntity> _fallbackStreamController =
      StreamController<ExchangeEntity>.broadcast();

  ExchangeRepositoryImpl({ExchangeRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<ExchangeEntity> createProposal(ExchangeEntity exchange) async {
    final model = ExchangeModel.fromEntity(exchange);

    if (_remoteDataSource != null) {
      try {
        final saved = await _remoteDataSource!.createProposal(model);
        _inMemoryProposals.insert(0, saved);
        _fallbackStreamController.add(saved.toEntity());
        return saved.toEntity();
      } catch (_) {
        // Fallback a memoria si la red falla
      }
    }

    _inMemoryProposals.insert(0, model);
    final entity = model.toEntity();
    _fallbackStreamController.add(entity);
    return entity;
  }

  @override
  Future<List<ExchangeEntity>> getProposalsForOffer(String offerId) async {
    if (_remoteDataSource != null) {
      try {
        final list = await _remoteDataSource!.getProposalsForOffer(offerId);
        return list.map((m) => m.toEntity()).toList();
      } catch (_) {
        // Fallback
      }
    }
    return _inMemoryProposals
        .where((p) => p.offerId == offerId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<List<ExchangeEntity>> getProposalsByUser(String userId) async {
    if (_remoteDataSource != null) {
      try {
        final list = await _remoteDataSource!.getProposalsByUser(userId);
        return list.map((m) => m.toEntity()).toList();
      } catch (_) {
        // Fallback
      }
    }
    return _inMemoryProposals
        .where((p) =>
            p.usuarioProponenteId == userId || p.usuarioReceptorId == userId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<ExchangeEntity?> getProposalById(String id) async {
    if (_remoteDataSource != null) {
      try {
        final item = await _remoteDataSource!.getProposalById(id);
        if (item != null) return item.toEntity();
      } catch (_) {
        // Fallback
      }
    }
    try {
      final model = _inMemoryProposals.firstWhere((p) => p.id == id);
      return model.toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ExchangeEntity> updateProposalStatus(String id, String nuevoEstado) async {
    if (_remoteDataSource != null) {
      try {
        final updated =
            await _remoteDataSource!.updateProposalStatus(id, nuevoEstado);
        final index = _inMemoryProposals.indexWhere((p) => p.id == id);
        if (index != -1) {
          _inMemoryProposals[index] = updated;
        }
        _fallbackStreamController.add(updated.toEntity());
        return updated.toEntity();
      } catch (_) {
        // Fallback
      }
    }

    final index = _inMemoryProposals.indexWhere((p) => p.id == id);
    if (index != -1) {
      final current = _inMemoryProposals[index];
      final updated = ExchangeModel(
        id: current.id,
        offerId: current.offerId,
        usuarioProponenteId: current.usuarioProponenteId,
        usuarioReceptorId: current.usuarioReceptorId,
        modalidad: current.modalidad,
        propuesta: current.propuesta,
        montoEfectivo: current.montoEfectivo,
        bienOfrecidoId: current.bienOfrecidoId,
        bienOfrecidoTitulo: current.bienOfrecidoTitulo,
        estado: nuevoEstado,
        fechaCreacion: current.fechaCreacion,
        fechaActualizacion: DateTime.now(),
      );
      _inMemoryProposals[index] = updated;
      final entity = updated.toEntity();
      _fallbackStreamController.add(entity);
      return entity;
    }

    final fallback = ExchangeEntity(
      id: id,
      offerId: '',
      usuarioProponenteId: '',
      propuesta: '',
      estado: nuevoEstado,
      fechaCreacion: DateTime.now(),
    );
    _fallbackStreamController.add(fallback);
    return fallback;
  }

  @override
  Stream<ExchangeEntity> listenToExchangeUpdates({
    String? offerId,
    String? exchangeId,
  }) {
    if (_remoteDataSource != null) {
      return _remoteDataSource!
          .listenToExchangeUpdates(offerId: offerId, exchangeId: exchangeId)
          .map((model) => model.toEntity());
    }

    return _fallbackStreamController.stream.where((item) {
      if (exchangeId != null && item.id != exchangeId) return false;
      if (offerId != null && item.offerId != offerId) return false;
      return true;
    });
  }

  @override
  void emitRealtimeUpdate(ExchangeEntity exchange) {
    if (_remoteDataSource != null) {
      _remoteDataSource!.emitRealtimeUpdate(ExchangeModel.fromEntity(exchange));
    }
    _fallbackStreamController.add(exchange);
  }
}
