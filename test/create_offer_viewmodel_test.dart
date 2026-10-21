import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';
import 'package:swappia_app/domain/repositories/offer_repository.dart';
import 'package:swappia_app/domain/usecases/publish_offer_usecase.dart';
import 'package:swappia_app/presentation/viewmodels/create_offer_viewmodel.dart';

class MockOfferRepository implements OfferRepository {
  final List<OfferEntity> offers = [];
  bool shouldFail = false;

  @override
  Future<OfferEntity> publishOffer(OfferEntity offer) async {
    if (shouldFail) {
      throw Exception('Error del servidor al registrar oferta');
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
  late CreateOfferViewModel viewModel;

  setUp(() {
    repository = MockOfferRepository();
    useCase = PublishOfferUseCase(repository);
    viewModel = CreateOfferViewModel(publishOfferUseCase: useCase);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('CreateOfferViewModel - Estado inicial y gestión de controladores', () {
    test('Estado inicial es initial sin errores ni oferta creada', () {
      expect(viewModel.status, CreateOfferStatus.initial);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.isSuccess, isFalse);
      expect(viewModel.hasError, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.successMessage, isNull);
      expect(viewModel.createdOffer, isNull);
      expect(viewModel.tituloController.text, isEmpty);
      expect(viewModel.descripcionController.text, isEmpty);
      expect(viewModel.categoria, isEmpty);
      expect(viewModel.coloniaComunidad, isEmpty);
      expect(viewModel.modalidad, 'trueque');
    });

    test('Actualización de selectores actualiza valores y controladores', () {
      viewModel.setCategoria('Servicios u Oficios');
      viewModel.setColoniaComunidad('Colonia Lindavista');
      viewModel.setModalidad('mixto');
      viewModel.setFotoPath('mifoto.jpg');

      expect(viewModel.categoria, 'Servicios u Oficios');
      expect(viewModel.categoriaController.text, 'Servicios u Oficios');
      expect(viewModel.coloniaComunidad, 'Colonia Lindavista');
      expect(viewModel.coloniaController.text, 'Colonia Lindavista');
      expect(viewModel.modalidad, 'mixto');
      expect(viewModel.selectedFotoPath, 'mifoto.jpg');
      expect(viewModel.fotoUrlController.text, 'mifoto.jpg');
    });

    test('clearForm limpia todos los campos y controladores de texto', () {
      viewModel.tituloController.text = 'Taladro';
      viewModel.descripcionController.text = 'Taladro en buen estado';
      viewModel.setCategoria('Herramientas');
      viewModel.setColoniaComunidad('Centro');
      viewModel.fotoUrlController.text = 'foto.png';
      viewModel.loQueBuscaController.text = 'Fruta';
      viewModel.precioEstimadoController.text = '100';

      viewModel.clearForm();

      expect(viewModel.tituloController.text, isEmpty);
      expect(viewModel.descripcionController.text, isEmpty);
      expect(viewModel.categoriaController.text, isEmpty);
      expect(viewModel.categoria, isEmpty);
      expect(viewModel.coloniaController.text, isEmpty);
      expect(viewModel.coloniaComunidad, isEmpty);
      expect(viewModel.fotoUrlController.text, isEmpty);
      expect(viewModel.loQueBuscaController.text, isEmpty);
      expect(viewModel.precioEstimadoController.text, isEmpty);
      expect(viewModel.modalidad, 'trueque');
      expect(viewModel.selectedFotoPath, isNull);
    });
  });

  group('CreateOfferViewModel - Proceso asíncrono y Criterios de Aceptación', () {
    test('CRITERIO DE ACEPTACIÓN: Una nueva oferta se publica de manera transparente y se limpian los campos del formulario tras la confirmación', () async {
      // 1. Llenar los datos del formulario en el ViewModel
      viewModel.tituloController.text = 'Mesa de madera de mezquite';
      viewModel.descripcionController.text = 'Hecha a mano en Dolores Hidalgo, madera maciza';
      viewModel.setCategoria('Bienes y Artículos');
      viewModel.setColoniaComunidad('Colonia Lindavista');
      viewModel.setFotoPath('mesa_artesanal.webp');
      viewModel.setModalidad('trueque');
      viewModel.loQueBuscaController.text = 'Bicicleta o herramientas de carpintería';

      // 2. Ejecutar publicación
      final bool exito = await viewModel.publishOffer(
        usuarioId: 'usr_don_chema',
      );

      // 3. Verificaciones de resultado y notificacion
      expect(exito, isTrue);
      expect(viewModel.isSuccess, isTrue);
      expect(viewModel.status, CreateOfferStatus.success);
      expect(viewModel.successMessage, isNotNull);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.createdOffer, isNotNull);
      expect(viewModel.createdOffer!.titulo, 'Mesa de madera de mezquite');
      expect(viewModel.createdOffer!.categoria, 'Bienes y Artículos');
      expect(viewModel.createdOffer!.fotoUrl, 'mesa_artesanal.webp');

      // 4. CRITERIO ESPECÍFICO: Los campos del formulario DEBEN quedar limpios tras la confirmación
      expect(viewModel.tituloController.text, isEmpty);
      expect(viewModel.descripcionController.text, isEmpty);
      expect(viewModel.categoriaController.text, isEmpty);
      expect(viewModel.categoria, isEmpty);
      expect(viewModel.fotoUrlController.text, isEmpty);
      expect(viewModel.selectedFotoPath, isNull);
      expect(viewModel.loQueBuscaController.text, isEmpty);
      expect(viewModel.precioEstimadoController.text, isEmpty);
      expect(viewModel.coloniaController.text, isEmpty);

      // Verificación en el repositorio persistido
      expect(repository.offers.length, 1);
      expect(repository.offers.first.titulo, 'Mesa de madera de mezquite');
    });

    test('Notifica error a la UI y preserva los campos del formulario si falla la validación', () async {
      // Formulario con formato de foto inválido
      viewModel.tituloController.text = 'Mesa de madera';
      viewModel.descripcionController.text = 'Madera maciza para comedor';
      viewModel.setCategoria('Bienes y Artículos');
      viewModel.setColoniaComunidad('Colonia Lindavista');
      viewModel.fotoUrlController.text = 'foto_invalida.pdf'; // Formato PDF prohibido

      final bool exito = await viewModel.publishOffer(
        usuarioId: 'usr_123',
      );

      expect(exito, isFalse);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.status, CreateOfferStatus.error);
      expect(viewModel.errorMessage, contains('El formato de la foto debe ser JPG, JPEG, PNG o WEBP'));
      expect(viewModel.isSuccess, isFalse);
      expect(viewModel.createdOffer, isNull);

      // Para no perder los datos del usuario en caso de error, los campos se mantienen
      expect(viewModel.tituloController.text, 'Mesa de madera');
      expect(viewModel.fotoUrlController.text, 'foto_invalida.pdf');

      // Limpieza de error
      viewModel.clearError();
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.status, CreateOfferStatus.initial);
    });

    test('Maneja excepciones del repositorio correctamente', () async {
      repository.shouldFail = true;

      viewModel.tituloController.text = 'Pintura exterior para fachada';
      viewModel.descripcionController.text = 'Cubeta de 19 litros color blanco ostión';
      viewModel.setCategoria('Materiales de Construcción');
      viewModel.setColoniaComunidad('Centro');
      viewModel.fotoUrlController.text = 'cubeta.jpg';

      final bool exito = await viewModel.publishOffer(
        usuarioId: 'usr_123',
      );

      expect(exito, isFalse);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.errorMessage, 'Error del servidor al registrar oferta');
      expect(viewModel.status, CreateOfferStatus.error);
    });
  });
}
