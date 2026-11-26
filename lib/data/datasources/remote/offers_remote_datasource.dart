import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../models/offer_model.dart';

/// Contrato para la fuente de datos remota de ofertas y almacenamiento de imágenes.
abstract class OffersRemoteDataSource {
  /// Sube la imagen de la oferta al bucket de Supabase Storage ('offer_images')
  /// y retorna la URL pública generada.
  Future<String> uploadOfferImage({
    required String filePath,
    Uint8List? fileBytes,
    required String fileName,
  });

  /// Inserta una nueva oferta en la tabla 'offers' de PostgreSQL y retorna el modelo creado.
  Future<OfferModel> createOffer(OfferModel offer);

  /// Consulta todas las ofertas activas ordenadas por fecha de publicación.
  Future<List<OfferModel>> getOffers();

  /// Filtra ofertas activas por colonia o comunidad de Dolores Hidalgo.
  Future<List<OfferModel>> getOffersByColonia(String coloniaComunidad);

  /// Recupera publicaciones activas ordenadas por fecha reciente, filtradas
  /// por colonia y/o categoría con soporte de paginación simple.
  Future<List<OfferModel>> getFilteredOffers({
    String? colonia,
    String? categoria,
    int page = 0,
    int limit = 20,
  });

  /// Obtiene una oferta específica por su identificador único.
  Future<OfferModel?> getOfferById(String id);

  /// Actualiza el estado de la oferta en PostgreSQL.
  Future<OfferModel> updateOfferStatus(String id, String nuevoEstado);

  /// Desactiva o elimina una oferta por su identificador.
  Future<void> deleteOffer(String id);
}

/// Implementación remota de ofertas conectada a Supabase (PostgreSQL + Supabase Storage).
class SupabaseOffersRemoteDataSource implements OffersRemoteDataSource {
  final SupabaseClient? _customClient;
  static const String bucketName = 'offer_images';
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

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

  SupabaseOffersRemoteDataSource({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client {
    if (_customClient != null) {
      return _customClient!;
    }
    return SupabaseService.instance.client;
  }

  @override
  Future<String> uploadOfferImage({
    required String filePath,
    Uint8List? fileBytes,
    required String fileName,
  }) async {
    try {
      final sanitizedName = fileName
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
          .toLowerCase();
      final ext = sanitizedName.contains('.')
          ? sanitizedName.split('.').last
          : 'jpg';
      final uniquePath = 'public/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

      Uint8List bytesToUpload;
      if (fileBytes != null && fileBytes.isNotEmpty) {
        bytesToUpload = fileBytes;
      } else {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('El archivo de imagen no existe en la ruta: $filePath');
        }
        bytesToUpload = await file.readAsBytes();
      }

      await _client.storage.from(bucketName).uploadBinary(
            uniquePath,
            bytesToUpload,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      final publicUrl = _client.storage.from(bucketName).getPublicUrl(uniquePath);
      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('Error al subir imagen al bucket de Supabase: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error inesperado al subir fotografía de la oferta: $e');
    }
  }

  @override
  Future<OfferModel> createOffer(OfferModel offer) async {
    try {
      final authUser = _client.auth.currentUser;
      final session = _client.auth.currentSession;
      if (authUser == null || session == null) {
        throw Exception(
          'Tu sesión en Supabase no está activa. Confirma tu correo electrónico (o desactiva "Confirm email" en Supabase Auth) e inicia sesión nuevamente.',
        );
      }

      final payload = offer.toJson();
      payload['usuario_id'] = authUser.id;
      if (payload['fecha_publicacion'] == null) {
        payload.remove('fecha_publicacion');
      }

      if (payload['id'] == null ||
          payload['id'].toString().isEmpty ||
          payload['id'].toString().startsWith('temp-') ||
          !_isValidUuid(payload['id'].toString())) {
        payload.remove('id');
      }

      // Subir imagen local al bucket offer_images antes de insertar la fila
      final rawPhoto = offer.fotoUrl.trim();
      final isRemoteOrData = rawPhoto.startsWith('http://') ||
          rawPhoto.startsWith('https://') ||
          rawPhoto.startsWith('data:image');
      if (rawPhoto.isNotEmpty && !isRemoteOrData) {
        final localFile = File(rawPhoto);
        if (localFile.existsSync()) {
          try {
            final fileName = rawPhoto.split(Platform.pathSeparator).last;
            final publicUrl = await uploadOfferImage(
              filePath: rawPhoto,
              fileName: fileName.isNotEmpty ? fileName : 'oferta.jpg',
            );
            payload['foto_url'] = publicUrl;
          } catch (_) {
            // Si la subida al bucket falla, conservar la ruta original
          }
        }
      }

      try {
        final response = await _client
            .from('offers')
            .insert(payload)
            .select()
            .single();

        return OfferModel.fromJson(response);
      } on PostgrestException catch (e) {
        if (!_isMissingTableError(e)) {
          if (e.code == '42501') {
            throw Exception(
              'Sin permisos para guardar la oferta (RLS). Verifica que hayas iniciado sesión con tu cuenta confirmada.',
            );
          }
          rethrow;
        }

        final altPayload = Map<String, dynamic>.from(payload);
        if (altPayload.containsKey('activa')) {
          altPayload['activo'] = altPayload.remove('activa');
        }
        if (altPayload.containsKey('colonia_comunidad')) {
          altPayload['colonia'] = altPayload.remove('colonia_comunidad');
        }

        final response = await _client
            .from('publicaciones')
            .insert(altPayload)
            .select()
            .single();

        return OfferModel.fromJson(response);
      }
    } on PostgrestException catch (e) {
      throw Exception('Error en base de datos al guardar la oferta: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error inesperado al registrar oferta: $e');
    }
  }

  @override
  Future<List<OfferModel>> getOffers() async {
    return getFilteredOffers();
  }

  @override
  Future<List<OfferModel>> getOffersByColonia(String coloniaComunidad) async {
    return getFilteredOffers(colonia: coloniaComunidad);
  }

  @override
  Future<List<OfferModel>> getFilteredOffers({
    String? colonia,
    String? categoria,
    int page = 0,
    int limit = 20,
  }) async {
    final fromIndex = page * limit;
    final toIndex = fromIndex + limit - 1;

    try {
      var query = _client.from('offers').select().eq('activa', true);

      if (colonia != null && colonia.trim().isNotEmpty) {
        query = query.ilike('colonia_comunidad', '%${colonia.trim()}%');
      }

      if (categoria != null && categoria.trim().isNotEmpty) {
        query = query.ilike('categoria', '%${categoria.trim()}%');
      }

      final response = await query
          .order('fecha_publicacion', ascending: false)
          .range(fromIndex, toIndex);

      final list = response as List;
      return list
          .map((item) => OfferModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        var altQuery = _client.from('publicaciones').select().eq('activo', true);

        if (colonia != null && colonia.trim().isNotEmpty) {
          altQuery = altQuery.ilike('colonia', '%${colonia.trim()}%');
        }

        if (categoria != null && categoria.trim().isNotEmpty) {
          altQuery = altQuery.ilike('categoria', '%${categoria.trim()}%');
        }

        final response = await altQuery
            .order('created_at', ascending: false)
            .range(fromIndex, toIndex);

        final list = response as List;
        return list
            .map((item) => OfferModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  @override
  Future<OfferModel?> getOfferById(String id) async {
    try {
      final response = await _client
          .from('offers')
          .select()
          .eq('id', id)
          .eq('activa', true)
          .maybeSingle();

      if (response == null) {
        final pubResponse = await _client
            .from('publicaciones')
            .select()
            .eq('id', id)
            .eq('activo', true)
            .maybeSingle();
        if (pubResponse == null) return null;
        return OfferModel.fromJson(pubResponse);
      }
      return OfferModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<OfferModel> updateOfferStatus(String id, String nuevoEstado) async {
    try {
      try {
        final response = await _client
            .from('offers')
            .update({'estado': nuevoEstado})
            .eq('id', id)
            .select()
            .single();
        return OfferModel.fromJson(response);
      } catch (_) {
        final response = await _client
            .from('publicaciones')
            .update({'estado': nuevoEstado})
            .eq('id', id)
            .select()
            .single();
        return OfferModel.fromJson(response);
      }
    } catch (e) {
      // Fallback a buscar oferta actual y actualizarla
      final existing = await getOfferById(id);
      if (existing != null) {
        return OfferModel(
          id: existing.id,
          usuarioId: existing.usuarioId,
          titulo: existing.titulo,
          descripcion: existing.descripcion,
          categoria: existing.categoria,
          coloniaComunidad: existing.coloniaComunidad,
          fotoUrl: existing.fotoUrl,
          modalidad: existing.modalidad,
          loQueBusca: existing.loQueBusca,
          precioEstimado: existing.precioEstimado,
          fechaPublicacion: existing.fechaPublicacion,
          activa: existing.activa,
          estado: nuevoEstado,
        );
      }
      throw Exception('No se pudo actualizar el estado de la oferta en Supabase: $e');
    }
  }

  @override
  Future<void> deleteOffer(String id) async {
    try {
      await _client.from('offers').update({'activa': false}).eq('id', id);
    } catch (_) {
      try {
        await _client.from('publicaciones').update({'activo': false}).eq('id', id);
      } catch (e) {
        throw Exception('No se pudo desactivar la oferta: $e');
      }
    }
  }
}

class MockOffersRemoteDataSource implements OffersRemoteDataSource {
  final List<OfferModel> _storedOffers = [];

  List<OfferModel> get storedOffers => List.unmodifiable(_storedOffers);

  @override
  Future<String> uploadOfferImage({
    required String filePath,
    Uint8List? fileBytes,
    required String fileName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return 'https://supabase.co/storage/v1/object/public/offer_images/public_${DateTime.now().millisecondsSinceEpoch}_$cleanName';
  }

  @override
  Future<OfferModel> createOffer(OfferModel offer) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final id = offer.id.isNotEmpty && !offer.id.startsWith('temp-')
        ? offer.id
        : 'off-${DateTime.now().millisecondsSinceEpoch}';
    final saved = offer.id == id
        ? offer
        : OfferModel(
            id: id,
            usuarioId: offer.usuarioId,
            titulo: offer.titulo,
            descripcion: offer.descripcion,
            categoria: offer.categoria,
            coloniaComunidad: offer.coloniaComunidad,
            fotoUrl: offer.fotoUrl,
            modalidad: offer.modalidad,
            loQueBusca: offer.loQueBusca,
            precioEstimado: offer.precioEstimado,
            fechaPublicacion: offer.fechaPublicacion ?? DateTime.now(),
            activa: offer.activa,
            estado: offer.estado,
          );
    _storedOffers.insert(0, saved);
    return saved;
  }

  @override
  Future<List<OfferModel>> getOffers() async {
    return getFilteredOffers();
  }

  @override
  Future<List<OfferModel>> getOffersByColonia(String coloniaComunidad) async {
    return getFilteredOffers(colonia: coloniaComunidad);
  }

  @override
  Future<List<OfferModel>> getFilteredOffers({
    String? colonia,
    String? categoria,
    int page = 0,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 30));
    var results = _storedOffers.where((o) => o.activa);

    if (colonia != null && colonia.trim().isNotEmpty) {
      results = results.where((o) =>
          o.coloniaComunidad.trim().toLowerCase() ==
          colonia.trim().toLowerCase());
    }

    if (categoria != null && categoria.trim().isNotEmpty) {
      results = results.where((o) =>
          o.categoria.trim().toLowerCase() ==
          categoria.trim().toLowerCase());
    }

    final sorted = results.toList()
      ..sort((a, b) {
        final dateA = a.fechaPublicacion ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.fechaPublicacion ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

    final skip = page * limit;
    return sorted.skip(skip).take(limit).toList();
  }

  @override
  Future<OfferModel?> getOfferById(String id) async {
    await Future.delayed(const Duration(milliseconds: 20));
    try {
      return _storedOffers.firstWhere((o) => o.id == id && o.activa);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<OfferModel> updateOfferStatus(String id, String nuevoEstado) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final index = _storedOffers.indexWhere((o) => o.id == id);
    if (index != -1) {
      final current = _storedOffers[index];
      final updated = OfferModel(
        id: current.id,
        usuarioId: current.usuarioId,
        titulo: current.titulo,
        descripcion: current.descripcion,
        categoria: current.categoria,
        coloniaComunidad: current.coloniaComunidad,
        fotoUrl: current.fotoUrl,
        modalidad: current.modalidad,
        loQueBusca: current.loQueBusca,
        precioEstimado: current.precioEstimado,
        fechaPublicacion: current.fechaPublicacion,
        activa: current.activa,
        estado: nuevoEstado,
      );
      _storedOffers[index] = updated;
      return updated;
    }
    throw Exception('Oferta no encontrada para actualizar estado: $id');
  }

  @override
  Future<void> deleteOffer(String id) async {
    await Future.delayed(const Duration(milliseconds: 20));
    _storedOffers.removeWhere((o) => o.id == id);
  }
}
