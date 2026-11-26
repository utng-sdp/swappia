/// Entidad de dominio que representa una calificación vecinal tras un intercambio.
class RatingEntity {
  final String id;
  final String evaluadorId;
  final String evaluadoId;
  final String? intercambioId;
  final int estrellas;
  final String? comentario;
  final DateTime fechaCreacion;

  const RatingEntity({
    required this.id,
    required this.evaluadorId,
    required this.evaluadoId,
    this.intercambioId,
    required this.estrellas,
    this.comentario,
    required this.fechaCreacion,
  });

  bool get esPuntuacionValida => estrellas >= 1 && estrellas <= 5;
  bool get esAutocalificacion => evaluadorId.trim() == evaluadoId.trim();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RatingEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          evaluadorId == other.evaluadorId &&
          evaluadoId == other.evaluadoId &&
          intercambioId == other.intercambioId &&
          estrellas == other.estrellas &&
          comentario == other.comentario;

  @override
  int get hashCode => Object.hash(
        id,
        evaluadorId,
        evaluadoId,
        intercambioId,
        estrellas,
        comentario,
      );
}
