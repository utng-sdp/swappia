import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/core/theme/app_theme.dart';
import 'package:swappia_app/presentation/views/auth/login_view.dart';
import 'package:swappia_app/presentation/views/auth/register_view.dart';
import 'package:swappia_app/presentation/widgets/custom_button.dart';
import 'package:swappia_app/presentation/widgets/custom_text_field.dart';
import 'package:swappia_app/presentation/widgets/status_banner.dart';

void main() {
  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
  }

  group('LoginView Tests', () {
    testWidgets('Renderiza correctamente todos los elementos del login', (tester) async {
      setMobileScreen(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginView(),
        ),
      );

      expect(find.text('Swappia'), findsOneWidget);
      expect(find.text('Iniciar Sesion'), findsOneWidget);
      expect(find.text('Correo electronico'), findsOneWidget);
      expect(find.text('Contrasena'), findsOneWidget);
      expect(find.text('Registrate aqui'), findsOneWidget);
    });

    testWidgets('Muestra errores de validacion si los campos estan vacios', (tester) async {
      setMobileScreen(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginView(),
        ),
      );

      await tester.ensureVisible(find.byType(CustomButton));
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      expect(find.text('Por favor ingresa tu correo electronico'), findsOneWidget);
      expect(find.text('Por favor ingresa tu contrasena'), findsOneWidget);
    });

    testWidgets('Muestra StatusBanner cuando onLoginSubmit lanza error', (tester) async {
      setMobileScreen(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: LoginView(
            onLoginSubmit: (email, pass) async {
              throw Exception('Credenciales invalidas para el vecino');
            },
          ),
        ),
      );

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'vecino@dolores.com');
      await tester.enterText(textFields.at(1), '123456');
      await tester.pump();

      await tester.ensureVisible(find.byType(CustomButton));
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      expect(find.byType(StatusBanner), findsOneWidget);
      expect(find.text('Credenciales invalidas para el vecino'), findsOneWidget);
    });

    testWidgets('Dispara callback para navegar a registro', (tester) async {
      setMobileScreen(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      var navigated = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: LoginView(
            onNavigateToRegister: () => navigated = true,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Registrate aqui'));
      await tester.tap(find.text('Registrate aqui'));
      await tester.pump();
      expect(navigated, isTrue);
    });
  });

  group('RegisterView Tests', () {
    testWidgets('Renderiza correctamente todos los campos de registro vecinal', (tester) async {
      setMobileScreen(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RegisterView(),
        ),
      );

      expect(find.text('Crear Perfil Vecinal'), findsOneWidget);
      expect(find.text('Nombre completo'), findsOneWidget);
      expect(find.text('Telefono celular (10 digitos)'), findsOneWidget);
      expect(find.text('Correo electronico'), findsOneWidget);
      expect(find.text('Colonia o comunidad (Dolores Hidalgo)'), findsOneWidget);
      expect(find.text('Registrarme como Vecino'), findsOneWidget);
    });

    testWidgets('Valida telefono con longitud diferente a 10 digitos', (tester) async {
      setMobileScreen(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RegisterView(),
        ),
      );

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Carlos Samael');
      await tester.enterText(textFields.at(1), '418123');
      await tester.enterText(textFields.at(2), 'carlos@dolores.com');
      await tester.enterText(textFields.at(4), '123456');
      await tester.enterText(textFields.at(5), '123456');
      await tester.pump();

      await tester.ensureVisible(find.byType(CustomButton));
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      expect(find.text('El telefono debe tener exactamente 10 digitos'), findsOneWidget);
    });

    testWidgets('Valida coincidencia de contrasenas', (tester) async {
      setMobileScreen(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RegisterView(),
        ),
      );

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Carlos Samael');
      await tester.enterText(textFields.at(1), '4181234567');
      await tester.enterText(textFields.at(2), 'carlos@dolores.com');
      await tester.enterText(textFields.at(4), 'passwordA');
      await tester.enterText(textFields.at(5), 'passwordB');
      await tester.pump();

      await tester.ensureVisible(find.byType(CustomButton));
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      expect(find.text('Las contrasenas no coinciden'), findsOneWidget);
    });

    testWidgets('Dispara callback para regresar a login', (tester) async {
      setMobileScreen(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      var backToLogin = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: RegisterView(
            onNavigateToLogin: () => backToLogin = true,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Inicia sesion aqui'));
      await tester.tap(find.text('Inicia sesion aqui'));
      await tester.pump();
      expect(backToLogin, isTrue);
    });
  });
}