import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/data/repositories/exchange_repository_impl.dart';
import 'package:swappia_app/data/repositories/offer_repository_impl.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/domain/usecases/propose_exchange_usecase.dart';

void main() {
  late OfferRepositoryImpl offerRepo;
  late ExchangeRepositoryImpl exchangeRepo;
  late ProposeExchangeUseCase useCase;

  setUp(() {
    offerRepo = OfferRepositoryImpl();
    exchangeRepo = ExchangeRepositoryImpl();
    useCase = ProposeExchangeUseCase(
      exchangeRepository: exchangeRepo,
      offerRepository: offerRepo,
    );
  });

  group('ProposeExchangeUseCase - Validaciones de Reglas de Negocio', () {
    test('Lanza excepción si la descripción de la propuesta está vacía o es muy corta', () async {
      await offerRepo.publishOffer(
        const OfferEntity(
          id: 'offer-1',
          usuarioId: 'usr-dueño',
          titulo: 'Taladro Bosch',
          descripcion: 'Taladro industrial',
          categoria: 'Herramientas',
          coloniaComunidad: 'Centro',
          fotoUrl: 'https://ejemplo.com/foto.jpg',
        ),
      );

      expect(
        () => useCase.execute(
          offerId: 'offer-1',
          usuarioProponenteId: 'usr-vecino',
          propuesta: '',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('no puede estar vacía'),
        )),
      );

      expect(
        () => useCase.execute(
          offerId: 'offer-1',
          usuarioProponenteId: 'usr-vecino',
          propuesta: 'ab',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('al menos 3 caracteres'),
        )),
      );
    });

    test('Lanza excepción si el proponente intenta proponer sobre su propia publicación', () async {
      await offerRepo.publishOffer(
        const OfferEntity(
          id: 'offer-propia',
          usuarioId: 'usr-carlos',
          titulo: 'Bicicleta de Montaña',
          descripcion: 'Bicicleta rodada 26',
          categoria: 'Bienes',
          coloniaComunidad: 'Centro',
          fotoUrl: 'https://ejemplo.com/bici.jpg',
        ),
      );

      expect(
        () => useCase.execute(
          offerId: 'offer-propia',
          usuarioProponenteId: 'usr-carlos',
          propuesta: 'Te ofrezco mi podadora a cambio',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('No puedes proponer un intercambio sobre tu propia publicación'),
        )),
      );
    });

    test('Lanza excepción si la publicación está inactiva', () async {
      await offerRepo.publishOffer(
        const OfferEntity(
          id: 'offer-pausada',
          usuarioId: 'usr-dueño',
          titulo: 'Mesa de madera',
          descripcion: 'Mesa usada',
          categoria: 'Bienes',
          coloniaComunidad: 'Centro',
          fotoUrl: 'https://ejemplo.com/mesa.jpg',
          activa: false,
        ),
      );

      expect(
        () => useCase.execute(
          offerId: 'offer-pausada',
          usuarioProponenteId: 'usr-otro',
          propuesta: 'Te ofrezco una silla a cambio',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('No es posible proponer intercambio en una publicación pausada'),
        )),
      );
    });
  });

  group('ProposeExchangeUseCase - Ejecución Exitosa y Persistencia', () {
    test('Persiste la propuesta y actualiza la publicación a "pendiente_aceptacion"', () async {
      final initialOffer = await offerRepo.publishOffer(
        const OfferEntity(
          id: 'offer-trueque-1',
          usuarioId: 'usr-dueño',
          titulo: 'Podadora de césped',
          descripcion: 'Podadora en excelente estado',
          categoria: 'Herramientas',
          coloniaComunidad: 'Colonia La Florida',
          fotoUrl: 'https://ejemplo.com/podadora.jpg',
          modalidad: 'trueque',
        ),
      );

      expect(initialOffer.estado, 'disponible');
      expect(initialOffer.estaEnPropuesta, isFalse);

      final result = await useCase.execute(
        offerId: 'offer-trueque-1',
        usuarioProponenteId: 'usr-proponente',
        propuesta: 'Te ofrezco juego de llaves mecánicas y desarmadores',
      );

      // 1. Verificación de propuesta persistida
      expect(result.proposal.id, isNotEmpty);
      expect(result.proposal.offerId, 'offer-trueque-1');
      expect(result.proposal.usuarioProponenteId, 'usr-proponente');
      expect(result.proposal.usuarioReceptorId, 'usr-dueño');
      expect(result.proposal.propuesta, 'Te ofrezco juego de llaves mecánicas y desarmadores');
      expect(result.proposal.estado, 'pendiente_aceptacion');
      expect(result.proposal.esPendiente, isTrue);

      final storedProposals = await exchangeRepo.getProposalsForOffer('offer-trueque-1');
      expect(storedProposals.length, 1);
      expect(storedProposals.first.propuesta, result.proposal.propuesta);

      // 2. Verificación de actualización del estado de la publicación
      expect(result.updatedOffer.id, 'offer-trueque-1');
      expect(result.updatedOffer.estado, 'pendiente_aceptacion');
      expect(result.updatedOffer.estaEnPropuesta, isTrue);

      final updatedInRepo = await offerRepo.getOfferById('offer-trueque-1');
      expect(updatedInRepo, isNotNull);
      expect(updatedInRepo!.estado, 'pendiente_aceptacion');
      expect(updatedInRepo.estaEnPropuesta, isTrue);
    });
  });
}
