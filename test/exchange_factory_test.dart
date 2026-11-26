import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/data/repositories/exchange_repository_impl.dart';
import 'package:swappia_app/data/repositories/offer_repository_impl.dart';
import 'package:swappia_app/domain/factories/exchange_factory.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/domain/usecases/propose_exchange_usecase.dart';

void main() {
  group('Issue #18 & #24: ExchangeFactory y clases derivadas', () {
    test('Crea CashExchange cuando modalidad es dinero/efectivo', () {
      final exchange = ExchangeFactory.create(
        modalidad: 'efectivo',
        id: 'exc-cash-1',
        offerId: 'off-1',
        usuarioProponenteId: 'usr-1',
        usuarioReceptorId: 'usr-2',
        propuesta: 'Pago completo al recibir la herramienta',
        montoEfectivo: 350.0,
      );

      expect(exchange, isA<CashExchange>());
      final cash = exchange as CashExchange;
      expect(cash.modalidad, 'dinero');
      expect(cash.esValido, isTrue);
      expect(cash.resumenAcuerdo, contains('350.00 MXN'));
    });

    test('Crea BarterExchange cuando modalidad es trueque', () {
      final exchange = ExchangeFactory.create(
        modalidad: 'trueque',
        id: 'exc-barter-1',
        offerId: 'off-2',
        usuarioProponenteId: 'usr-1',
        propuesta: 'Cambio por juego de desarmadores',
        bienOfrecidoId: 'off-own-1',
        bienOfrecidoTitulo: 'Juego de Desarmadores',
      );

      expect(exchange, isA<BarterExchange>());
      final barter = exchange as BarterExchange;
      expect(barter.modalidad, 'trueque');
      expect(barter.esValido, isTrue);
      expect(barter.resumenAcuerdo, contains('Juego de Desarmadores'));
    });

    test('Crea MixedExchange cuando modalidad es mixto', () {
      final exchange = ExchangeFactory.create(
        modalidad: 'mixto',
        id: 'exc-mix-1',
        offerId: 'off-3',
        usuarioProponenteId: 'usr-1',
        propuesta: 'Ofrezco pintura y diferencia en efectivo',
        montoEfectivo: 120.0,
        bienOfrecidoTitulo: 'Cubeta de Pintura',
      );

      expect(exchange, isA<MixedExchange>());
      final mixed = exchange as MixedExchange;
      expect(mixed.modalidad, 'mixto');
      expect(mixed.esValido, isTrue);
      expect(mixed.resumenAcuerdo, contains('Cubeta de Pintura'));
      expect(mixed.resumenAcuerdo, contains('120.00 MXN'));
    });

    test('Lanza ArgumentError para modalidad desconocida o monto negativo', () {
      expect(
        () => ExchangeFactory.create(
          modalidad: 'cripto',
          id: 'exc-bad',
          offerId: 'off-1',
          usuarioProponenteId: 'usr-1',
          propuesta: 'Propuesta inválida',
        ),
        throwsArgumentError,
      );

      expect(
        () => ExchangeFactory.create(
          modalidad: 'dinero',
          id: 'exc-neg',
          offerId: 'off-1',
          usuarioProponenteId: 'usr-1',
          propuesta: 'Monto negativo',
          montoEfectivo: -50,
        ),
        throwsArgumentError,
      );
    });

    test('ProposeExchangeUseCase instancia ExchangeFactory con modalidad y bien propio',
        () async {
      final offerRepo = OfferRepositoryImpl();
      final exchangeRepo = ExchangeRepositoryImpl();
      final offer = await offerRepo.publishOffer(
        const OfferEntity(
          id: 'off-factory-test',
          usuarioId: 'usr-receptor',
          titulo: 'Mesa de Madera',
          descripcion: 'Mesa artesanal de Dolores Hidalgo',
          categoria: 'Artesanía',
          coloniaComunidad: 'Centro',
          fotoUrl: 'https://ejemplo.com/mesa.jpg',
          modalidad: 'mixto',
        ),
      );

      final useCase = ProposeExchangeUseCase(
        exchangeRepository: exchangeRepo,
        offerRepository: offerRepo,
      );

      final result = await useCase.execute(
        offerId: offer.id,
        usuarioProponenteId: 'usr-proponente',
        propuesta: 'Te doy mi lámpara más 200 pesos',
        modalidad: 'mixto',
        montoEfectivo: 200.0,
        bienOfrecidoId: 'off-lampara',
        bienOfrecidoTitulo: 'Lámpara de Talavera',
      );

      expect(result.proposal.modalidad, 'mixto');
      expect(result.proposal.montoEfectivo, 200.0);
      expect(result.proposal.bienOfrecidoTitulo, 'Lámpara de Talavera');
      expect(result.updatedOffer.estado, 'pendiente_aceptacion');
    });
  });
}
