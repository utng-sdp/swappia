import '../models/user_entity.dart';
import '../repositories/user_repository.dart';

/// Caso de uso en la capa de dominio para procesar el envío de reseñas y calificaciones a vecinos.
/// Valida reglas de negocio:
/// 1. Calificación numérica válida entre 1.0 y 5.0 estrellas.
/// 2. Un usuario no puede calificarse a sí mismo.
/// 3. El usuario destino debe existir en el sistema.
/// 4. Recalcula el promedio acumulado ponderado y actualiza el contador de calificaciones.
class RateUserUseCase {
  final UserRepository _userRepository;

  RateUserUseCase(this._userRepository);

  /// Ejecuta la calificación de un vecino tras concretar o aceptar un intercambio.
  /// Retorna la entidad del usuario actualizado con su nuevo promedio y total.
  Future<UserEntity> execute({
    required String targetUserId,
    required String reviewerUserId,
    required double rating,
    String? comment,
  }) async {
    // 1. Validar que la calificación esté dentro del rango 1.0 - 5.0
    if (rating < 1.0 || rating > 5.0) {
      throw ArgumentError(
        'La calificación debe ser un valor entre 1.0 y 5.0 estrellas.',
      );
    }

    // 2. Validar que no sea autocalificación
    if (targetUserId.trim() == reviewerUserId.trim()) {
      throw StateError(
        'No puedes calificarte a ti mismo en un intercambio vecinal.',
      );
    }

    // 3. Obtener el usuario destino
    final targetUser = await _userRepository.getUserById(targetUserId.trim());
    if (targetUser == null) {
      throw StateError(
        'El usuario a calificar no fue encontrado en la comunidad.',
      );
    }

    // 4. Calcular el nuevo promedio ponderado
    final oldTotal = targetUser.totalCalificaciones;
    final oldAccumulated = targetUser.calificacionAcumulada;

    final newTotal = oldTotal + 1;
    // Nueva calificación ponderada
    final rawAverage = ((oldAccumulated * oldTotal) + rating) / newTotal;
    // Redondear a un decimal
    final newAverage = double.parse(rawAverage.toStringAsFixed(1));

    // 5. Persistir en repositorio
    await _userRepository.updateRating(
      userId: targetUserId.trim(),
      nuevaCalificacionAcumulada: newAverage,
      nuevoTotalCalificaciones: newTotal,
    );

    return targetUser.copyWith(
      calificacionAcumulada: newAverage,
      totalCalificaciones: newTotal,
    );
  }
}
