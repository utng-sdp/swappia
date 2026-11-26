import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/data/repositories/exchange_repository_impl.dart';
import 'package:swappia_app/data/repositories/offer_repository_impl.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/domain/usecases/propose_exchange_usecase.dart';
import 'package:swappia_app/presentation/viewmodels/exchange_viewmodel.dart';

void main() {
  late OfferRepositoryImpl offerRepo;
  late ExchangeRepositoryImpl exchangeRepo;
  late ProposeExchangeUseCase useCase;
  late ExchangeViewModel viewModel;

  setUp(() async {
    offerRepo = OfferRepositoryImpl();
    exchangeRepo = ExchangeRepositoryImpl();
    useCase = ProposeExchangeUseCase(
      exchangeRepository: exchangeRepo,
      offerRepository: offerRepo,
    );
    viewModel = ExchangeViewModel(proposeExchangeUseCase: useCase);

    await offerRepo.publishOffer(
      const OfferEntity(
        id: 'offer-prueba-1',
        usuarioId: 'usr-vecino-vendedor',
        titulo: 'Sierra Circular Eléctrica',
        descripcion: 'Sierra en perfecto estado',
        categoria: 'Herramientas',
        coloniaComunidad: 'Centro',
        fotoUrl: 'https://ejemplo.com/sierra.jpg',
      ),
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('ExchangeViewModel - Control de Estado del Flujo de Negociación', () {
    test('Estado inicial es initial y no hay errores ni mensajes', () {
      expect(viewModel.status, ExchangeStatus.initial);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.isSuccess, isFalse);
      expect(viewModel.hasError, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.successMessage, isNull);
      expect(viewModel.currentProposal, isNull);
      expect(viewModel.updatedOffer, isNull);
    });

    test('sendProposal con datos válidos actualiza a success y limpia el formulario', () async {
      viewModel.proposalController.text = 'Te ofrezco una pulidora y dos discos a cambio';

      final success = await viewModel.sendProposal(
        offerId: 'offer-prueba-1',
        usuarioProponenteId: 'usr-comprador',
      );

      expect(success, isTrue);
      expect(viewModel.status, ExchangeStatus.success);
      expect(viewModel.isSuccess, isTrue);
      expect(viewModel.hasError, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.successMessage, contains('éxito'));

      expect(viewModel.currentProposal, isNotNull);
      expect(viewModel.currentProposal!.propuesta, 'Te ofrezco una pulidora y dos discos a cambio');
      expect(viewModel.currentProposal!.estado, 'pendiente_aceptacion');

      expect(viewModel.updatedOffer, isNotNull);
      expect(viewModel.updatedOffer!.estado, 'pendiente_aceptacion');
      expect(viewModel.updatedOffer!.estaEnPropuesta, isTrue);

      // Criterio: Se limpia el formulario
      expect(viewModel.proposalController.text, isEmpty);
    });

    test('sendProposal con propuesta vacía cambia el estado a error', () async {
      viewModel.proposalController.text = '';

      final success = await viewModel.sendProposal(
        offerId: 'offer-prueba-1',
        usuarioProponenteId: 'usr-comprador',
      );

      expect(success, isFalse);
      expect(viewModel.status, ExchangeStatus.error);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.isSuccess, isFalse);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.errorMessage, contains('no puede estar vacía'));
    });

    test('clearError restablece el mensaje de error', () async {
      await viewModel.sendProposal(
        offerId: 'offer-prueba-1',
        usuarioProponenteId: 'usr-comprador',
        propuesta: 'x',
      );

      expect(viewModel.hasError, isTrue);

      viewModel.clearError();

      expect(viewModel.hasError, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('reset restablece todos los valores a su estado inicial', () async {
      await viewModel.sendProposal(
        offerId: 'offer-prueba-1',
        usuarioProponenteId: 'usr-comprador',
        propuesta: 'Propuesta válida completa',
      );

      expect(viewModel.isSuccess, isTrue);

      viewModel.reset();

      expect(viewModel.status, ExchangeStatus.initial);
      expect(viewModel.currentProposal, isNull);
      expect(viewModel.updatedOffer, isNull);
      expect(viewModel.successMessage, isNull);
    });
  });
}
