import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/domain/repositories/offer_repository.dart';
import 'package:swappia_app/domain/usecases/publish_offer_usecase.dart';

class MockOfferRepository implements OfferRepository {
  final List<OfferEntity> offers = [];
  bool shouldFail = false;

  @override
  Future<OfferEntity> publishOffer(OfferEntity offer) async {
    if (shouldFail) {
      throw Exception('Fallo de conexión al publicar');
    }
    offers.add(offer);
    return offer;
  }

  @override
  Future<List<OfferEntity>> getOffers() async => offers;

  @override
  Future<List<OfferEntity>> getOffersByColonia(String coloniaComunidad) async =>
      offers.where((o) => o.coloniaComunidad == coloniaComunidad).toList();

  @override
  Future<OfferEntity?> getOfferById(String id) async {
    try {
      return offers.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteOffer(String id) async {
    offers.removeWhere((o) => o.id == id);
  }
}

void main() {
  late MockOfferRepository repository;
  late PublishOfferUseCase useCase;

  setUp(() {
    repository = MockOfferRepository();
    useCase = PublishOfferUseCase(repository);
  });

  group('PublishOfferUseCase - Validaciones de campos obligatorios', () {
    test('Lanza excepción si el título está vacío o solo contiene espacios', () async {
      expect(
        () => useCase.execute(
          titulo: '   ',
          descripcion: 'Descripción válida de más de 5 caracteres',
          categoria: 'Herramientas',
          coloniaComunidad: 'Colonia Lindavista',
          usuarioId: 'usr_123',
          fotoUrl: 'herramienta.jpg',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('El título de la oferta es obligatorio'),
        )),
      );
    });

    test('Lanza excepción si el título tiene menos de 3 caracteres', () async {
      expect(
        () => useCase.execute(
          titulo: 'ab',
          descripcion: 'Descripción válida de más de 5 caracteres',
          categoria: 'Herramientas',
          coloniaComunidad: 'Colonia Lindavista',
          usuarioId: 'usr_123',
          fotoUrl: 'herramienta.jpg',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('El título debe tener al menos 3 caracteres'),
        )),
      );
    });

    test('Lanza excepción si la descripción está vacía', () async {
      expect(
        () => useCase.execute(
          titulo: 'Taladro percutor',
          descripcion: '    ',
          categoria: 'Herramientas',
          coloniaComunidad: 'Colonia Lindavista',
          usuarioId: 'usr_123',
          fotoUrl: 'herramienta.jpg',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('La descripción de la oferta es obligatoria'),
        )),
      );
    });

    test('Lanza excepción si la categoría está vacía', () async {
      expect(
        () => useCase.execute(
          titulo: 'Taladro percutor',
          descripcion: 'En excelente estado con brocas',
          categoria: '   ',
          coloniaComunidad: 'Colonia Lindavista',
          usuarioId: 'usr_123',
          fotoUrl: 'herramienta.jpg',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('La categoría es obligatoria'),
        )),
      );
    });

    test('Lanza excepción si la colonia o comunidad está vacía', () async {
      expect(
        () => useCase.execute(
          titulo: 'Taladro percutor',
          descripcion: 'En excelente estado con brocas',
          categoria: 'Herramientas',
          coloniaComunidad: '   ',
          usuarioId: 'usr_123',
          fotoUrl: 'herramienta.jpg',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('La colonia o comunidad es obligatoria'),
        )),
      );
    });

    test('Lanza excepción si el identificador de usuario está vacío', () async {
      expect(
        () => useCase.execute(
          titulo: 'Taladro percutor',
          descripcion: 'En excelente estado con brocas',
          categoria: 'Herramientas',
          coloniaComunidad: 'Centro',
          usuarioId: '   ',
          fotoUrl: 'herramienta.jpg',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('El identificador del usuario es obligatorio'),
        )),
      );
    });

    test('Lanza excepción si la fotografía de la oferta está vacía', () async {
      expect(
        () => useCase.execute(
          titulo: 'Taladro percutor',
          descripcion: 'En excelente estado con brocas',
          categoria: 'Herramientas',
          coloniaComunidad: 'Centro',
          usuarioId: 'usr_123',
          fotoUrl: '   ',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('La fotografía de la oferta es obligatoria'),
        )),
      );
    });
  });

  group('PublishOfferUseCase - Validaciones de formato de foto', () {
    test('Rechaza formatos que no sean JPG, JPEG, PNG o WEBP', () async {
      final invalidPhotos = [
        'documento.pdf',
        'foto.gif',
        'manual.txt',
        'imagen.bmp',
        'ejecutable.exe',
        'video.mp4',
      ];

      for (final invalid in invalidPhotos) {
        expect(
          () => useCase.execute(
            titulo: 'Taladro percutor',
            descripcion: 'En excelente estado con brocas',
            categoria: 'Herramientas',
            coloniaComunidad: 'Centro',
            usuarioId: 'usr_123',
            fotoUrl: invalid,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('El formato de la foto debe ser JPG, JPEG, PNG o WEBP'),
          )),
        );
      }
    });

    test('Acepta formatos válidos en minúsculas y mayúsculas (.jpg, .jpeg, .png, .webp)', () async {
      final validPhotos = [
        'foto.jpg',
        'FOTO.JPEG',
        'path/to/articulo.png',
        'https://supabase.co/storage/v1/object/public/offers/taladro.webp',
        'https://supabase.co/storage/v1/object/public/offers/taladro.png?token=exp123',
        'data:image/jpeg;base64,/9j/4AAQSkZJRg...',
      ];

      for (final valid in validPhotos) {
        final result = await useCase.execute(
          titulo: 'Taladro percutor',
          descripcion: 'En excelente estado con brocas',
          categoria: 'Herramientas',
          coloniaComunidad: 'Centro',
          usuarioId: 'usr_123',
          fotoUrl: valid,
        );
        expect(result.fotoUrl, valid);
      }
    });
  });

  group('PublishOfferUseCase - Validaciones adicionales y persistencia', () {
    test('Rechaza precios estimados negativos', () async {
      expect(
        () => useCase.execute(
          titulo: 'Taladro percutor',
          descripcion: 'En excelente estado con brocas',
          categoria: 'Herramientas',
          coloniaComunidad: 'Centro',
          usuarioId: 'usr_123',
          fotoUrl: 'herramienta.jpg',
          precioEstimado: -50.0,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('El precio estimado no puede ser negativo'),
        )),
      );
    });

    test('Persiste correctamente una oferta válida y asigna modalidad y estado', () async {
      final result = await useCase.execute(
        titulo: 'Clases de Matemáticas',
        descripcion: 'Asesoría para secundaria y preparatoria en Dolores',
        categoria: 'Educación y Asesoría',
        coloniaComunidad: 'Colonia San Antonio',
        usuarioId: 'usr_prof_elena',
        fotoUrl: 'clases.jpg',
        modalidad: 'mixto',
        loQueBusca: 'Apoyo con jardín o 80 MXN',
        precioEstimado: 80.0,
      );

      expect(result.titulo, 'Clases de Matemáticas');
      expect(result.categoria, 'Educación y Asesoría');
      expect(result.coloniaComunidad, 'Colonia San Antonio');
      expect(result.modalidad, 'mixto');
      expect(result.loQueBusca, 'Apoyo con jardín o 80 MXN');
      expect(result.precioEstimado, 80.0);
      expect(result.activa, isTrue);
      expect(result.id, isNotEmpty);
      expect(repository.offers.length, 1);
    });
  });
}
