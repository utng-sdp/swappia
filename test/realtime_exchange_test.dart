import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swappia_app/domain/models/exchange_entity.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/domain/models/user_entity.dart';
import 'package:swappia_app/domain/repositories/exchange_repository.dart';
import 'package:swappia_app/domain/repositories/offer_repository.dart';
import 'package:swappia_app/domain/repositories/user_repository.dart';
import 'package:swappia_app/domain/usecases/propose_exchange_usecase.dart';
import 'package:swappia_app/domain/usecases/rate_user_usecase.dart';
import 'package:swappia_app/presentation/viewmodels/exchange_viewmodel.dart';
import 'package:swappia_app/presentation/views/exchange/offer_detail_view.dart';
import 'dart:async';

class FakeExchangeRepository implements ExchangeRepository {
  final StreamController<ExchangeEntity> _controller =
      StreamController<ExchangeEntity>.broadcast();
  final List<ExchangeEntity> proposals = [];

  @override
  Future<ExchangeEntity> createProposal(ExchangeEntity exchange) async {
    proposals.add(exchange);
    _controller.add(exchange);
    return exchange;
  }

  @override
  Future<List<ExchangeEntity>> getProposalsForOffer(String offerId) async => proposals;

  @override
  Future<List<ExchangeEntity>> getProposalsByUser(String userId) async => proposals;

  @override
  Future<ExchangeEntity?> getProposalById(String id) async =>
      proposals.where((p) => p.id == id).firstOrNull;

  @override
  Future<ExchangeEntity> updateProposalStatus(String id, String nuevoEstado) async {
    final index = proposals.indexWhere((p) => p.id == id);
    if (index != -1) {
      final updated = proposals[index].copyWith(estado: nuevoEstado);
      proposals[index] = updated;
      _controller.add(updated);
      return updated;
    }
    final fallback = ExchangeEntity(
      id: id,
      offerId: 'off-1',
      usuarioProponenteId: 'usr-buyer',
      propuesta: 'trueque',
      estado: nuevoEstado,
      fechaCreacion: DateTime.now(),
    );
    _controller.add(fallback);
    return fallback;
  }

  @override
  Stream<ExchangeEntity> listenToExchangeUpdates({
    String? offerId,
    String? exchangeId,
  }) {
    return _controller.stream;
  }

  @override
  void emitRealtimeUpdate(ExchangeEntity exchange) {
    _controller.add(exchange);
  }

  void dispose() {
    _controller.close();
  }
}

class FakeOfferRepository implements OfferRepository {
  @override
  Future<OfferEntity> publishOffer(OfferEntity offer) async => offer;

  @override
  Future<List<OfferEntity>> getFilteredOffers({
    String? colonia,
    String? categoria,
    int page = 0,
    int limit = 20,
  }) async => [];

  @override
  Future<List<OfferEntity>> getOffers() async => [];

  @override
  Future<List<OfferEntity>> getOffersByColonia(String coloniaComunidad) async => [];

  @override
  Future<OfferEntity?> getOfferById(String id) async => null;

  Future<List<OfferEntity>> getOffersByUser(String userId) async => [];

  Future<void> createOffer(OfferEntity offer) async {}

  Future<void> updateOffer(OfferEntity offer) async {}

  @override
  Future<void> deleteOffer(String id) async {}

  @override
  Future<OfferEntity> updateOfferStatus(String offerId, String nuevoEstado) async {
    return OfferEntity(
      id: offerId,
      titulo: 'Test Offer',
      descripcion: 'Test Desc',
      categoria: 'Herramientas',
      modalidad: 'Trueque',
      coloniaComunidad: 'Centro',
      fotoUrl: 'https://ejemplo.com/foto.jpg',
      usuarioId: 'usr-seller',
      estado: nuevoEstado,
    );
  }
}

class FakeUserRepository implements UserRepository {
  final Map<String, UserEntity> users = {
    'usr-seller': UserEntity(
      id: 'usr-seller',
      nombre: 'Doña Lupita',
      coloniaComunidad: 'Centro',
      telefono: '4187654321',
      calificacionAcumulada: 5.0,
      totalCalificaciones: 5,
      fechaRegistro: DateTime(2026, 1, 1),
    ),
  };

  @override
  Future<UserEntity?> getUserById(String id) async => users[id];

  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Future<void> createUser(UserEntity user) async {}

  @override
  Future<void> updateUser(UserEntity user) async {}

  @override
  Future<List<UserEntity>> getUsersByColonia(String coloniaComunidad) async => [];

  @override
  Future<void> updateRating({
    required String userId,
    required double nuevaCalificacionAcumulada,
    required int nuevoTotalCalificaciones,
  }) async {
    final user = users[userId];
    if (user != null) {
      users[userId] = user.copyWith(
        calificacionAcumulada: nuevaCalificacionAcumulada,
        totalCalificaciones: nuevoTotalCalificaciones,
      );
    }
  }
}

void main() {
  testWidgets('Reacción en tiempo real (WebSockets / Supabase Realtime) al cambio de estado y calificación',
      (WidgetTester tester) async {
    final fakeExchangeRepo = FakeExchangeRepository();
    final fakeOfferRepo = FakeOfferRepository();
    final fakeUserRepo = FakeUserRepository();

    final proposeUseCase = ProposeExchangeUseCase(
      exchangeRepository: fakeExchangeRepo,
      offerRepository: fakeOfferRepo,
    );
    final rateUserUseCase = RateUserUseCase(fakeUserRepo);

    final exchangeVM = ExchangeViewModel(
      proposeExchangeUseCase: proposeUseCase,
      rateUserUseCase: rateUserUseCase,
      exchangeRepository: fakeExchangeRepo,
    );

    final testOffer = OfferEntity(
      id: 'off-realtime-1',
      titulo: 'Taladro Percutor Bosch',
      descripcion: 'En excelente estado para trueque',
      categoria: 'Herramientas',
      modalidad: 'Trueque',
      coloniaComunidad: 'La Lindavista',
      fotoUrl: 'https://ejemplo.com/taladro.jpg',
      usuarioId: 'usr-seller',
      estado: 'disponible',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ExchangeViewModel>.value(value: exchangeVM),
        ],
        child: MaterialApp(
          home: OfferDetailView(offer: testOffer),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Estado inicial: botón de proponer intercambio visible
    expect(find.byKey(const Key('propose_exchange_button')), findsOneWidget);
    expect(find.byKey(const Key('rate_user_button')), findsNothing);
    expect(find.byKey(const Key('accepted_proposal_banner')), findsNothing);

    // Conectar Realtime para la oferta
    exchangeVM.subscribeToExchangeUpdates(offerId: 'off-realtime-1');

    // Simular que llega un WebSocket de Realtime indicando que la propuesta fue aceptada
    final acceptedProposal = ExchangeEntity(
      id: 'exc-101',
      offerId: 'off-realtime-1',
      usuarioProponenteId: 'usr-buyer',
      usuarioReceptorId: 'usr-seller',
      propuesta: 'Te lo cambio por una podadora',
      estado: 'aceptada',
      fechaCreacion: DateTime.now(),
    );

    fakeExchangeRepo.emitRealtimeUpdate(acceptedProposal);

    // Esperar a que el stream entregue el evento y la UI reaccione en vivo
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Criterio de Aceptación: La app reacciona en tiempo real a los cambios de estado sin necesidad de refrescar la pantalla manualmente
    expect(find.byKey(const Key('accepted_proposal_banner')), findsOneWidget);
    expect(find.text('¡Propuesta Aceptada en Vivo!'), findsOneWidget);
    expect(find.byKey(const Key('rate_user_button')), findsOneWidget);
    expect(find.text('Propuesta Aceptada'), findsOneWidget);

    // Probar interacción con el botón de calificación
    await tester.ensureVisible(find.byKey(const Key('rate_user_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rate_user_button')));
    await tester.pumpAndSettle();

    // El modal de calificación debe estar abierto con las 5 estrellas
    expect(find.text('Tu opinión fortalece la confianza comunitaria'), findsOneWidget);
    expect(find.byKey(const Key('star_5')), findsOneWidget);
    expect(find.byKey(const Key('submit_rating_button')), findsOneWidget);

    // Enviar calificación de 5 estrellas
    await tester.tap(find.byKey(const Key('submit_rating_button')));
    await tester.pumpAndSettle();

    // Verificar que la calificación fue procesada por el usecase y repositorio
    final updatedSeller = await fakeUserRepo.getUserById('usr-seller');
    expect(updatedSeller, isNotNull);
    expect(updatedSeller!.totalCalificaciones, 6); // Pasó de 5 a 6
    expect(updatedSeller.calificacionAcumulada, 5.0);

    fakeExchangeRepo.dispose();
  });
}
