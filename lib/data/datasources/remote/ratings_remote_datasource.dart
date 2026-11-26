import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../models/rating_model.dart';

/// Fuente de datos remota para calificaciones vecinales en Supabase (tabla 'ratings').
abstract class RatingsRemoteDataSource {
  Future<RatingModel> insertRating(RatingModel rating);
  Future<List<RatingModel>> fetchRatingsForUser(String userId);
  Future<List<RatingModel>> fetchRatingsForExchange(String intercambioId);
}

class SupabaseRatingsRemoteDataSource implements RatingsRemoteDataSource {
  final SupabaseClient? _customClient;
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  SupabaseRatingsRemoteDataSource({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client {
    if (_customClient != null) return _customClient!;
    return SupabaseService.instance.client;
  }

  bool _isValidUuid(String? value) {
    if (value == null) return false;
    return _uuidRegex.hasMatch(value.trim());
  }

  @override
  Future<RatingModel> insertRating(RatingModel rating) async {
    final payload = rating.toJson();
    if (!_isValidUuid(payload['id']?.toString())) {
      payload.remove('id');
    }
    if (payload.containsKey('intercambio_id') &&
        !_isValidUuid(payload['intercambio_id']?.toString())) {
      payload.remove('intercambio_id');
    }

    final response =
        await _client.from('ratings').insert(payload).select().single();
    return RatingModel.fromJson(response);
  }

  @override
  Future<List<RatingModel>> fetchRatingsForUser(String userId) async {
    final response = await _client
        .from('ratings')
        .select()
        .eq('evaluado_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => RatingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<RatingModel>> fetchRatingsForExchange(
      String intercambioId) async {
    final response = await _client
        .from('ratings')
        .select()
        .eq('intercambio_id', intercambioId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => RatingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class MockRatingsRemoteDataSource implements RatingsRemoteDataSource {
  final List<RatingModel> _ratings = [];

  List<RatingModel> get ratings => List.unmodifiable(_ratings);

  @override
  Future<RatingModel> insertRating(RatingModel rating) async {
    await Future.delayed(const Duration(milliseconds: 15));
    final saved = RatingModel(
      id: rating.id.isNotEmpty
          ? rating.id
          : 'rat-${DateTime.now().millisecondsSinceEpoch}',
      evaluadorId: rating.evaluadorId,
      evaluadoId: rating.evaluadoId,
      intercambioId: rating.intercambioId,
      estrellas: rating.estrellas,
      comentario: rating.comentario,
      fechaCreacion: rating.fechaCreacion,
    );
    _ratings.insert(0, saved);
    return saved;
  }

  @override
  Future<List<RatingModel>> fetchRatingsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _ratings.where((r) => r.evaluadoId == userId).toList();
  }

  @override
  Future<List<RatingModel>> fetchRatingsForExchange(
      String intercambioId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _ratings.where((r) => r.intercambioId == intercambioId).toList();
  }
}
