import '../models/exchange_entity.dart';

/// Modalidades de acuerdo soportadas por Swappia (Patrón Factory).
enum ExchangePaymentType {
  dinero,
  trueque,
  mixto;

  static ExchangePaymentType parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'dinero':
      case 'efectivo':
      case 'cash':
        return ExchangePaymentType.dinero;
      case 'trueque':
      case 'barter':
        return ExchangePaymentType.trueque;
      case 'mixto':
      case 'mixed':
        return ExchangePaymentType.mixto;
      default:
        throw ArgumentError(
          'Modalidad de intercambio no soportada: "$raw". Usa dinero, trueque o mixto.',
        );
    }
  }

  String get dbValue => name;
}

/// Clase derivada para acuerdos pagados en dinero en efectivo.
class CashExchange extends ExchangeEntity {
  const CashExchange({
    required super.id,
    required super.offerId,
    required super.usuarioProponenteId,
    super.usuarioReceptorId,
    required super.propuesta,
    super.montoEfectivo,
    super.estado = 'pendiente_aceptacion',
    required super.fechaCreacion,
    super.fechaActualizacion,
  }) : super(modalidad: 'dinero');

  bool get esValido => (montoEfectivo ?? 0) >= 0 && propuesta.trim().isNotEmpty;

  String get resumenAcuerdo => montoEfectivo != null && montoEfectivo! > 0
      ? 'Pago en efectivo de \$${montoEfectivo!.toStringAsFixed(2)} MXN'
      : 'Acuerdo en efectivo';
}

/// Clase derivada para acuerdos de trueque puro (intercambio de bienes o servicios).
class BarterExchange extends ExchangeEntity {
  const BarterExchange({
    required super.id,
    required super.offerId,
    required super.usuarioProponenteId,
    super.usuarioReceptorId,
    required super.propuesta,
    super.bienOfrecidoId,
    super.bienOfrecidoTitulo,
    super.estado = 'pendiente_aceptacion',
    required super.fechaCreacion,
    super.fechaActualizacion,
  }) : super(modalidad: 'trueque');

  bool get esValido =>
      propuesta.trim().isNotEmpty || (bienOfrecidoTitulo?.isNotEmpty ?? false);

  String get resumenAcuerdo {
    if (bienOfrecidoTitulo != null && bienOfrecidoTitulo!.trim().isNotEmpty) {
      return 'Trueque por "$bienOfrecidoTitulo"';
    }
    return 'Trueque directo entre vecinos';
  }
}

/// Clase derivada para acuerdos mixtos (combinación de bien/servicio + efectivo).
class MixedExchange extends ExchangeEntity {
  const MixedExchange({
    required super.id,
    required super.offerId,
    required super.usuarioProponenteId,
    super.usuarioReceptorId,
    required super.propuesta,
    super.montoEfectivo,
    super.bienOfrecidoId,
    super.bienOfrecidoTitulo,
    super.estado = 'pendiente_aceptacion',
    required super.fechaCreacion,
    super.fechaActualizacion,
  }) : super(modalidad: 'mixto');

  bool get esValido => (montoEfectivo ?? 0) >= 0 && propuesta.trim().isNotEmpty;

  String get resumenAcuerdo {
    final itemPart = (bienOfrecidoTitulo != null && bienOfrecidoTitulo!.isNotEmpty)
        ? '"$bienOfrecidoTitulo"'
        : 'bien/servicio';
    final cashPart = (montoEfectivo != null && montoEfectivo! > 0)
        ? ' + \$${montoEfectivo!.toStringAsFixed(2)} MXN'
        : '';
    return 'Acuerdo mixto ($itemPart$cashPart)';
  }
}

/// Patrón Factory para instanciar de forma extensible cualquier modalidad
/// de intercambio vecinal (Dinero, Trueque o Mixto).
abstract class ExchangeFactory {
  static ExchangeEntity create({
    required String modalidad,
    required String id,
    required String offerId,
    required String usuarioProponenteId,
    String? usuarioReceptorId,
    required String propuesta,
    double? montoEfectivo,
    String? bienOfrecidoId,
    String? bienOfrecidoTitulo,
    String estado = 'pendiente_aceptacion',
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    final type = ExchangePaymentType.parse(modalidad);
    return createFromType(
      type: type,
      id: id,
      offerId: offerId,
      usuarioProponenteId: usuarioProponenteId,
      usuarioReceptorId: usuarioReceptorId,
      propuesta: propuesta,
      montoEfectivo: montoEfectivo,
      bienOfrecidoId: bienOfrecidoId,
      bienOfrecidoTitulo: bienOfrecidoTitulo,
      estado: estado,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
    );
  }

  static ExchangeEntity createFromType({
    required ExchangePaymentType type,
    required String id,
    required String offerId,
    required String usuarioProponenteId,
    String? usuarioReceptorId,
    required String propuesta,
    double? montoEfectivo,
    String? bienOfrecidoId,
    String? bienOfrecidoTitulo,
    String estado = 'pendiente_aceptacion',
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    if (montoEfectivo != null && montoEfectivo < 0) {
      throw ArgumentError('El monto en efectivo no puede ser negativo.');
    }

    final created = fechaCreacion ?? DateTime.now();

    switch (type) {
      case ExchangePaymentType.dinero:
        return CashExchange(
          id: id,
          offerId: offerId,
          usuarioProponenteId: usuarioProponenteId,
          usuarioReceptorId: usuarioReceptorId,
          propuesta: propuesta,
          montoEfectivo: montoEfectivo,
          estado: estado,
          fechaCreacion: created,
          fechaActualizacion: fechaActualizacion,
        );
      case ExchangePaymentType.trueque:
        return BarterExchange(
          id: id,
          offerId: offerId,
          usuarioProponenteId: usuarioProponenteId,
          usuarioReceptorId: usuarioReceptorId,
          propuesta: propuesta,
          bienOfrecidoId: bienOfrecidoId,
          bienOfrecidoTitulo: bienOfrecidoTitulo,
          estado: estado,
          fechaCreacion: created,
          fechaActualizacion: fechaActualizacion,
        );
      case ExchangePaymentType.mixto:
        return MixedExchange(
          id: id,
          offerId: offerId,
          usuarioProponenteId: usuarioProponenteId,
          usuarioReceptorId: usuarioReceptorId,
          propuesta: propuesta,
          montoEfectivo: montoEfectivo,
          bienOfrecidoId: bienOfrecidoId,
          bienOfrecidoTitulo: bienOfrecidoTitulo,
          estado: estado,
          fechaCreacion: created,
          fechaActualizacion: fechaActualizacion,
        );
    }
  }
}
