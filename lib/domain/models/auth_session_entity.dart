import 'user_entity.dart';

class AuthSessionEntity {
  final String token;
  final UserEntity user;
  final DateTime createdAt;

  const AuthSessionEntity({
    required this.token,
    required this.user,
    required this.createdAt,
  });

  bool get isValid => token.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSessionEntity &&
          runtimeType == other.runtimeType &&
          token == other.token &&
          user == other.user;

  @override
  int get hashCode => Object.hash(token, user);
}
