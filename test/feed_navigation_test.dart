import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swappia_app/data/datasources/local/auth_local_datasource.dart';
import 'package:swappia_app/data/datasources/remote/auth_remote_datasource.dart';
import 'package:swappia_app/data/repositories/auth_repository_impl.dart';
import 'package:swappia_app/data/repositories/offer_repository_impl.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/domain/usecases/get_session_usecase.dart';
import 'package:swappia_app/domain/usecases/login_usecase.dart';
import 'package:swappia_app/domain/usecases/register_usecase.dart';
import 'package:swappia_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:swappia_app/presentation/viewmodels/feed_viewmodel.dart';
import 'package:swappia_app/presentation/views/exchange/offer_detail_view.dart';
import 'package:swappia_app/presentation/views/feed/feed_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildFeedApp({
    required AuthViewModel authVM,
    required FeedViewModel feedVM,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
        ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
      ],
      child: MaterialApp(
        initialRoute: FeedView.routeName,
        routes: {
          FeedView.routeName: (context) => const FeedView(),
          OfferDetailView.routeName: (context) {
            final offer =
                ModalRoute.of(context)?.settings.arguments as OfferEntity?;
            return OfferDetailView(offer: offer);
          },
        },
      ),
    );
  }

  testWidgets(
      'Criterio de Aceptación: Al presionar sobre una tarjeta del Feed, se abre el detalle completo de la oferta seleccionada',
      (WidgetTester tester) async {
    final local = SharedPreferencesAuthLocalDataSource();
    final remote = MockAuthRemoteDataSource();
    final authRepo =
        AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);
    final authVM = AuthViewModel(
      loginUseCase: LoginUseCase(authRepo),
      registerUseCase: RegisterUseCase(authRepo),
      getSessionUseCase: GetSessionUseCase(authRepo),
    );

    // Iniciar sesión con usuario de prueba
    await authVM.login(
      emailOrPhone: 'pedro@swappia.mx',
      password: 'password123',
    );

    final offerRepo = OfferRepositoryImpl();
    await offerRepo.publishOffer(
      const OfferEntity(
        id: 'offer-123',
        usuarioId: 'usr-chema',
        titulo: 'Juego de Herramientas de Carpintería',
        descripcion:
            'Sierra, cepillo de madera y formones en excelente condición para proyectos en casa.',
        categoria: 'Herramientas y Maquinaria',
        coloniaComunidad: 'Centro',
        fotoUrl: 'https://ejemplo.com/herramientas.jpg',
        modalidad: 'trueque',
        loQueBusca: 'Fruta de temporada o asesoría',
      ),
    );

    final feedVM = FeedViewModel(
      offerRepository: offerRepo,
      debounceDuration: const Duration(milliseconds: 50),
    );

    await tester.pumpWidget(buildFeedApp(authVM: authVM, feedVM: feedVM));
    await tester.pumpAndSettle();

    // Comprobar que la tarjeta está visible en el Feed
    final cardFinder = find.byKey(const Key('offer_card_offer-123'));
    expect(cardFinder, findsOneWidget);
    expect(find.text('Juego de Herramientas de Carpintería'), findsOneWidget);

    // CRITERIO DE ACEPTACIÓN: Presionar sobre la tarjeta del Feed
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Comprobar que se abrió el detalle completo de la oferta seleccionada
    expect(find.text('Detalle de Publicación'), findsOneWidget);
    expect(find.byKey(const Key('offer_detail_title')), findsOneWidget);
    expect(find.text('Juego de Herramientas de Carpintería'), findsOneWidget);
    expect(find.byKey(const Key('offer_detail_description')), findsOneWidget);
    expect(
      find.text(
          'Sierra, cepillo de madera y formones en excelente condición para proyectos en casa.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('offer_detail_lo_que_busca')), findsOneWidget);
    expect(find.text('Fruta de temporada o asesoría'), findsOneWidget);
    expect(find.byKey(const Key('propose_exchange_button')), findsOneWidget);
  });

  testWidgets(
      'Barra de búsqueda con Debounce filtra las publicaciones en tiempo real',
      (WidgetTester tester) async {
    final local = SharedPreferencesAuthLocalDataSource();
    final remote = MockAuthRemoteDataSource();
    final authRepo =
        AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);
    final authVM = AuthViewModel(
      loginUseCase: LoginUseCase(authRepo),
      registerUseCase: RegisterUseCase(authRepo),
      getSessionUseCase: GetSessionUseCase(authRepo),
    );
    await authVM.login(
      emailOrPhone: 'pedro@swappia.mx',
      password: 'password123',
    );

    final offerRepo = OfferRepositoryImpl();
    await offerRepo.publishOffer(
      const OfferEntity(
        id: 'offer-bicicleta',
        usuarioId: 'usr-carlos',
        titulo: 'Bicicleta Rodada 26 de Montaña',
        descripcion: 'Bicicleta en buen estado.',
        categoria: 'Bienes',
        coloniaComunidad: 'Colonia La Florida',
        fotoUrl: 'https://ejemplo.com/bici.jpg',
        modalidad: 'trueque',
      ),
    );
    await offerRepo.publishOffer(
      const OfferEntity(
        id: 'offer-clases',
        usuarioId: 'usr-elena',
        titulo: 'Clases de Matemáticas Secundaria',
        descripcion: 'Regularización de secundaria.',
        categoria: 'Educación y Asesoría',
        coloniaComunidad: 'Colonia Lindavista',
        fotoUrl: 'https://ejemplo.com/mates.jpg',
        modalidad: 'mixto',
      ),
    );

    final feedVM = FeedViewModel(
      offerRepository: offerRepo,
      debounceDuration: const Duration(milliseconds: 100),
    );

    await tester.pumpWidget(buildFeedApp(authVM: authVM, feedVM: feedVM));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offer_card_offer-bicicleta')), findsOneWidget);
    expect(find.byKey(const Key('offer_card_offer-clases')), findsOneWidget);

    // Escribir en la barra de búsqueda
    await tester.enterText(
        find.byKey(const Key('feed_search_bar')), 'Bicicleta');

    // Antes de terminar el debounce aún no se filtra
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.byKey(const Key('offer_card_offer-clases')), findsOneWidget);

    // Esperar al debounce completo
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    // Solo debe verse la bicicleta
    expect(find.byKey(const Key('offer_card_offer-bicicleta')), findsOneWidget);
    expect(find.byKey(const Key('offer_card_offer-clases')), findsNothing);

    // Limpiar búsqueda
    expect(find.byKey(const Key('clear_search_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('clear_search_button')));
    await tester.pumpAndSettle();

    // Vuelven a verse ambas publicaciones
    expect(find.byKey(const Key('offer_card_offer-bicicleta')), findsOneWidget);
    expect(find.byKey(const Key('offer_card_offer-clases')), findsOneWidget);
  });
}
