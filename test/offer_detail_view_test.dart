import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/presentation/views/exchange/offer_detail_view.dart';

void main() {
  const testOffer = OfferEntity(
    id: 'off-test-100',
    usuarioId: 'usr-vecino-1',
    titulo: 'Servicio de Reparación Eléctrica',
    descripcion:
        'Instalación de apagadores, cableado y revisión de centros de carga.',
    categoria: 'Electricidad',
    coloniaComunidad: 'Colonia La Florida',
    fotoUrl: 'https://ejemplo.com/foto.jpg',
    modalidad: 'mixto',
    loQueBusca: 'Pintura vinílica o despensa',
    precioEstimado: 150.0,
    activa: true,
  );

  Widget createWidgetUnderTest({
    OfferEntity? offer,
    Future<void> Function(String)? onPropose,
  }) {
    return MaterialApp(
      home: OfferDetailView(
        offer: offer ?? testOffer,
        onProposeExchange: onPropose,
      ),
    );
  }

  group('OfferDetailView - Visualización y Acciones', () {
    testWidgets('Muestra información completa de la oferta',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Título y categoría
      expect(find.byKey(const Key('offer_detail_title')), findsOneWidget);
      expect(find.text('Servicio de Reparación Eléctrica'), findsOneWidget);
      expect(find.text('Electricidad'), findsOneWidget);

      // Colonia
      expect(find.byKey(const Key('offer_detail_colonia')), findsOneWidget);
      expect(find.text('Colonia La Florida'), findsOneWidget);

      // Descripción
      expect(find.byKey(const Key('offer_detail_description')), findsOneWidget);
      expect(
        find.text(
            'Instalación de apagadores, cableado y revisión de centros de carga.'),
        findsOneWidget,
      );

      // Lo que busca a cambio y precio estimado
      expect(
          find.byKey(const Key('offer_detail_lo_que_busca')), findsOneWidget);
      expect(find.text('Pintura vinílica o despensa'), findsOneWidget);
      expect(find.byKey(const Key('offer_detail_price')), findsOneWidget);
      expect(find.text('\$150.00 MXN'), findsOneWidget);

      // Botón principal
      expect(find.byKey(const Key('propose_exchange_button')), findsOneWidget);
      expect(find.text('Proponer Intercambio'), findsOneWidget);
    });

    testWidgets(
        'Al presionar Proponer Intercambio abre modal para enviar propuesta',
        (WidgetTester tester) async {
      String? sentProposal;

      await tester.pumpWidget(createWidgetUnderTest(
        onPropose: (text) async {
          sentProposal = text;
        },
      ));
      await tester.pumpAndSettle();

      // Asegurar visibilidad con scroll dentro del SingleChildScrollView
      final proposeBtn = find.byKey(const Key('propose_exchange_button'));
      await tester.ensureVisible(proposeBtn);
      await tester.pumpAndSettle();

      // Pulsar botón de Proponer Intercambio
      await tester.tap(proposeBtn);
      await tester.pumpAndSettle();

      // Verificar que el modal se abrió
      expect(find.byKey(const Key('proposal_input_field')), findsOneWidget);
      expect(find.byKey(const Key('confirm_proposal_button')), findsOneWidget);

      // Ingresar propuesta
      await tester.enterText(
        find.byKey(const Key('proposal_input_field')),
        'Te ofrezco 2 botes de pintura blanca sellados a cambio del servicio.',
      );

      // Enviar propuesta
      await tester.tap(find.byKey(const Key('confirm_proposal_button')));
      await tester.pumpAndSettle();

      // Verificar que el callback fue invocado con el texto
      expect(
        sentProposal,
        'Te ofrezco 2 botes de pintura blanca sellados a cambio del servicio.',
      );
      expect(find.text('¡Propuesta de intercambio enviada al vecino con éxito!'),
          findsOneWidget);
    });

    testWidgets('Maneja navegación con paso de argumentos vía ModalRoute',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => Scaffold(
                body: ElevatedButton(
                  key: const Key('go_to_detail_btn'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      OfferDetailView.routeName,
                      arguments: testOffer,
                    );
                  },
                  child: const Text('Ir a detalle'),
                ),
              ),
          OfferDetailView.routeName: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments as OfferEntity?;
            return OfferDetailView(offer: args);
          },
        },
      ));
      await tester.pumpAndSettle();

      // Pulsar botón para navegar pasando argumentos
      await tester.tap(find.byKey(const Key('go_to_detail_btn')));
      await tester.pumpAndSettle();

      // Verificar que se visualiza el detalle con los datos del argumento
      expect(find.text('Servicio de Reparación Eléctrica'), findsOneWidget);
      expect(find.byKey(const Key('offer_detail_back_button')), findsOneWidget);

      // Presionar regresar
      await tester.tap(find.byKey(const Key('offer_detail_back_button')));
      await tester.pumpAndSettle();

      // Debe haber regresado a la pantalla anterior
      expect(find.byKey(const Key('go_to_detail_btn')), findsOneWidget);
    });
  });
}
