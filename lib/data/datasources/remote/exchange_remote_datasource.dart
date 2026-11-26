import 'dart:async';
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

  /// Escucha actualizaciones en tiempo real mediante WebSockets de Supabase Realtime
  Stream<ExchangeModel> listenToExchangeUpdates({
    String? offerId,
    String? exchangeId,
  });

  /// Emite una actualización en vivo (para mocks y pruebas)
  void emitRealtimeUpdate(ExchangeModel model);
}

/// Implementación remota conectada a Supabase (PostgreSQL y Realtime).
/// Persiste propuestas en la tabla 'exchanges' con fallback a 'intercambios' o 'propuestas'.
class SupabaseExchangeRemoteDataSource implements ExchangeRemoteDataSource {
  final SupabaseClient? _customClient;
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final StreamController<ExchangeModel> _localStreamController =
      StreamController<ExchangeModel>.broadcast();

  bool _isValidUuid(String? value) {
    if (value == null) return false;
    return _uuidRegex.hasMatch(value.trim());
  }

  bool _isMissingTableError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return e.code == 'PGRST205' ||
        e.code == '42P01' ||
        msg.contains('could not find the table');
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
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      payload['usuario_proponente_id'] = currentUser.id;
    }

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
      final model = ExchangeModel.fromJson(response);
      _localStreamController.add(model);
      return model;
    } on PostgrestException catch (e) {
      if (!_isMissingTableError(e)) {
        rethrow;
      }
      try {
        final response = await _client
            .from('intercambios')
            .insert(payload)
            .select()
            .single();
        final model = ExchangeModel.fromJson(response);
        _localStreamController.add(model);
        return model;
      } on PostgrestException catch (e2) {
        if (!_isMissingTableError(e2)) {
          rethrow;
        }
        final response = await _client
            .from('propuestas')
            .insert(payload)
            .select()
            .single();
        final model = ExchangeModel.fromJson(response);
        _localStreamController.add(model);
        return model;
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
    ExchangeModel updated;
    try {
      final response = await _client
          .from('exchanges')
          .update({'estado': nuevoEstado, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();
      updated = ExchangeModel.fromJson(response);
    } catch (_) {
      final response = await _client
          .from('intercambios')
          .update({'estado': nuevoEstado})
          .eq('id', id)
          .select()
          .single();
      updated = ExchangeModel.fromJson(response);
    }
    _localStreamController.add(updated);
    return updated;
  }

  @override
  Stream<ExchangeModel> listenToExchangeUpdates({
    String? offerId,
    String? exchangeId,
  }) {
    late StreamController<ExchangeModel> controller;

    controller = StreamController<ExchangeModel>.broadcast(
      onListen: () {
        try {
          final channelName = 'public:exchanges:${exchangeId ?? offerId ?? 'all'}';
          final channel = _client.channel(channelName);

          channel
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'exchanges',
                callback: (payload) {
                  try {
                    final data = payload.newRecord;
                    if (data.isNotEmpty) {
                      final exchange = ExchangeModel.fromJson(data);
                      if (exchangeId != null && exchange.id != exchangeId) return;
                      if (offerId != null && exchange.offerId != offerId) return;
                      if (!controller.isClosed) {
                        controller.add(exchange);
                      }
                    }
                  } catch (_) {}
                },
              )
              .subscribe();
        } catch (_) {}

        // También vincular con el stream local para notificaciones inmediatas
        final sub = _localStreamController.stream.listen((exchange) {
          if (exchangeId != null && exchange.id != exchangeId) return;
          if (offerId != null && exchange.offerId != offerId) return;
          if (!controller.isClosed) {
            controller.add(exchange);
          }
        });
        controller.onCancel = () => sub.cancel();
      },
    );

    return controller.stream;
  }

  @override
  void emitRealtimeUpdate(ExchangeModel model) {
    _localStreamController.add(model);
  }
}

/// Implementación Mock en memoria para pruebas unitarias y modo sin conexión.
class MockExchangeRemoteDataSource implements ExchangeRemoteDataSource {
  final List<ExchangeModel> _proposals = [];
  final StreamController<ExchangeModel> _streamController =
      StreamController<ExchangeModel>.broadcast();

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
    _streamController.add(saved);
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
      _streamController.add(updated);
      return updated;
    }
    throw Exception('Propuesta no encontrada para actualizar: $id');
  }

  @override
  Stream<ExchangeModel> listenToExchangeUpdates({
    String? offerId,
    String? exchangeId,
  }) {
    return _streamController.stream.where((item) {
      if (exchangeId != null && item.id != exchangeId) return false;
      if (offerId != null && item.offerId != offerId) return false;
      return true;
    });
  }

  @override
  void emitRealtimeUpdate(ExchangeModel model) {
    _streamController.add(model);
  }
}
