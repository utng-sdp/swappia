import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swappia_app/data/datasources/local/auth_local_datasource.dart';
import 'package:swappia_app/data/datasources/remote/auth_remote_datasource.dart';
import 'package:swappia_app/data/repositories/auth_repository_impl.dart';
import 'package:swappia_app/domain/usecases/get_session_usecase.dart';
import 'package:swappia_app/domain/usecases/login_usecase.dart';
import 'package:swappia_app/domain/usecases/register_usecase.dart';
import 'package:swappia_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:swappia_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestApp(AuthViewModel viewModel) {
    return SwappiaApp(authViewModel: viewModel);
  }

  testWidgets('Criterio de Aceptación: Al autenticarse con éxito, redirige automáticamente al Feed principal',
      (WidgetTester tester) async {
    final local = SharedPreferencesAuthLocalDataSource();
    final remote = MockAuthRemoteDataSource();
    final repo = AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);
    final viewModel = AuthViewModel(
      loginUseCase: LoginUseCase(repo),
      registerUseCase: RegisterUseCase(repo),
      getSessionUseCase: GetSessionUseCase(repo),
    );

    await tester.pumpWidget(createTestApp(viewModel));
    await tester.pumpAndSettle();

    // Comprobar que nos encontramos en la pantalla de Login
    expect(find.text('Swappia'), findsOneWidget);
    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);

    // Ingresar credenciales válidas
    await tester.enterText(find.byKey(const Key('login_email_field')), 'pedro@swappia.mx');
    await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');

    // Pulsar botón de inicio de sesión
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump(); // Inicia estado loading

    // Esperar a que se complete la llamada asíncrona y la redirección
    await tester.pumpAndSettle();

    // CRITERIO DE ACEPTACIÓN: La aplicación redirige de forma automática al Feed principal
    expect(find.text('Swappia Feed'), findsOneWidget);
    expect(find.byKey(const Key('feed_user_name')), findsOneWidget);
    expect(find.text('Don Pedro Gómez'), findsOneWidget);
    expect(find.text('La Lindavista'), findsWidgets);
    expect(find.text('Sesión Activa'), findsOneWidget);

    // Verificar que el token persistido se visualiza o se guardó correctamente
    expect(viewModel.token, isNotNull);
    final savedToken = await local.getToken();
    expect(savedToken, isNotNull);
    expect(savedToken, viewModel.token);
  });

  testWidgets('Formulario de Login muestra error al ingresar credenciales inválidas',
      (WidgetTester tester) async {
    final local = SharedPreferencesAuthLocalDataSource();
    final remote = MockAuthRemoteDataSource();
    final repo = AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);
    final viewModel = AuthViewModel(
      loginUseCase: LoginUseCase(repo),
      registerUseCase: RegisterUseCase(repo),
      getSessionUseCase: GetSessionUseCase(repo),
    );

    await tester.pumpWidget(createTestApp(viewModel));
    await tester.pumpAndSettle();

    // Ingresar credenciales inválidas
    await tester.enterText(find.byKey(const Key('login_email_field')), 'pedro@swappia.mx');
    await tester.enterText(find.byKey(const Key('login_password_field')), 'password_incorrecta');

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    // Debe permanecer en login y mostrar error
    expect(find.text('Swappia Feed'), findsNothing);
    expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
    expect(find.byKey(const Key('login_error_text')), findsOneWidget);
  });

  testWidgets('Flujo de Registro conecta al ViewModel y redirige automáticamente al Feed principal',
      (WidgetTester tester) async {
    final local = SharedPreferencesAuthLocalDataSource();
    final remote = MockAuthRemoteDataSource();
    final repo = AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);
    final viewModel = AuthViewModel(
      loginUseCase: LoginUseCase(repo),
      registerUseCase: RegisterUseCase(repo),
      getSessionUseCase: GetSessionUseCase(repo),
    );

    await tester.pumpWidget(createTestApp(viewModel));
    await tester.pumpAndSettle();

    // Navegar a la pantalla de Registro
    await tester.tap(find.byKey(const Key('goto_register_button')));
    await tester.pumpAndSettle();

    expect(find.text('Registro de Vecino'), findsOneWidget);

    // Llenar formulario de nuevo vecino
    await tester.enterText(find.byKey(const Key('register_nombre_field')), 'Doña Juanita Taller');
    await tester.enterText(find.byKey(const Key('register_colonia_field')), 'El Llanito');
    await tester.enterText(find.byKey(const Key('register_telefono_field')), '4181122334');
    await tester.enterText(find.byKey(const Key('register_email_field')), 'juanita@swappia.mx');
    await tester.enterText(find.byKey(const Key('register_password_field')), 'secret123');

    // Registrar
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    // Criterio de Aceptación: Redirige automáticamente al Feed
    expect(find.text('Swappia Feed'), findsOneWidget);
    expect(find.text('Doña Juanita Taller'), findsOneWidget);
    expect(find.text('El Llanito'), findsWidgets);
  });
}
