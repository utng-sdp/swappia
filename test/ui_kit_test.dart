import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/core/theme/app_colors.dart';
import 'package:swappia_app/core/theme/app_theme.dart';
import 'package:swappia_app/presentation/widgets/custom_button.dart';
import 'package:swappia_app/presentation/widgets/custom_text_field.dart';

void main() {
  group('AppTheme - Material 3 Theme System', () {
    test('Configuracion de tema claro (lightTheme) valida y completa', () {
      final light = AppTheme.lightTheme;
      expect(light.useMaterial3, isTrue);
      expect(light.brightness, Brightness.light);
      expect(light.colorScheme.primary, AppColors.primary);
      expect(light.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(light.appBarTheme.centerTitle, isTrue);
    });

    test('Configuracion de tema oscuro (darkTheme) valida y completa', () {
      final dark = AppTheme.darkTheme;
      expect(dark.useMaterial3, isTrue);
      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme.primary, AppColors.primaryLight);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(dark.appBarTheme.centerTitle, isTrue);
    });
  });

  group('CustomButton Widget Tests', () {
    testWidgets('Renderiza correctamente texto e icono en tema claro', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomButton(
              text: 'Proponer Trueque',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Proponer Trueque'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

      await tester.tap(find.byType(CustomButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('Renderiza y responde en tema oscuro sin errores visuales', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CustomButton(
              text: 'Boton Oscuro',
              variant: CustomButtonVariant.secondary,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Boton Oscuro'), findsOneWidget);
      await tester.tap(find.byType(CustomButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('Muestra CircularProgressIndicator y bloquea taps cuando isLoading es true', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomButton(
              text: 'Guardando',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Guardando'), findsNothing);

      await tester.tap(find.byType(CustomButton));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('Respeta estado deshabilitado cuando onPressed es null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CustomButton(
              text: 'Deshabilitado',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<CustomButton>(find.byType(CustomButton));
      expect(button.isEnabled, isFalse);
    });
  });

  group('CustomTextField Widget Tests', () {
    testWidgets('Renderiza label, hint y actualiza texto con onChanged', (tester) async {
      String enteredText = '';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomTextField(
              label: 'Colonia o Comunidad',
              hint: 'Ej. Lindavista o San Antonio',
              onChanged: (val) => enteredText = val,
            ),
          ),
        ),
      );

      expect(find.text('Colonia o Comunidad'), findsOneWidget);
      expect(find.text('Ej. Lindavista o San Antonio'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Centro');
      await tester.pump();
      expect(enteredText, 'Centro');
    });

    testWidgets('Alterna visibilidad de contrasena con icono de ojo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: CustomTextField(
              label: 'Contrasena',
              isPassword: true,
            ),
          ),
        ),
      );

      // Inicialmente oculto
      TextField textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap en icono para mostrar
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('Muestra mensaje de error cuando falla la validacion', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextField(
                label: 'Oficio',
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'El oficio es requerido';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('El oficio es requerido'), findsOneWidget);
    });
  });
}
