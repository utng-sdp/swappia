import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/data/datasources/remote/auth_remote_datasource.dart';
import 'package:swappia_app/data/models/user_model.dart';

void main() {
  group('SupabaseAuthRemoteDataSource & AuthRemoteDataSource Contract Tests', () {
    test('SupabaseAuthRemoteDataSource es una instancia válida de AuthRemoteDataSource', () {
      final remoteDataSource = SupabaseAuthRemoteDataSource();
      expect(remoteDataSource, isA<AuthRemoteDataSource>());
    });

    test('MockAuthRemoteDataSource implementa signInWithEmail y signUpWithEmail correctamente', () async {
      final mock = MockAuthRemoteDataSource();

      // Probar signInWithEmail
      final loginResult = await mock.signInWithEmail(
        email: 'pedro@swappia.mx',
        password: 'password123',
      );

      expect(loginResult['token'], isNotEmpty);
      expect(loginResult['user']['nombre'], 'Don Pedro Gómez');
      expect(loginResult['user']['colonia_comunidad'], 'La Lindavista');

      // Probar signUpWithEmail
      final registerResult = await mock.signUpWithEmail(
        email: 'nuevo_vecino@swappia.mx',
        password: 'password123',
        nombre: 'Carlos Artesano',
        coloniaComunidad: 'El Llanito',
        telefono: '4189998877',
      );

      expect(registerResult['token'], isNotEmpty);
      expect(registerResult['user']['nombre'], 'Carlos Artesano');
      expect(registerResult['user']['colonia_comunidad'], 'El Llanito');
      expect(registerResult['user']['telefono'], '4189998877');

      // Probar signOut
      expect(() async => await mock.signOut(), returnsNormally);
    });

    test('UserModel mapea correctamente la estructura de la tabla profiles de PostgreSQL', () {
      final postgresProfile = {
        'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'nombre': 'Juana María',
        'colonia_comunidad': 'La Posta',
        'telefono': '4181112233',
        'calificacion_acumulada': 4.9,
        'total_calificaciones': 15,
        'foto_url': 'https://supabase.co/storage/v1/object/public/avatars/juana.jpg',
        'fecha_registro': '2026-10-20T19:00:00.000Z',
      };

      final model = UserModel.fromJson(postgresProfile);

      expect(model.id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(model.nombre, 'Juana María');
      expect(model.coloniaComunidad, 'La Posta');
      expect(model.telefono, '4181112233');
      expect(model.calificacionAcumulada, 4.9);
      expect(model.totalCalificaciones, 15);
      expect(model.fotoUrl, isNotNull);
      expect(model.fechaRegistro, isNotNull);

      final entity = model.toEntity();
      expect(entity.tieneNombreValido, isTrue);
      expect(entity.tieneTelefonoValido, isTrue);
      expect(entity.tienePerfilCompleto, isTrue);
      expect(entity.esVecinoConfiable, isTrue);
      expect(entity.reputacionLegible, '4.9 ★ (15)');
    });
  });
}
