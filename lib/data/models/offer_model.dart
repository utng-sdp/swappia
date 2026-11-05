import '../../domain/models/offer_entity.dart';

class OfferModel {
  final String id;
  final String usuarioId;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String coloniaComunidad;
  final String fotoUrl;
  final String modalidad;
  final String? loQueBusca;
  final double? precioEstimado;
  final DateTime? fechaPublicacion;
  final bool activa;

  const OfferModel({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.coloniaComunidad,
    required this.fotoUrl,
    this.modalidad = 'trueque',
    this.loQueBusca,
    this.precioEstimado,
    this.fechaPublicacion,
    this.activa = true,
  });

  OfferEntity toEntity() {
    return OfferEntity(
      id: id,
      usuarioId: usuarioId,
      titulo: titulo,
      descripcion: descripcion,
      categoria: categoria,
      coloniaComunidad: coloniaComunidad,
      fotoUrl: fotoUrl,
      modalidad: modalidad,
      loQueBusca: loQueBusca,
      precioEstimado: precioEstimado,
      fechaPublicacion: fechaPublicacion,
      activa: activa,
    );
  }

  factory OfferModel.fromEntity(OfferEntity entity) {
    return OfferModel(
      id: entity.id,
      usuarioId: entity.usuarioId,
      titulo: entity.titulo,
      descripcion: entity.descripcion,
      categoria: entity.categoria,
      coloniaComunidad: entity.coloniaComunidad,
      fotoUrl: entity.fotoUrl,
      modalidad: entity.modalidad,
      loQueBusca: entity.loQueBusca,
      precioEstimado: entity.precioEstimado,
      fechaPublicacion: entity.fechaPublicacion,
      activa: entity.activa,
    );
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    // 1. Manejo robusto de fotos: soporte para array 'fotos', 'foto_url' o 'fotoUrl'
    String resolvedFotoUrl = '';
    if (json['fotos'] != null) {
      if (json['fotos'] is List && (json['fotos'] as List).isNotEmpty) {
        resolvedFotoUrl = (json['fotos'] as List).first.toString();
      } else if (json['fotos'] is String) {
        resolvedFotoUrl = json['fotos'].toString();
      }
    }
    if (resolvedFotoUrl.isEmpty) {
      resolvedFotoUrl = (json['foto_url'] ?? json['fotoUrl'] ?? '').toString();
    }

    // 2. Manejo de estado activo: 'activo' (tabla publicaciones), 'activa' (tabla offers)
    final rawActivo = json['activo'] ?? json['activa'];
    final bool isActiva = rawActivo == null ? true : (rawActivo == true || rawActivo == 1);

    // 3. Manejo de colonia: 'colonia' o 'colonia_comunidad'
    final String resolvedColonia = (json['colonia'] ??
            json['colonia_comunidad'] ??
            json['coloniaComunidad'] ??
            '')
        .toString();

    // 4. Manejo de fecha: 'created_at' o 'fecha_publicacion'
    DateTime? fecha;
    final rawFecha = json['created_at'] ??
        json['fecha_publicacion'] ??
        json['fechaPublicacion'];
    if (rawFecha != null) {
      fecha = DateTime.tryParse(rawFecha.toString());
    }

    return OfferModel(
      id: (json['id'] ?? '').toString(),
      usuarioId: (json['usuario_id'] ?? json['usuarioId'] ?? '').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      categoria: (json['categoria'] ?? '').toString(),
      coloniaComunidad: resolvedColonia,
      fotoUrl: resolvedFotoUrl,
      modalidad: (json['modalidad'] ?? 'trueque').toString(),
      loQueBusca: json['lo_que_busca']?.toString() ??
          json['loQueBusca']?.toString(),
      precioEstimado: (json['precio_estimado'] as num?)?.toDouble() ??
          (json['precioEstimado'] as num?)?.toDouble(),
      fechaPublicacion: fecha,
      activa: isActiva,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'colonia_comunidad': coloniaComunidad,
      'foto_url': fotoUrl,
      'modalidad': modalidad,
      'lo_que_busca': loQueBusca,
      'precio_estimado': precioEstimado,
      'fecha_publicacion': fechaPublicacion?.toIso8601String(),
      'activa': activa,
    };
  }
}
