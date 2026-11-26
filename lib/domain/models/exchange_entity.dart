/// Entidad de dominio que representa una propuesta de intercambio entre vecinos.
class ExchangeEntity {
  final String id;
  final String offerId;
  final String usuarioProponenteId;
  final String? usuarioReceptorId;
  final String modalidad; // 'trueque', 'dinero', 'mixto'
  final String propuesta;
  final double? montoEfectivo;
  final String? bienOfrecidoId;
  final String? bienOfrecidoTitulo;
  final String estado; // 'pendiente_aceptacion', 'aceptada', 'rechazada', 'cancelada'
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  const ExchangeEntity({
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

  bool get esPendiente =>
      estado.toLowerCase() == 'pendiente_aceptacion' ||
      estado.toLowerCase() == 'pendiente' ||
      estado.toLowerCase() == 'en_propuesta';

  bool get esAceptada => estado.toLowerCase() == 'aceptada';
  bool get esRechazada => estado.toLowerCase() == 'rechazada';

  bool get estaAceptada => esAceptada;
  bool get estaEnPropuesta => esPendiente;

  ExchangeEntity copyWith({
    String? id,
    String? offerId,
    String? usuarioProponenteId,
    String? usuarioReceptorId,
    String? modalidad,
    String? propuesta,
    double? montoEfectivo,
    String? bienOfrecidoId,
    String? bienOfrecidoTitulo,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return ExchangeEntity(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      usuarioProponenteId: usuarioProponenteId ?? this.usuarioProponenteId,
      usuarioReceptorId: usuarioReceptorId ?? this.usuarioReceptorId,
      modalidad: modalidad ?? this.modalidad,
      propuesta: propuesta ?? this.propuesta,
      montoEfectivo: montoEfectivo ?? this.montoEfectivo,
      bienOfrecidoId: bienOfrecidoId ?? this.bienOfrecidoId,
      bienOfrecidoTitulo: bienOfrecidoTitulo ?? this.bienOfrecidoTitulo,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          offerId == other.offerId &&
          usuarioProponenteId == other.usuarioProponenteId &&
          usuarioReceptorId == other.usuarioReceptorId &&
          modalidad == other.modalidad &&
          propuesta == other.propuesta &&
          montoEfectivo == other.montoEfectivo &&
          bienOfrecidoId == other.bienOfrecidoId &&
          bienOfrecidoTitulo == other.bienOfrecidoTitulo &&
          estado == other.estado;

  @override
  int get hashCode => Object.hash(
        id,
        offerId,
        usuarioProponenteId,
        usuarioReceptorId,
        modalidad,
        propuesta,
        montoEfectivo,
        bienOfrecidoId,
        bienOfrecidoTitulo,
        estado,
      );

  @override
  String toString() {
    return 'ExchangeEntity(id: $id, offerId: $offerId, modalidad: $modalidad, proponente: $usuarioProponenteId, estado: $estado)';
  }
}
