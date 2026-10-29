import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/data/repositories/offer_repository_impl.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/presentation/viewmodels/feed_viewmodel.dart';

void main() {
  late OfferRepositoryImpl repository;
  late FeedViewModel viewModel;

  setUp(() {
    repository = OfferRepositoryImpl();
    viewModel = FeedViewModel(
      offerRepository: repository,
      debounceDuration: const Duration(milliseconds: 50),
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('FeedViewModel - Carga y Filtrado de Ofertas', () {
    test('loadOffers carga ofertas iniciales comunitarias si el repo está vacío', () async {
      expect(viewModel.offers, isEmpty);
      expect(viewModel.isLoading, isFalse);

      await viewModel.loadOffers();

      expect(viewModel.offers, isNotEmpty);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.count, greaterThanOrEqualTo(3));
      expect(viewModel.offers.any((o) => o.titulo.contains('Jardinería')), isTrue);
    });

    test('loadOffers carga ofertas existentes desde el repositorio', () async {
      await repository.publishOffer(
        const OfferEntity(
          id: 'custom-1',
          usuarioId: 'usr-1',
          titulo: 'Taladro Percutor Bosch',
          descripcion: 'Taladro industrial en perfecto estado.',
          categoria: 'Herramientas y Maquinaria',
          coloniaComunidad: 'Centro',
          fotoUrl: 'https://ejemplo.com/taladro.jpg',
          modalidad: 'trueque',
        ),
      );

      await viewModel.loadOffers();

      expect(viewModel.offers.length, 1);
      expect(viewModel.offers.first.titulo, 'Taladro Percutor Bosch');
    });

    test('onSearchChanged filtra ofertas tras el debounce', () async {
      await viewModel.loadOffers();
      final totalInicial = viewModel.count;
      expect(totalInicial, greaterThanOrEqualTo(3));

      // Disparar búsqueda con término específico
      viewModel.onSearchChanged('Matemáticas');

      // Inmediatamente antes del debounce aún no ha cambiado el query activo
      expect(viewModel.searchQuery, '');

      // Esperar a que el debounce termine
      await Future.delayed(const Duration(milliseconds: 100));

      expect(viewModel.searchQuery, 'Matemáticas');
      expect(viewModel.offers.length, 1);
      expect(viewModel.offers.first.titulo, contains('Matemáticas'));
    });

    test('searchImmediate filtra sin esperar debounce', () async {
      await viewModel.loadOffers();

      viewModel.searchImmediate('Bicicleta');

      expect(viewModel.searchQuery, 'Bicicleta');
      expect(viewModel.offers.length, 1);
      expect(viewModel.offers.first.titulo, contains('Bicicleta'));
    });

    test('clearSearch restablece todas las ofertas y limpia la consulta', () async {
      await viewModel.loadOffers();
      final totalInicial = viewModel.count;

      viewModel.searchImmediate('Bicicleta');
      expect(viewModel.count, 1);

      viewModel.clearSearch();

      expect(viewModel.searchQuery, '');
      expect(viewModel.searchController.text, '');
      expect(viewModel.count, totalInicial);
    });

    test('filtro busca en descripción, colonia y lo que busca', () async {
      await viewModel.loadOffers();

      // Buscar por colonia 'Lindavista'
      viewModel.searchImmediate('Lindavista');
      expect(viewModel.offers.any((o) => o.coloniaComunidad.contains('Lindavista')), isTrue);

      // Buscar por lo que busca 'despensa'
      viewModel.searchImmediate('despensa');
      expect(viewModel.offers.any((o) => o.loQueBusca?.toLowerCase().contains('despensa') ?? false), isTrue);
    });
  });
}

