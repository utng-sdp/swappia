class UserEntity {
  final String id;
  final String nombre;
  final String coloniaComunidad;
  final String telefono;
  final double calificacionAcumulada;
  final int totalCalificaciones;
  final String? fotoUrl;
  final DateTime? fechaRegistro;

  const UserEntity({
    required this.id,
    required this.nombre,
    required this.coloniaComunidad,
    required this.telefono,
    this.calificacionAcumulada = 0.0,
    this.totalCalificaciones = 0,
    this.fotoUrl,
    this.fechaRegistro,
  });

  bool get tieneNombreValido => nombre.trim().isNotEmpty;

  bool get tieneTelefonoValido {
    final digitos = telefono.replaceAll(RegExp(r'\D'), '');
    return digitos.length == 10;
  }

  bool get tienePerfilCompleto =>
      tieneNombreValido &&
      coloniaComunidad.trim().isNotEmpty &&
      tieneTelefonoValido;

  bool get tieneCalificaciones => totalCalificaciones > 0;

  bool get esVecinoConfiable =>
      totalCalificaciones >= 3 && calificacionAcumulada >= 4.0;

  String get reputacionLegible {
    if (!tieneCalificaciones) {
      return 'Nuevo en la comunidad';
    }
    return '${calificacionAcumulada.toStringAsFixed(1)} ★ ($totalCalificaciones)';
  }

  UserEntity copyWith({
    String? id,
    String? nombre,
    String? coloniaComunidad,
    String? telefono,
    double? calificacionAcumulada,
    int? totalCalificaciones,
    String? fotoUrl,
    DateTime? fechaRegistro,
  }) {
    return UserEntity(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      coloniaComunidad: coloniaComunidad ?? this.coloniaComunidad,
      telefono: telefono ?? this.telefono,
      calificacionAcumulada:
          calificacionAcumulada ?? this.calificacionAcumulada,
      totalCalificaciones: totalCalificaciones ?? this.totalCalificaciones,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nombre == other.nombre &&
          coloniaComunidad == other.coloniaComunidad &&
          telefono == other.telefono &&
          calificacionAcumulada == other.calificacionAcumulada &&
          totalCalificaciones == other.totalCalificaciones &&
          fotoUrl == other.fotoUrl &&
          fechaRegistro == other.fechaRegistro;

  @override
  int get hashCode => Object.hash(
        id,
        nombre,
        coloniaComunidad,
        telefono,
        calificacionAcumulada,
        totalCalificaciones,
        fotoUrl,
        fechaRegistro,
      );

  @override
  String toString() {
    return 'UserEntity(id: $id, nombre: $nombre, coloniaComunidad: $coloniaComunidad, telefono: $telefono, calificacionAcumulada: $calificacionAcumulada, totalCalificaciones: $totalCalificaciones)';
  }
}
