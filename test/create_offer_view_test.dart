import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swappia_app/core/theme/app_theme.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/domain/repositories/offer_repository.dart';
import 'package:swappia_app/domain/usecases/publish_offer_usecase.dart';
import 'package:swappia_app/presentation/viewmodels/create_offer_viewmodel.dart';
import 'package:swappia_app/presentation/views/exchange/create_offer_view.dart';

class MockOfferRepository implements OfferRepository {
  final List<OfferEntity> offers = [];

  @override
  Future<OfferEntity> publishOffer(OfferEntity offer) async {
    offers.add(offer);
    return offer;
  }

  @override
  Future<List<OfferEntity>> getOffers() async => offers;

  @override
  Future<List<OfferEntity>> getOffersByColonia(String coloniaComunidad) async =>
      offers.where((o) => o.coloniaComunidad == coloniaComunidad).toList();

  @override
  Future<OfferEntity?> getOfferById(String id) async => null;

  @override
  Future<void> deleteOffer(String id) async {}
}

void main() {
  late MockOfferRepository repository;
  late PublishOfferUseCase useCase;
  late CreateOfferViewModel viewModel;

  setUp(() {
    repository = MockOfferRepository();
    useCase = PublishOfferUseCase(repository);
    viewModel = CreateOfferViewModel(publishOfferUseCase: useCase);
  });

  Widget createTestWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ChangeNotifierProvider<CreateOfferViewModel>.value(
        value: viewModel,
        child: const CreateOfferView(),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('Renderiza correctamente todos los campos y botones del formulario',
      (WidgetTester tester) async {
    setMobileScreen(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Publicar Oferta o Necesidad'), findsOneWidget);
    expect(find.byKey(const Key('offer_title_field')), findsOneWidget);
    expect(find.byKey(const Key('offer_category_dropdown')), findsOneWidget);
    expect(find.byKey(const Key('offer_description_field')), findsOneWidget);
    expect(find.byKey(const Key('offer_photo_field')), findsOneWidget);
    expect(find.byKey(const Key('offer_colonia_dropdown')), findsOneWidget);
    expect(find.byKey(const Key('offer_modalidad_segmented')), findsOneWidget);
    expect(find.byKey(const Key('submit_offer_button')), findsOneWidget);
    expect(find.byKey(const Key('clear_offer_form_button')), findsOneWidget);
  });

  testWidgets('Muestra mensaje de error en StatusBanner cuando faltan campos requeridos',
      (WidgetTester tester) async {
    setMobileScreen(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Pulsar botón de publicar con formulario vacío
    await tester.tap(find.byKey(const Key('submit_offer_button')));
    await tester.pumpAndSettle();

    // Debe mostrar banner de error indicando que el título es obligatorio
    expect(find.byKey(const Key('create_offer_error_banner')), findsOneWidget);
    expect(find.text('El título de la oferta es obligatorio'), findsOneWidget);
  });

  testWidgets('Publicación exitosa limpia los campos del formulario y notifica éxito',
      (WidgetTester tester) async {
    setMobileScreen(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // 1. Ingresar título
    await tester.enterText(
        find.byKey(const Key('offer_title_field')), 'Herramientas de Jardinería');

    // 2. Seleccionar categoría desde el ViewModel
    viewModel.setCategoria('Herramientas y Maquinaria');

    // 3. Ingresar descripción
    await tester.enterText(
        find.byKey(const Key('offer_description_field')),
        'Pala, rastrillo y tijeras de podar en excelente estado');

    // 4. Ingresar foto válida
    await tester.enterText(
        find.byKey(const Key('offer_photo_field')), 'jardineria.png');

    // 5. Seleccionar colonia desde el ViewModel
    viewModel.setColoniaComunidad('Colonia Lindavista');

    await tester.pumpAndSettle();

    // 6. Presionar botón de publicar
    await tester.tap(find.byKey(const Key('submit_offer_button')));
    await tester.pumpAndSettle();

    // 7. Debe mostrar el banner de éxito y el snackbar
    expect(find.byKey(const Key('create_offer_success_banner')), findsOneWidget);
    expect(find.text('¡Oferta publicada exitosamente!'), findsWidgets);

    // 8. Criterio de aceptación: los campos del formulario quedan limpios
    final titleField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('offer_title_field')),
        matching: find.byType(TextField),
      ),
    );
    expect(titleField.controller?.text, isEmpty);
  });
}
