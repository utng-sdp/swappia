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

  /// Obtiene una oferta específica por su identificador único.
  Future<OfferModel?> getOfferById(String id);

  /// Desactiva o elimina una oferta por su identificador.
  Future<void> deleteOffer(String id);
}

/// Implementación remota de ofertas conectada a Supabase (PostgreSQL + Supabase Storage).
class SupabaseOffersRemoteDataSource implements OffersRemoteDataSource {
  final SupabaseClient? _customClient;
  static const String bucketName = 'offer_images';

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
      final payload = offer.toJson();

      // Si el id está vacío o es un placeholder temporal, dejamos que PostgreSQL genere el UUID
      if (payload['id'] == null ||
          payload['id'].toString().isEmpty ||
          payload['id'].toString().startsWith('temp-')) {
        payload.remove('id');
      }

      try {
        final response = await _client
            .from('offers')
            .insert(payload)
            .select()
            .single();

        return OfferModel.fromJson(response);
      } catch (_) {
        // Fallback a 'publicaciones'
        final response = await _client
            .from('publicaciones')
            .insert(payload)
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
    try {
      final response = await _client
          .from('offers')
          .select()
          .eq('activa', true)
          .order('fecha_publicacion', ascending: false);

      final list = response as List;
      return list
          .map((item) => OfferModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final response = await _client
            .from('publicaciones')
            .select()
            .eq('activa', true)
            .order('fecha_publicacion', ascending: false);

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
  Future<List<OfferModel>> getOffersByColonia(String coloniaComunidad) async {
    try {
      final response = await _client
          .from('offers')
          .select()
          .eq('activa', true)
          .ilike('colonia_comunidad', coloniaComunidad)
          .order('fecha_publicacion', ascending: false);

      final list = response as List;
      return list
          .map((item) => OfferModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final response = await _client
            .from('publicaciones')
            .select()
            .eq('activa', true)
            .ilike('colonia_comunidad', coloniaComunidad)
            .order('fecha_publicacion', ascending: false);

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
            .eq('activa', true)
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
  Future<void> deleteOffer(String id) async {
    try {
      await _client.from('offers').update({'activa': false}).eq('id', id);
    } catch (_) {
      try {
        await _client.from('publicaciones').update({'activa': false}).eq('id', id);
      } catch (e) {
        throw Exception('No se pudo desactivar la oferta: $e');
      }
    }
  }
}

/// Implementación Mock en memoria para pruebas unitarias y modo sin conexión.
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
          );
    _storedOffers.insert(0, saved);
    return saved;
  }

  @override
  Future<List<OfferModel>> getOffers() async {
    await Future.delayed(const Duration(milliseconds: 30));
    return _storedOffers.where((o) => o.activa).toList();
  }

  @override
  Future<List<OfferModel>> getOffersByColonia(String coloniaComunidad) async {
    await Future.delayed(const Duration(milliseconds: 30));
    return _storedOffers
        .where((o) =>
            o.activa &&
            o.coloniaComunidad.toLowerCase() == coloniaComunidad.toLowerCase())
        .toList();
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
  Future<void> deleteOffer(String id) async {
    await Future.delayed(const Duration(milliseconds: 20));
    _storedOffers.removeWhere((o) => o.id == id);
  }
}
