import '../../domain/models/exchange_entity.dart';
import '../../domain/repositories/exchange_repository.dart';
import '../datasources/remote/exchange_remote_datasource.dart';
import '../models/exchange_model.dart';

/// Implementación de ExchangeRepository con soporte de persistencia en Supabase y respaldo en memoria.
class ExchangeRepositoryImpl implements ExchangeRepository {
  final ExchangeRemoteDataSource? _remoteDataSource;
  final List<ExchangeModel> _inMemoryProposals = [];

  ExchangeRepositoryImpl({ExchangeRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<ExchangeEntity> createProposal(ExchangeEntity exchange) async {
    final model = ExchangeModel.fromEntity(exchange);

    if (_remoteDataSource != null) {
      try {
        final saved = await _remoteDataSource!.createProposal(model);
        _inMemoryProposals.insert(0, saved);
        return saved.toEntity();
      } catch (_) {
        // Fallback a memoria si la red falla
      }
    }

    _inMemoryProposals.insert(0, model);
    return model.toEntity();
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
        propuesta: current.propuesta,
        estado: nuevoEstado,
        fechaCreacion: current.fechaCreacion,
        fechaActualizacion: DateTime.now(),
      );
      _inMemoryProposals[index] = updated;
      return updated.toEntity();
    }

    throw Exception('Propuesta no encontrada para actualizar estado: $id');
  }
}
