import '../../domain/models/rating_entity.dart';

/// Modelo de datos para serializar calificaciones hacia la tabla 'ratings' de PostgreSQL.
class RatingModel {
  final String id;
  final String evaluadorId;
  final String evaluadoId;
  final String? intercambioId;
  final int estrellas;
  final String? comentario;
  final DateTime fechaCreacion;

  const RatingModel({
    required this.id,
    required this.evaluadorId,
    required this.evaluadoId,
    this.intercambioId,
    required this.estrellas,
    this.comentario,
    required this.fechaCreacion,
  });

  RatingEntity toEntity() => RatingEntity(
        id: id,
        evaluadorId: evaluadorId,
        evaluadoId: evaluadoId,
        intercambioId: intercambioId,
        estrellas: estrellas,
        comentario: comentario,
        fechaCreacion: fechaCreacion,
      );

  factory RatingModel.fromEntity(RatingEntity entity) => RatingModel(
        id: entity.id,
        evaluadorId: entity.evaluadorId,
        evaluadoId: entity.evaluadoId,
        intercambioId: entity.intercambioId,
        estrellas: entity.estrellas,
        comentario: entity.comentario,
        fechaCreacion: entity.fechaCreacion,
      );

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['created_at'] ?? json['fecha_creacion'];
    return RatingModel(
      id: (json['id'] ?? '').toString(),
      evaluadorId: (json['evaluador_id'] ?? json['evaluadorId'] ?? '').toString(),
      evaluadoId: (json['evaluado_id'] ?? json['evaluadoId'] ?? '').toString(),
      intercambioId: json['intercambio_id']?.toString() ??
          json['intercambioId']?.toString(),
      estrellas: (json['estrellas'] as num?)?.toInt() ?? 5,
      comentario: json['comentario'] as String?,
      fechaCreacion: rawDate != null
          ? (DateTime.tryParse(rawDate.toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'evaluador_id': evaluadorId,
        'evaluado_id': evaluadoId,
        if (intercambioId != null && intercambioId!.isNotEmpty)
          'intercambio_id': intercambioId,
        'estrellas': estrellas,
        if (comentario != null && comentario!.trim().isNotEmpty)
          'comentario': comentario!.trim(),
        'created_at': fechaCreacion.toIso8601String(),
      };
}
