import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swappia_app/data/datasources/local/auth_local_datasource.dart';
import 'package:swappia_app/data/datasources/remote/auth_remote_datasource.dart';
import 'package:swappia_app/data/repositories/auth_repository_impl.dart';
import 'package:swappia_app/data/repositories/exchange_repository_impl.dart';
import 'package:swappia_app/data/repositories/offer_repository_impl.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/domain/usecases/get_session_usecase.dart';
import 'package:swappia_app/domain/usecases/login_usecase.dart';
import 'package:swappia_app/domain/usecases/propose_exchange_usecase.dart';
import 'package:swappia_app/domain/usecases/register_usecase.dart';
import 'package:swappia_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:swappia_app/presentation/viewmodels/exchange_viewmodel.dart';
import 'package:swappia_app/presentation/viewmodels/feed_viewmodel.dart';
import 'package:swappia_app/presentation/views/exchange/offer_detail_view.dart';
import 'package:swappia_app/presentation/widgets/offer_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Criterios de Aceptación: Registro de Propuesta y Cambio de Estado Visual a "En propuesta"', () {
    testWidgets(
        'Al enviar una propuesta desde OfferDetailView, la publicación cambia su estado visual a "En propuesta"',
        (WidgetTester tester) async {
      final offerRepo = OfferRepositoryImpl();
      final exchangeRepo = ExchangeRepositoryImpl();
      final proposeUseCase = ProposeExchangeUseCase(
        exchangeRepository: exchangeRepo,
        offerRepository: offerRepo,
      );

      final authRepo = AuthRepositoryImpl(
        remoteDataSource: MockAuthRemoteDataSource(),
        localDataSource: SharedPreferencesAuthLocalDataSource(),
      );
      final authVM = AuthViewModel(
        loginUseCase: LoginUseCase(authRepo),
        registerUseCase: RegisterUseCase(authRepo),
        getSessionUseCase: GetSessionUseCase(authRepo),
      );

      await tester.runAsync(() async {
        await authVM.login(
          emailOrPhone: 'pedro@swappia.mx',
          password: 'password123',
        );
      });

      final initialOffer = await offerRepo.publishOffer(
        const OfferEntity(
          id: 'offer-test-detalle',
          usuarioId: 'usr-vendedor-1',
          titulo: 'Compresor de Aire 25L',
          descripcion: 'Compresor de aire portátil con manguera incluida.',
          categoria: 'Herramientas y Maquinaria',
          coloniaComunidad: 'Centro',
          fotoUrl: '',
          modalidad: 'trueque',
          loQueBusca: 'Caja de herramientas o taladro',
          estado: 'disponible',
        ),
      );

      final exchangeVM = ExchangeViewModel(proposeExchangeUseCase: proposeUseCase);
      final feedVM = FeedViewModel(offerRepository: offerRepo);
      feedVM.addOffer(initialOffer);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
            ChangeNotifierProvider<ExchangeViewModel>.value(value: exchangeVM),
            ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
          ],
          child: MaterialApp(
            home: OfferDetailView(offer: initialOffer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Estado inicial: se visualiza como "Disponible"
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('En propuesta'), findsNothing);

      // 2. Pulsar botón "Proponer Intercambio"
      final proposeButton = find.byKey(const Key('propose_exchange_button'));
      await tester.ensureVisible(proposeButton);
      await tester.pumpAndSettle();
      await tester.tap(proposeButton);
      await tester.pumpAndSettle();

      // 3. Escribir propuesta en el modal
      expect(find.byKey(const Key('proposal_input_field')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('proposal_input_field')),
        'Te ofrezco mi esmeriladora angular de 4 pulgadas seminueva.',
      );

      // 4. Confirmar y enviar la propuesta
      await tester.tap(find.byKey(const Key('confirm_proposal_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // CRITERIO DE ACEPTACIÓN: La propuesta queda registrada
      final proposalsInRepo = await exchangeRepo.getProposalsForOffer('offer-test-detalle');
      expect(proposalsInRepo.length, 1);
      expect(proposalsInRepo.first.propuesta, 'Te ofrezco mi esmeriladora angular de 4 pulgadas seminueva.');
      expect(proposalsInRepo.first.estado, 'pendiente_aceptacion');

      // CRITERIO DE ACEPTACIÓN: La publicación cambia su estado visual a "En propuesta"
      expect(find.byKey(const Key('offer_detail_status_badge')), findsOneWidget);
      expect(find.text('En propuesta'), findsOneWidget);
      expect(find.text('Disponible'), findsNothing);
    });

    testWidgets('OfferCard muestra el distintivo visual "En propuesta" cuando la oferta está en propuesta',
        (WidgetTester tester) async {
      const offerEnPropuesta = OfferEntity(
        id: 'offer-card-test',
        usuarioId: 'usr-vecino',
        titulo: 'Podadora a Gasolina',
        descripcion: 'Excelente podadora',
        categoria: 'Herramientas',
        coloniaComunidad: 'Centro',
        fotoUrl: '',
        modalidad: 'trueque',
        estado: 'en_propuesta',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfferCard(offer: offerEnPropuesta),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // CRITERIO DE ACEPTACIÓN: Muestra el badge "En propuesta"
      expect(find.byKey(const Key('offer_status_badge_offer-card-test')), findsOneWidget);
      expect(find.text('En propuesta'), findsOneWidget);
    });
  });
}
