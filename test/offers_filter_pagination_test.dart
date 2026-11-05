import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/data/datasources/remote/offers_remote_datasource.dart';
import 'package:swappia_app/data/repositories/offer_repository_impl.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';

void main() {
  group('Issue #15: Filtros espaciales por colonia y categoría en OffersRepository', () {
    late MockOffersRemoteDataSource mockRemote;
    late OfferRepositoryImpl repositoryWithRemote;
    late OfferRepositoryImpl repositoryInMemoryOnly;

    final now = DateTime.now();

    final testOffers = [
      OfferEntity(
        id: 'off-1',
        usuarioId: 'usr-1',
        titulo: 'Taladro Percutor 750W',
        descripcion: 'Taladro con accesorios para trabajos en casa.',
        categoria: 'Herramientas',
        coloniaComunidad: 'Centro',
        fotoUrl: 'https://ejemplo.com/taladro.jpg',
        fechaPublicacion: now.subtract(const Duration(hours: 1)),
        activa: true,
      ),
      OfferEntity(
        id: 'off-2',
        usuarioId: 'usr-2',
        titulo: 'Sierra Caladora',
        descripcion: 'Sierra para madera y metal en excelente estado.',
        categoria: 'Herramientas',
        coloniaComunidad: 'La Lindavista',
        fotoUrl: 'https://ejemplo.com/sierra.jpg',
        fechaPublicacion: now.subtract(const Duration(hours: 2)),
        activa: true,
      ),
      OfferEntity(
        id: 'off-3',
        usuarioId: 'usr-3',
        titulo: 'Miel de Abeja Artesanal',
        descripcion: 'Miel cosechada localmente en frascos de 1 litro.',
        categoria: 'Alimentos',
        coloniaComunidad: 'Centro',
        fotoUrl: 'https://ejemplo.com/miel.jpg',
        fechaPublicacion: now.subtract(const Duration(hours: 3)),
        activa: true,
      ),
      OfferEntity(
        id: 'off-4',
        usuarioId: 'usr-4',
        titulo: 'Caja de Herramientas de Mano',
        descripcion: 'Juego de llaves, desarmadores y pinzas.',
        categoria: 'Herramientas',
        coloniaComunidad: 'Centro',
        fotoUrl: 'https://ejemplo.com/caja.jpg',
        fechaPublicacion: now.subtract(const Duration(hours: 4)),
        activa: true,
      ),
      OfferEntity(
        id: 'off-5',
        usuarioId: 'usr-5',
        titulo: 'Clases de Regularización de Matemáticas',
        descripcion: 'Asesorías de cálculo y álgebra secundaria y prepa.',
        categoria: 'Educación',
        coloniaComunidad: 'El Llanito',
        fotoUrl: 'https://ejemplo.com/mates.jpg',
        fechaPublicacion: now.subtract(const Duration(hours: 5)),
        activa: true,
      ),
      OfferEntity(
        id: 'off-6',
        usuarioId: 'usr-6',
        titulo: 'Queso Ranchero Artesanal',
        descripcion: 'Pieza de queso fresco de vaca elaborado en rancho.',
        categoria: 'Alimentos',
        coloniaComunidad: 'El Llanito',
        fotoUrl: 'https://ejemplo.com/queso.jpg',
        fechaPublicacion: now.subtract(const Duration(hours: 6)),
        activa: true,
      ),
    ];

    setUp(() async {
      mockRemote = MockOffersRemoteDataSource();
      repositoryWithRemote = OfferRepositoryImpl(remoteDataSource: mockRemote);
      repositoryInMemoryOnly = OfferRepositoryImpl();

      for (final offer in testOffers) {
        await repositoryWithRemote.publishOffer(offer);
        await repositoryInMemoryOnly.publishOffer(offer);
      }
    });

    test(
        'Criterio de Aceptación: La API devuelve únicamente las publicaciones asociadas a los filtros solicitados (Colonia)',
        () async {
      // Filtrar únicamente por la colonia Centro
      final centroOffers = await repositoryWithRemote.getFilteredOffers(
        colonia: 'Centro',
      );

      expect(centroOffers, isNotEmpty);
      expect(centroOffers.length, 3);
      for (final offer in centroOffers) {
        expect(offer.coloniaComunidad.toLowerCase(), 'centro');
      }

      // No debe contener ofertas de otras colonias
      expect(centroOffers.any((o) => o.id == 'off-2'), isFalse);
      expect(centroOffers.any((o) => o.id == 'off-5'), isFalse);
    });

    test(
        'Criterio de Aceptación: La API devuelve únicamente las publicaciones asociadas a los filtros solicitados (Categoría)',
        () async {
      // Filtrar únicamente por la categoría Herramientas
      final herramientas = await repositoryWithRemote.getFilteredOffers(
        categoria: 'Herramientas',
      );

      expect(herramientas, isNotEmpty);
      expect(herramientas.length, 3);
      for (final offer in herramientas) {
        expect(offer.categoria.toLowerCase(), 'herramientas');
      }

      // No debe contener alimentos ni educación
      expect(herramientas.any((o) => o.categoria == 'Alimentos'), isFalse);
      expect(herramientas.any((o) => o.categoria == 'Educación'), isFalse);
    });

    test(
        'Criterio de Aceptación: Filtro conjunto colonia + categoría devuelve la intersección exacta',
        () async {
      // Filtrar por colonia 'Centro' Y categoría 'Herramientas'
      final resultados = await repositoryWithRemote.getFilteredOffers(
        colonia: 'Centro',
        categoria: 'Herramientas',
      );

      expect(resultados.length, 2);
      expect(resultados.map((o) => o.id).toSet(), containsAll(['off-1', 'off-4']));

      // Validar que cada publicación cumpla ambos criterios
      for (final offer in resultados) {
        expect(offer.coloniaComunidad.toLowerCase(), 'centro');
        expect(offer.categoria.toLowerCase(), 'herramientas');
      }
    });

    test('Filtro sin coincidencias retorna lista vacía sin errores', () async {
      final vacio = await repositoryWithRemote.getFilteredOffers(
        colonia: 'Comunidad Inexistente',
        categoria: 'Aeronáutica',
      );

      expect(vacio, isEmpty);
    });

    test('Paginación simple: respeta page y limit dividiendo los resultados en lotes', () async {
      // Página 0, límite 2
      final page0 = await repositoryWithRemote.getFilteredOffers(
        page: 0,
        limit: 2,
      );
      expect(page0.length, 2);
      expect(page0[0].id, 'off-1');
      expect(page0[1].id, 'off-2');

      // Página 1, límite 2
      final page1 = await repositoryWithRemote.getFilteredOffers(
        page: 1,
        limit: 2,
      );
      expect(page1.length, 2);
      expect(page1[0].id, 'off-3');
      expect(page1[1].id, 'off-4');

      // Página 2, límite 2
      final page2 = await repositoryWithRemote.getFilteredOffers(
        page: 2,
        limit: 2,
      );
      expect(page2.length, 2);
      expect(page2[0].id, 'off-5');
      expect(page2[1].id, 'off-6');

      // Página 3, fuera de rango
      final page3 = await repositoryWithRemote.getFilteredOffers(
        page: 3,
        limit: 2,
      );
      expect(page3, isEmpty);
    });

    test('Ordenamiento cronológico descendente: las ofertas más recientes aparecen primero', () async {
      final ofertas = await repositoryWithRemote.getFilteredOffers(limit: 10);
      expect(ofertas.length, 6);

      for (int i = 0; i < ofertas.length - 1; i++) {
        final current = ofertas[i].fechaPublicacion!;
        final next = ofertas[i + 1].fechaPublicacion!;
        expect(current.isAfter(next) || current.isAtSameMomentAs(next), isTrue,
            reason: 'La oferta $i debe ser más reciente o igual a la oferta ${i + 1}');
      }
    });

    test('Fallback local en memoria: soporta filtros espaciales y paginación idénticamente', () async {
      final centroHerramientas = await repositoryInMemoryOnly.getFilteredOffers(
        colonia: 'Centro',
        categoria: 'Herramientas',
      );
      expect(centroHerramientas.length, 2);
      expect(centroHerramientas.map((o) => o.id).toSet(), containsAll(['off-1', 'off-4']));

      final paginado = await repositoryInMemoryOnly.getFilteredOffers(
        page: 1,
        limit: 2,
      );
      expect(paginado.length, 2);
      expect(paginado[0].id, 'off-3');
      expect(paginado[1].id, 'off-4');
    });
  });
}
