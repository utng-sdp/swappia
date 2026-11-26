import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../models/exchange_model.dart';

/// Contrato de fuente de datos remota para propuestas de intercambio en Supabase.
abstract class ExchangeRemoteDataSource {
  Future<ExchangeModel> createProposal(ExchangeModel exchange);
  Future<List<ExchangeModel>> getProposalsForOffer(String offerId);
  Future<List<ExchangeModel>> getProposalsByUser(String userId);
  Future<ExchangeModel?> getProposalById(String id);
  Future<ExchangeModel> updateProposalStatus(String id, String nuevoEstado);
}

/// Implementación remota conectada a Supabase (PostgreSQL).
/// Persiste propuestas en la tabla 'exchanges' con fallback a 'intercambios' o 'propuestas'.
class SupabaseExchangeRemoteDataSource implements ExchangeRemoteDataSource {
  final SupabaseClient? _customClient;
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool _isValidUuid(String? value) {
    if (value == null) return false;
    return _uuidRegex.hasMatch(value.trim());
  }

  SupabaseExchangeRemoteDataSource({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client {
    if (_customClient != null) {
      return _customClient!;
    }
    return SupabaseService.instance.client;
  }

  @override
  Future<ExchangeModel> createProposal(ExchangeModel exchange) async {
    final payload = exchange.toJson();

    // Si el id no es un UUID válido, permitir que PostgreSQL genere el UUID por defecto
    if (payload['id'] == null ||
        payload['id'].toString().isEmpty ||
        !_isValidUuid(payload['id'].toString())) {
      payload.remove('id');
    }

    try {
      final response = await _client
          .from('exchanges')
          .insert(payload)
          .select()
          .single();
      return ExchangeModel.fromJson(response);
    } catch (_) {
      try {
        final response = await _client
            .from('intercambios')
            .insert(payload)
            .select()
            .single();
        return ExchangeModel.fromJson(response);
      } catch (_) {
        final response = await _client
            .from('propuestas')
            .insert(payload)
            .select()
            .single();
        return ExchangeModel.fromJson(response);
      }
    }
  }

  @override
  Future<List<ExchangeModel>> getProposalsForOffer(String offerId) async {
    try {
      final response = await _client
          .from('exchanges')
          .select()
          .eq('offer_id', offerId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((item) => ExchangeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final response = await _client
            .from('intercambios')
            .select()
            .eq('offer_id', offerId)
            .order('created_at', ascending: false);
        return (response as List)
            .map((item) => ExchangeModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  @override
  Future<List<ExchangeModel>> getProposalsByUser(String userId) async {
    try {
      final response = await _client
          .from('exchanges')
          .select()
          .or('usuario_proponente_id.eq.$userId,usuario_receptor_id.eq.$userId')
          .order('created_at', ascending: false);
      return (response as List)
          .map((item) => ExchangeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ExchangeModel?> getProposalById(String id) async {
    try {
      final response = await _client
          .from('exchanges')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return ExchangeModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ExchangeModel> updateProposalStatus(String id, String nuevoEstado) async {
    try {
      final response = await _client
          .from('exchanges')
          .update({'estado': nuevoEstado, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();
      return ExchangeModel.fromJson(response);
    } catch (_) {
      final response = await _client
          .from('intercambios')
          .update({'estado': nuevoEstado})
          .eq('id', id)
          .select()
          .single();
      return ExchangeModel.fromJson(response);
    }
  }
}

/// Implementación Mock en memoria para pruebas unitarias y modo sin conexión.
class MockExchangeRemoteDataSource implements ExchangeRemoteDataSource {
  final List<ExchangeModel> _proposals = [];

  List<ExchangeModel> get proposals => List.unmodifiable(_proposals);

  @override
  Future<ExchangeModel> createProposal(ExchangeModel exchange) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final id = exchange.id.isNotEmpty
        ? exchange.id
        : 'exc-${DateTime.now().millisecondsSinceEpoch}';
    final saved = ExchangeModel(
      id: id,
      offerId: exchange.offerId,
      usuarioProponenteId: exchange.usuarioProponenteId,
      usuarioReceptorId: exchange.usuarioReceptorId,
      propuesta: exchange.propuesta,
      estado: exchange.estado,
      fechaCreacion: exchange.fechaCreacion,
      fechaActualizacion: exchange.fechaActualizacion,
    );
    _proposals.insert(0, saved);
    return saved;
  }

  @override
  Future<List<ExchangeModel>> getProposalsForOffer(String offerId) async {
    await Future.delayed(const Duration(milliseconds: 15));
    return _proposals.where((p) => p.offerId == offerId).toList();
  }

  @override
  Future<List<ExchangeModel>> getProposalsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 15));
    return _proposals
        .where((p) =>
            p.usuarioProponenteId == userId || p.usuarioReceptorId == userId)
        .toList();
  }

  @override
  Future<ExchangeModel?> getProposalById(String id) async {
    await Future.delayed(const Duration(milliseconds: 10));
    try {
      return _proposals.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ExchangeModel> updateProposalStatus(String id, String nuevoEstado) async {
    await Future.delayed(const Duration(milliseconds: 15));
    final index = _proposals.indexWhere((p) => p.id == id);
    if (index != -1) {
      final current = _proposals[index];
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
      _proposals[index] = updated;
      return updated;
    }
    throw Exception('Propuesta no encontrada para actualizar: $id');
  }
}
