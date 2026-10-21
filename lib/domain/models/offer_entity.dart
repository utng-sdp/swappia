class OfferEntity {
  final String id;
  final String usuarioId;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String coloniaComunidad;
  final String fotoUrl;
  final String modalidad; // 'trueque', 'dinero', 'mixto'
  final String? loQueBusca;
  final double? precioEstimado;
  final DateTime? fechaPublicacion;
  final bool activa;

  const OfferEntity({
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

  bool get tieneTituloValido => titulo.trim().length >= 3;
  bool get tieneDescripcionValida => descripcion.trim().length >= 5;
  bool get tieneFoto => fotoUrl.trim().isNotEmpty;
  bool get esTruequePuro => modalidad.toLowerCase() == 'trueque';
  bool get esMixto => modalidad.toLowerCase() == 'mixto';
  bool get esDinero => modalidad.toLowerCase() == 'dinero';

  OfferEntity copyWith({
    String? id,
    String? usuarioId,
    String? titulo,
    String? descripcion,
    String? categoria,
    String? coloniaComunidad,
    String? fotoUrl,
    String? modalidad,
    String? loQueBusca,
    double? precioEstimado,
    DateTime? fechaPublicacion,
    bool? activa,
  }) {
    return OfferEntity(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      coloniaComunidad: coloniaComunidad ?? this.coloniaComunidad,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      modalidad: modalidad ?? this.modalidad,
      loQueBusca: loQueBusca ?? this.loQueBusca,
      precioEstimado: precioEstimado ?? this.precioEstimado,
      fechaPublicacion: fechaPublicacion ?? this.fechaPublicacion,
      activa: activa ?? this.activa,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          usuarioId == other.usuarioId &&
          titulo == other.titulo &&
          descripcion == other.descripcion &&
          categoria == other.categoria &&
          coloniaComunidad == other.coloniaComunidad &&
          fotoUrl == other.fotoUrl &&
          modalidad == other.modalidad &&
          loQueBusca == other.loQueBusca &&
          precioEstimado == other.precioEstimado &&
          fechaPublicacion == other.fechaPublicacion &&
          activa == other.activa;

  @override
  int get hashCode => Object.hash(
        id,
        usuarioId,
        titulo,
        descripcion,
        categoria,
        coloniaComunidad,
        fotoUrl,
        modalidad,
        loQueBusca,
        precioEstimado,
        fechaPublicacion,
        activa,
      );

  @override
  String toString() {
    return 'OfferEntity(id: $id, titulo: $titulo, modalidad: $modalidad, colonia: $coloniaComunidad)';
  }
}
