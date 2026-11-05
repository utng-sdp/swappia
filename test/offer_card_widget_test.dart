import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/core/theme/app_theme.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/presentation/widgets/offer_card.dart';

void main() {
  const sampleOfferBien = OfferEntity(
    id: 'off-card-1',
    usuarioId: 'usr-don-pedro',
    titulo: 'Taladro Percutor DeWalt 800W',
    descripcion: 'Taladro percutor en caja original, incluye juego de brocas para concreto y madera.',
    categoria: 'Herramientas y Maquinaria',
    coloniaComunidad: 'Centro',
    fotoUrl: 'https://ejemplo.com/taladro.jpg',
    modalidad: 'trueque',
    loQueBusca: 'Pintura vinílica o despensa',
    activa: true,
  );

  const sampleOfferServicio = OfferEntity(
    id: 'off-card-2',
    usuarioId: 'usr-dona-lupita',
    titulo: 'Clases de Regularización de Matemáticas',
    descripcion: 'Asesorías personalizadas de álgebra y geometría para alumnos de secundaria.',
    categoria: 'Educación y Asesoría',
    coloniaComunidad: 'La Lindavista',
    fotoUrl: '',
    modalidad: 'mixto',
    precioEstimado: 120.0,
    activa: true,
  );

  const sampleOfferBusqueda = OfferEntity(
    id: 'off-card-3',
    usuarioId: 'usr-carlos-vecino',
    titulo: 'Busco Bicicleta Rodada 26 para traslado',
    descripcion: 'Necesito una bicicleta usada en condiciones mecánicas buenas para ir al trabajo.',
    categoria: 'Bienes',
    coloniaComunidad: 'Colonia La Florida',
    fotoUrl: '',
    modalidad: 'dinero',
    precioEstimado: 500.0,
    activa: true,
  );

  Widget createCardApp({
    required OfferEntity offer,
    VoidCallback? onTap,
    String? usuarioNombre,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: OfferCard(
            offer: offer,
            onTap: onTap,
            usuarioNombre: usuarioNombre,
          ),
        ),
      ),
    );
  }

  group('Issue #16: OfferCard Widget Tests', () {
    testWidgets('Criterio de Aceptación: Renderiza adecuadamente información, usuario y colonia',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCardApp(
        offer: sampleOfferBien,
        usuarioNombre: 'Don Pedro Gómez',
      ));
      await tester.pump();

      // Comprobar la tarjeta mediante su Key
      expect(find.byKey(const Key('offer_card_off-card-1')), findsOneWidget);

      // Título
      expect(find.byKey(const Key('offer_title_off-card-1')), findsOneWidget);
      expect(find.text('Taladro Percutor DeWalt 800W'), findsOneWidget);

      // Usuario
      expect(find.byKey(const Key('offer_user_off-card-1')), findsOneWidget);
      expect(find.text('Don Pedro Gómez'), findsOneWidget);

      // Colonia
      expect(find.byKey(const Key('offer_colonia_off-card-1')), findsOneWidget);
      expect(find.text('Centro'), findsOneWidget);

      // Acuerdo deseado
      expect(find.text('Intercambio: Pintura vinílica o despensa'), findsOneWidget);
    });

    testWidgets('Distintivo visual: Badges Ofrezco vs Busco y Bien vs Servicio',
        (WidgetTester tester) async {
      // 1. Probar bien ofertado
      await tester.pumpWidget(createCardApp(offer: sampleOfferBien));
      await tester.pump();

      expect(find.text('OFREZCO'), findsOneWidget);
      expect(find.text('Bien'), findsOneWidget);
      expect(find.text('Trueque'), findsOneWidget);

      // 2. Probar servicio ofertado
      await tester.pumpWidget(createCardApp(offer: sampleOfferServicio));
      await tester.pump();

      expect(find.text('OFREZCO'), findsOneWidget);
      expect(find.text('Servicio'), findsOneWidget);
      expect(find.text('Mixto'), findsOneWidget);
      expect(find.text('Ref: \$120.00 MXN'), findsOneWidget);

      // 3. Probar solicitud de búsqueda
      await tester.pumpWidget(createCardApp(offer: sampleOfferBusqueda));
      await tester.pump();

      expect(find.text('BUSCO'), findsOneWidget);
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('Ref: \$500.00 MXN'), findsOneWidget);
    });

    testWidgets('Dispara el callback onTap al presionar la tarjeta',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(createCardApp(
        offer: sampleOfferBien,
        onTap: () {
          tapped = true;
        },
      ));
      await tester.pump();

      final cardFinder = find.byKey(const Key('offer_card_off-card-1'));
      expect(cardFinder, findsOneWidget);

      await tester.tap(cardFinder);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('Maneja foto vacía mostrando placeholder temático sin lanzar excepciones',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCardApp(offer: sampleOfferServicio));
      await tester.pump();

      // Debe renderizar el icono de servicio en la miniatura
      expect(find.byIcon(Icons.handyman_rounded), findsOneWidget);
    });

    testWidgets('Soporta tema oscuro sin errores de contraste visual',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCardApp(
        offer: sampleOfferBien,
        brightness: Brightness.dark,
      ));
      await tester.pump();

      expect(find.byKey(const Key('offer_card_off-card-1')), findsOneWidget);
      expect(find.text('Taladro Percutor DeWalt 800W'), findsOneWidget);
      expect(find.text('Centro'), findsOneWidget);
    });
  });
}

