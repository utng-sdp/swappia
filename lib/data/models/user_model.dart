import '../../domain/models/user_entity.dart';

class UserModel {
  final String id;
  final String nombre;
  final String coloniaComunidad;
  final String telefono;
  final double calificacionAcumulada;
  final int totalCalificaciones;
  final String? fotoUrl;
  final DateTime? fechaRegistro;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.coloniaComunidad,
    required this.telefono,
    this.calificacionAcumulada = 0.0,
    this.totalCalificaciones = 0,
    this.fotoUrl,
    this.fechaRegistro,
  });

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      nombre: nombre,
      coloniaComunidad: coloniaComunidad,
      telefono: telefono,
      calificacionAcumulada: calificacionAcumulada,
      totalCalificaciones: totalCalificaciones,
      fotoUrl: fotoUrl,
      fechaRegistro: fechaRegistro,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      nombre: entity.nombre,
      coloniaComunidad: entity.coloniaComunidad,
      telefono: entity.telefono,
      calificacionAcumulada: entity.calificacionAcumulada,
      totalCalificaciones: entity.totalCalificaciones,
      fotoUrl: entity.fotoUrl,
      fechaRegistro: entity.fechaRegistro,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      coloniaComunidad:
          (json['colonia_comunidad'] ?? json['coloniaComunidad'] ?? '')
              .toString(),
      telefono: (json['telefono'] ?? '').toString(),
      calificacionAcumulada:
          (json['calificacion_acumulada'] as num?)?.toDouble() ??
              (json['calificacionAcumulada'] as num?)?.toDouble() ??
              0.0,
      totalCalificaciones:
          (json['total_calificaciones'] as num?)?.toInt() ??
              (json['totalCalificaciones'] as num?)?.toInt() ??
              0,
      fotoUrl: json['foto_url'] as String? ?? json['fotoUrl'] as String?,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'].toString())
          : (json['fechaRegistro'] != null
              ? DateTime.tryParse(json['fechaRegistro'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'colonia_comunidad': coloniaComunidad,
      'telefono': telefono,
      'calificacion_acumulada': calificacionAcumulada,
      'total_calificaciones': totalCalificaciones,
      if (fotoUrl != null) 'foto_url': fotoUrl,
      if (fechaRegistro != null)
        'fecha_registro': fechaRegistro!.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? nombre,
    String? coloniaComunidad,
    String? telefono,
    double? calificacionAcumulada,
    int? totalCalificaciones,
    String? fotoUrl,
    DateTime? fechaRegistro,
  }) {
    return UserModel(
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
      other is UserModel &&
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
    return 'UserModel(id: $id, nombre: $nombre, coloniaComunidad: $coloniaComunidad, telefono: $telefono, calificacionAcumulada: $calificacionAcumulada, totalCalificaciones: $totalCalificaciones)';
  }
}
