import '../models/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity?> getUserById(String id);
  Future<UserEntity?> getCurrentUser();
  Future<void> createUser(UserEntity user);
  Future<void> updateUser(UserEntity user);
  Future<List<UserEntity>> getUsersByColonia(String coloniaComunidad);
  Future<void> updateRating({
    required String userId,
    required double nuevaCalificacionAcumulada,
    required int nuevoTotalCalificaciones,
  });
}
