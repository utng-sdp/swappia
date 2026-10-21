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
    return OfferModel(
      id: (json['id'] ?? '').toString(),
      usuarioId: (json['usuario_id'] ?? json['usuarioId'] ?? '').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      categoria: (json['categoria'] ?? '').toString(),
      coloniaComunidad: (json['colonia_comunidad'] ??
              json['coloniaComunidad'] ??
              '')
          .toString(),
      fotoUrl: (json['foto_url'] ?? json['fotoUrl'] ?? '').toString(),
      modalidad: (json['modalidad'] ?? 'trueque').toString(),
      loQueBusca: json['lo_que_busca']?.toString() ??
          json['loQueBusca']?.toString(),
      precioEstimado: (json['precio_estimado'] as num?)?.toDouble() ??
          (json['precioEstimado'] as num?)?.toDouble(),
      fechaPublicacion: json['fecha_publicacion'] != null
          ? DateTime.tryParse(json['fecha_publicacion'].toString())
          : (json['fechaPublicacion'] != null
              ? DateTime.tryParse(json['fechaPublicacion'].toString())
              : null),
      activa: json['activa'] == true || json['activa'] == 1,
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
