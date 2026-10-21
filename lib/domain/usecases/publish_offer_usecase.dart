import '../models/offer_entity.dart';
import '../repositories/offer_repository.dart';

/// Caso de uso para publicar una nueva oferta de trueque, servicio o bien en la comunidad.
/// Aplica validaciones de reglas de negocio para asegurar integridad de datos
/// (campos requeridos, formato valido de foto y consistencia de precios).
class PublishOfferUseCase {
  final OfferRepository _repository;

  PublishOfferUseCase(this._repository);

  /// Extensiones y formatos permitidos para las imagenes de las ofertas.
  static const List<String> allowedPhotoExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  /// Valida si la ruta o URL proporcionada corresponde a un formato de foto permitido.
  static bool isValidPhotoFormat(String urlOrPath) {
    final trimmed = urlOrPath.trim();
    if (trimmed.isEmpty) return false;

    // Soporte para data URIs base64
    if (trimmed.startsWith('data:image/jpeg') ||
        trimmed.startsWith('data:image/jpg') ||
        trimmed.startsWith('data:image/png') ||
        trimmed.startsWith('data:image/webp')) {
      return true;
    }

    // Remueve posibles query params de URLs (ej. tokens o firmas)
    final cleanPath = trimmed.split('?').first.toLowerCase();
    for (final ext in allowedPhotoExtensions) {
      if (cleanPath.endsWith('.$ext')) {
        return true;
      }
    }
    return false;
  }

  /// Ejecuta la publicacion de la oferta aplicando las reglas de negocio.
  Future<OfferEntity> execute({
    required String titulo,
    required String descripcion,
    required String categoria,
    required String coloniaComunidad,
    required String usuarioId,
    required String fotoUrl,
    String modalidad = 'trueque',
    String? loQueBusca,
    double? precioEstimado,
  }) async {
    // 1. Validaciones de campos obligatorios
    final cleanTitulo = titulo.trim();
    if (cleanTitulo.isEmpty) {
      throw Exception('El título de la oferta es obligatorio');
    }
    if (cleanTitulo.length < 3) {
      throw Exception('El título debe tener al menos 3 caracteres');
    }

    final cleanDescripcion = descripcion.trim();
    if (cleanDescripcion.isEmpty) {
      throw Exception('La descripción de la oferta es obligatoria');
    }
    if (cleanDescripcion.length < 5) {
      throw Exception('La descripción debe tener al menos 5 caracteres');
    }

    final cleanCategoria = categoria.trim();
    if (cleanCategoria.isEmpty) {
      throw Exception('La categoría es obligatoria');
    }

    final cleanColonia = coloniaComunidad.trim();
    if (cleanColonia.isEmpty) {
      throw Exception('La colonia o comunidad es obligatoria');
    }

    final cleanUsuarioId = usuarioId.trim();
    if (cleanUsuarioId.isEmpty) {
      throw Exception('El identificador del usuario es obligatorio');
    }

    final cleanFotoUrl = fotoUrl.trim();
    if (cleanFotoUrl.isEmpty) {
      throw Exception('La fotografía de la oferta es obligatoria');
    }

    // 2. Validacion de formato de foto
    if (!isValidPhotoFormat(cleanFotoUrl)) {
      throw Exception(
        'El formato de la foto debe ser JPG, JPEG, PNG o WEBP',
      );
    }

    // 3. Validacion de precio estimado
    if (precioEstimado != null && precioEstimado < 0) {
      throw Exception('El precio estimado no puede ser negativo');
    }

    // 4. Normalizacion de modalidad (trueque, dinero o mixto)
    final validModalidades = ['trueque', 'dinero', 'mixto'];
    final normalizedModalidad = modalidad.trim().toLowerCase();
    final finalModalidad = validModalidades.contains(normalizedModalidad)
        ? normalizedModalidad
        : 'trueque';

    final offer = OfferEntity(
      id: 'offer_${DateTime.now().millisecondsSinceEpoch}',
      usuarioId: cleanUsuarioId,
      titulo: cleanTitulo,
      descripcion: cleanDescripcion,
      categoria: cleanCategoria,
      coloniaComunidad: cleanColonia,
      fotoUrl: cleanFotoUrl,
      modalidad: finalModalidad,
      loQueBusca: loQueBusca?.trim(),
      precioEstimado: precioEstimado,
      fechaPublicacion: DateTime.now(),
      activa: true,
    );

    return await _repository.publishOffer(offer);
  }
}
