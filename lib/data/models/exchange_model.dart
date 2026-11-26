import '../../domain/models/exchange_entity.dart';

/// Modelo de datos para la persistencia de propuestas de intercambio en Supabase / PostgreSQL.
class ExchangeModel {
  final String id;
  final String offerId;
  final String usuarioProponenteId;
  final String? usuarioReceptorId;
  final String modalidad;
  final String propuesta;
  final double? montoEfectivo;
  final String? bienOfrecidoId;
  final String? bienOfrecidoTitulo;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  const ExchangeModel({
    required this.id,
    required this.offerId,
    required this.usuarioProponenteId,
    this.usuarioReceptorId,
    this.modalidad = 'trueque',
    required this.propuesta,
    this.montoEfectivo,
    this.bienOfrecidoId,
    this.bienOfrecidoTitulo,
    this.estado = 'pendiente_aceptacion',
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  ExchangeEntity toEntity() {
    return ExchangeEntity(
      id: id,
      offerId: offerId,
      usuarioProponenteId: usuarioProponenteId,
      usuarioReceptorId: usuarioReceptorId,
      modalidad: modalidad,
      propuesta: propuesta,
      montoEfectivo: montoEfectivo,
      bienOfrecidoId: bienOfrecidoId,
      bienOfrecidoTitulo: bienOfrecidoTitulo,
      estado: estado,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
    );
  }

  factory ExchangeModel.fromEntity(ExchangeEntity entity) {
    return ExchangeModel(
      id: entity.id,
      offerId: entity.offerId,
      usuarioProponenteId: entity.usuarioProponenteId,
      usuarioReceptorId: entity.usuarioReceptorId,
      modalidad: entity.modalidad,
      propuesta: entity.propuesta,
      montoEfectivo: entity.montoEfectivo,
      bienOfrecidoId: entity.bienOfrecidoId,
      bienOfrecidoTitulo: entity.bienOfrecidoTitulo,
      estado: entity.estado,
      fechaCreacion: entity.fechaCreacion,
      fechaActualizacion: entity.fechaActualizacion,
    );
  }

  factory ExchangeModel.fromJson(Map<String, dynamic> json) {
    final rawFecha = json['created_at'] ??
        json['fecha_creacion'] ??
        json['fechaCreacion'];
    final DateTime fecha = rawFecha != null
        ? (DateTime.tryParse(rawFecha.toString()) ?? DateTime.now())
        : DateTime.now();

    final rawUpdate = json['updated_at'] ??
        json['fecha_actualizacion'] ??
        json['fechaActualizacion'];
    final DateTime? fechaUpdate =
        rawUpdate != null ? DateTime.tryParse(rawUpdate.toString()) : null;

    final rawMonto = json['monto_efectivo'] ?? json['montoEfectivo'];
    final double? monto = rawMonto is num
        ? rawMonto.toDouble()
        : (rawMonto != null ? double.tryParse(rawMonto.toString()) : null);

    return ExchangeModel(
      id: (json['id'] ?? '').toString(),
      offerId: (json['offer_id'] ??
              json['publicacion_id'] ??
              json['offerId'] ??
              '')
          .toString(),
      usuarioProponenteId: (json['usuario_proponente_id'] ??
              json['proponente_id'] ??
              json['usuarioProponenteId'] ??
              '')
          .toString(),
      usuarioReceptorId: json['usuario_receptor_id']?.toString() ??
          json['receptor_id']?.toString() ??
          json['usuarioReceptorId']?.toString(),
      modalidad: (json['modalidad'] ?? json['tipo_pago'] ?? 'trueque')
          .toString()
          .toLowerCase(),
      propuesta: (json['propuesta'] ??
              json['mensaje'] ??
              json['descripcion'] ??
              '')
          .toString(),
      montoEfectivo: monto,
      bienOfrecidoId: json['bien_ofrecido_id']?.toString() ??
          json['bienOfrecidoId']?.toString(),
      bienOfrecidoTitulo: json['bien_ofrecido_titulo']?.toString() ??
          json['bienOfrecidoTitulo']?.toString(),
      estado: (json['estado'] ?? json['status'] ?? 'pendiente_aceptacion')
          .toString(),
      fechaCreacion: fecha,
      fechaActualizacion: fechaUpdate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offer_id': offerId,
      'usuario_proponente_id': usuarioProponenteId,
      'usuario_receptor_id': usuarioReceptorId,
      'modalidad': modalidad,
      'propuesta': propuesta,
      if (montoEfectivo != null) 'monto_efectivo': montoEfectivo,
      if (bienOfrecidoId != null) 'bien_ofrecido_id': bienOfrecidoId,
      if (bienOfrecidoTitulo != null)
        'bien_ofrecido_titulo': bienOfrecidoTitulo,
      'estado': estado,
      'created_at': fechaCreacion.toIso8601String(),
      'updated_at': fechaActualizacion?.toIso8601String(),
    };
  }
}
