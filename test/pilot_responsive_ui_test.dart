import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swappia_app/core/theme/app_theme.dart';
import 'package:swappia_app/data/datasources/local/auth_local_datasource.dart';
import 'package:swappia_app/data/datasources/remote/auth_remote_datasource.dart';
import 'package:swappia_app/data/repositories/auth_repository_impl.dart';
import 'package:swappia_app/data/repositories/exchange_repository_impl.dart';
import 'package:swappia_app/data/repositories/offer_repository_impl.dart';
import 'package:swappia_app/domain/models/exchange_entity.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/domain/usecases/get_session_usecase.dart';
import 'package:swappia_app/domain/usecases/login_usecase.dart';
import 'package:swappia_app/domain/usecases/propose_exchange_usecase.dart';
import 'package:swappia_app/domain/usecases/publish_offer_usecase.dart';
import 'package:swappia_app/domain/usecases/register_usecase.dart';
import 'package:swappia_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:swappia_app/presentation/viewmodels/create_offer_viewmodel.dart';
import 'package:swappia_app/presentation/viewmodels/exchange_viewmodel.dart';
import 'package:swappia_app/presentation/viewmodels/feed_viewmodel.dart';
import 'package:swappia_app/presentation/views/auth/login_view.dart';
import 'package:swappia_app/presentation/views/auth/register_view.dart';
import 'package:swappia_app/presentation/views/exchange/create_offer_view.dart';
import 'package:swappia_app/presentation/views/exchange/exchange_confirmation_view.dart';
import 'package:swappia_app/presentation/views/exchange/rate_user_view.dart';
import 'package:swappia_app/presentation/views/feed/feed_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void setSmallAndroidScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
  }

  group('Issue #25: Pruebas de responsividad y cero RenderFlex overflow (360px)',
      () {
    testWidgets('LoginView y RegisterView sin overflow en pantalla angosta',
        (WidgetTester tester) async {
      setSmallAndroidScreen(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const LoginView()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const RegisterView()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('FeedView (con filtros abiertos) y CreateOfferView sin overflow',
        (WidgetTester tester) async {
      setSmallAndroidScreen(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

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

      final offerRepo = OfferRepositoryImpl();
      final exchangeRepo = ExchangeRepositoryImpl();
      final feedVM = FeedViewModel(offerRepository: offerRepo);
      await feedVM.loadOffers();
      final createVM = CreateOfferViewModel(
        publishOfferUseCase: PublishOfferUseCase(offerRepo),
      );
      final exchangeVM = ExchangeViewModel(
        proposeExchangeUseCase: ProposeExchangeUseCase(
          exchangeRepository: exchangeRepo,
          offerRepository: offerRepo,
        ),
        exchangeRepository: exchangeRepo,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
            ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
            ChangeNotifierProvider<CreateOfferViewModel>.value(value: createVM),
            ChangeNotifierProvider<ExchangeViewModel>.value(value: exchangeVM),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FeedView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feed_toggle_filters_button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Navegar por las 4 pestañas de la barra inferior sin overflow
      for (final navKey in const [
        Key('nav_my_offers'),
        Key('nav_exchanges'),
        Key('nav_profile'),
        Key('nav_explore'),
      ]) {
        await tester.tap(find.byKey(navKey));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      // Publicar oferta en CreateOfferView debe sincronizarse de inmediato en FeedViewModel
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
            ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
            ChangeNotifierProvider<CreateOfferViewModel>.value(value: createVM),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CreateOfferView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(
          find.byKey(const Key('offer_title_field')), 'Oferta Nueva Sincronizada');
      createVM.setCategoria('Otro');
      await tester.enterText(
          find.byKey(const Key('offer_description_field')), 'Descripción de prueba');
      await tester.enterText(
          find.byKey(const Key('offer_photo_field')), 'foto.jpg');
      createVM.setColoniaComunidad('Independencia');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('submit_offer_button')));
      await tester.tap(find.byKey(const Key('submit_offer_button')));
      await tester.pumpAndSettle();

      expect(
        feedVM.allOffers.any((o) => o.titulo == 'Oferta Nueva Sincronizada'),
        isTrue,
      );
    });

    testWidgets('ExchangeConfirmationView y RateUserView sin overflow',
        (WidgetTester tester) async {
      setSmallAndroidScreen(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      const offer = OfferEntity(
        id: 'off-p1',
        usuarioId: 'usr-2',
        titulo: 'Servicio de Electricista Residencial en Dolores Hidalgo',
        descripcion: 'Instalación completa.',
        categoria: 'Electricidad',
        coloniaComunidad: 'Fraccionamiento Cuna de la Independencia',
        fotoUrl: '',
        modalidad: 'mixto',
      );
      final proposal = ExchangeEntity(
        id: 'exc-p1',
        offerId: 'off-p1',
        usuarioProponenteId: 'usr-1',
        modalidad: 'mixto',
        propuesta: 'Herramienta y diferencia en efectivo',
        montoEfectivo: 100,
        fechaCreacion: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExchangeConfirmationView(offer: offer, proposal: proposal),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const RateUserView(
            targetUserId: 'usr-2',
            targetUserName: 'Vecino Ejemplo con Nombre Largo',
            offerTitle: 'Servicio de Electricista Residencial',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
