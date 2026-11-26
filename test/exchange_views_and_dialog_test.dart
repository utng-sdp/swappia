import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/core/theme/app_theme.dart';
import 'package:swappia_app/domain/models/exchange_entity.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/presentation/views/exchange/exchange_confirmation_view.dart';
import 'package:swappia_app/presentation/views/exchange/propose_exchange_dialog.dart';
import 'package:swappia_app/presentation/views/exchange/rate_user_view.dart';

void main() {
  const targetOffer = OfferEntity(
    id: 'off-10',
    usuarioId: 'usr-receptor',
    titulo: 'Reparación de Plomería Residencial',
    descripcion: 'Instalación y reparación de tubería.',
    categoria: 'Servicios u Oficios',
    coloniaComunidad: 'Centro',
    fotoUrl: '',
    modalidad: 'mixto',
    precioEstimado: 250.0,
  );

  const ownOffer = OfferEntity(
    id: 'off-own-1',
    usuarioId: 'usr-proponente',
    titulo: 'Juego de Llaves Españolas',
    descripcion: 'Juego completo de herramientas.',
    categoria: 'Herramientas y Maquinaria',
    coloniaComunidad: 'Colonia Lindavista',
    fotoUrl: '',
  );

  group('Issue #19: ProposeExchangeDialog Widget Tests', () {
    testWidgets('Captura modalidad de pago, bien propio, monto y nota',
        (WidgetTester tester) async {
      ProposeExchangeSubmission? captured;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ProposeExchangeDialog.show(
                    context,
                    targetOffer: targetOffer,
                    userOffers: const [ownOffer],
                    onSubmit: (submission) async {
                      captured = submission;
                    },
                  );
                },
                child: const Text('Abrir modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir modal'));
      await tester.pumpAndSettle();

      // Seleccionar modalidad Mixto
      await tester.tap(find.byKey(const Key('modality_chip_mixto')));
      await tester.pumpAndSettle();

      // Seleccionar bien propio
      await tester.tap(find.byKey(const Key('own_offer_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Juego de Llaves Españolas').last);
      await tester.pumpAndSettle();

      // Escribir monto y nota
      await tester.enterText(
          find.byKey(const Key('proposal_amount_field')), '150');
      await tester.enterText(
        find.byKey(const Key('proposal_input_field')),
        'Te doy las llaves más 150 pesos en efectivo.',
      );

      await tester.ensureVisible(find.byKey(const Key('confirm_proposal_button')));
      await tester.tap(find.byKey(const Key('confirm_proposal_button')));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.modalidad, 'mixto');
      expect(captured!.montoEfectivo, 150.0);
      expect(captured!.bienOfrecidoId, 'off-own-1');
      expect(captured!.bienOfrecidoTitulo, 'Juego de Llaves Españolas');
      expect(
        captured!.propuesta,
        'Te doy las llaves más 150 pesos en efectivo.',
      );
    });
  });

  group('Issue #22: ExchangeConfirmationView y RateUserView', () {
    testWidgets('ExchangeConfirmationView acepta acuerdo y habilita calificar',
        (WidgetTester tester) async {
      bool accepted = false;
      final proposal = ExchangeEntity(
        id: 'exc-conf-1',
        offerId: targetOffer.id,
        usuarioProponenteId: 'usr-proponente',
        usuarioReceptorId: targetOffer.usuarioId,
        modalidad: 'mixto',
        propuesta: 'Llaves españolas + 150 MXN',
        montoEfectivo: 150.0,
        bienOfrecidoTitulo: 'Juego de Llaves Españolas',
        estado: 'pendiente_aceptacion',
        fechaCreacion: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExchangeConfirmationView(
            offer: targetOffer,
            proposal: proposal,
            counterpartName: 'Don Pedro',
            onAccept: () async {
              accepted = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pendiente de Confirmación'), findsOneWidget);
      expect(find.text('Mixto (Trueque + Efectivo)'), findsOneWidget);
      expect(find.byKey(const Key('confirm_agreement_button')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('confirm_agreement_button')));
      await tester.tap(find.byKey(const Key('confirm_agreement_button')));
      await tester.pumpAndSettle();

      expect(accepted, isTrue);
      expect(find.text('Acuerdo Confirmado'), findsOneWidget);
      expect(find.byKey(const Key('go_to_rate_user_button')), findsOneWidget);
    });

    testWidgets('RateUserView selecciona estrellas, envía reseña y muestra gracias',
        (WidgetTester tester) async {
      double? sentRating;
      String? sentComment;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: RateUserView(
            targetUserId: 'usr-receptor',
            targetUserName: 'Doña Lupita',
            offerTitle: targetOffer.titulo,
            onSubmitRating: (rating, comment) async {
              sentRating = rating;
              sentComment = comment;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('rate_view_star_4')));
      await tester.pumpAndSettle();
      expect(find.text('Muy buena experiencia (4/5)'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('rate_view_comment_field')),
        'Excelente atención y puntualidad',
      );

      await tester.ensureVisible(find.byKey(const Key('rate_view_submit_button')));
      await tester.tap(find.byKey(const Key('rate_view_submit_button')));
      await tester.pumpAndSettle();

      expect(sentRating, 4.0);
      expect(sentComment, 'Excelente atención y puntualidad');
      expect(find.byKey(const Key('rate_user_thank_you_view')), findsOneWidget);
      expect(find.text('¡Gracias por tu calificación!'), findsOneWidget);
    });
  });
}
