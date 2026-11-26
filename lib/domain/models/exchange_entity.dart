/// Entidad de dominio que representa una propuesta de intercambio entre vecinos.
class ExchangeEntity {
  final String id;
  final String offerId;
  final String usuarioProponenteId;
  final String? usuarioReceptorId;
  final String propuesta;
  final String estado; // 'pendiente_aceptacion', 'aceptada', 'rechazada', 'cancelada'
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  const ExchangeEntity({
    required this.id,
    required this.offerId,
    required this.usuarioProponenteId,
    this.usuarioReceptorId,
    required this.propuesta,
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
    String? propuesta,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return ExchangeEntity(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      usuarioProponenteId: usuarioProponenteId ?? this.usuarioProponenteId,
      usuarioReceptorId: usuarioReceptorId ?? this.usuarioReceptorId,
      propuesta: propuesta ?? this.propuesta,
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
          propuesta == other.propuesta &&
          estado == other.estado;

  @override
  int get hashCode => Object.hash(
        id,
        offerId,
        usuarioProponenteId,
        usuarioReceptorId,
        propuesta,
        estado,
      );

  @override
  String toString() {
    return 'ExchangeEntity(id: $id, offerId: $offerId, proponente: $usuarioProponenteId, estado: $estado)';
  }
}
