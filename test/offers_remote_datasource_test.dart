import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:swappia_app/data/datasources/remote/offers_remote_datasource.dart';
import 'package:swappia_app/data/models/offer_model.dart';
import 'package:swappia_app/data/repositories/offer_repository_impl.dart';
import 'package:swappia_app/domain/models/offer_entity.dart';

void main() {
  group('OffersRemoteDataSource & Storage Tests', () {
    test('SupabaseOffersRemoteDataSource implementa el contrato OffersRemoteDataSource', () {
      final remoteDataSource = SupabaseOffersRemoteDataSource();
      expect(remoteDataSource, isA<OffersRemoteDataSource>());
    });

    test(
        'Criterio de Aceptación: Las imágenes se suben al Storage y la URL generada se guarda correctamente en la fila de la oferta',
        () async {
      final remoteDataSource = MockOffersRemoteDataSource();
      final repository = OfferRepositoryImpl(remoteDataSource: remoteDataSource);

      // 1. Simulación de subida de imagen de la oferta a Supabase Storage (bucket: offer_images)
      final dummyBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header
      final uploadedImageUrl = await remoteDataSource.uploadOfferImage(
        filePath: 'test_path/taladro.png',
        fileBytes: dummyBytes,
        fileName: 'taladro_bosch.png',
      );

      expect(uploadedImageUrl, isNotEmpty);
      expect(uploadedImageUrl, contains('offer_images'));
      expect(uploadedImageUrl, contains('taladro_bosch.png'));

      // 2. Persistencia de la oferta en PostgreSQL conteniendo la URL generada
      const newOffer = OfferEntity(
        id: 'temp-1234',
        usuarioId: 'usr-pardo-001',
        titulo: 'Taladro Percutor Bosch 650W',
        descripcion: 'Herramienta en excelente estado con caja y brocas incluidas',
        categoria: 'Herramientas',
        coloniaComunidad: 'La Lindavista',
        fotoUrl: '', // Se asignará con la URL de Storage
        modalidad: 'trueque',
        loQueBusca: 'Servicio de plomería o soldadura',
      );

      final offerWithStorageImage = newOffer.copyWith(fotoUrl: uploadedImageUrl);

      final published = await repository.publishOffer(offerWithStorageImage);

      // Verificación de integridad en la fila de la oferta persistida
      expect(published.id, isNotEmpty);
      expect(published.fotoUrl, uploadedImageUrl);
      expect(published.titulo, 'Taladro Percutor Bosch 650W');
      expect(published.coloniaComunidad, 'La Lindavista');
      expect(published.usuarioId, 'usr-pardo-001');
      expect(published.activa, isTrue);

      // 3. Consulta desde la base de datos remota
      final offers = await repository.getOffers();
      expect(offers, isNotEmpty);
      expect(offers.first.fotoUrl, uploadedImageUrl);

      final filteredByColonia =
          await repository.getOffersByColonia('La Lindavista');
      expect(filteredByColonia, isNotEmpty);
      expect(filteredByColonia.first.titulo, 'Taladro Percutor Bosch 650W');
    });

    test('OfferModel mapea e intercambia tipos correctamente con PostgreSQL', () {
      final postgresRow = {
        'id': 'b8f2c3d4-1111-2222-3333-abcdef123456',
        'usuario_id': 'usr-789',
        'titulo': 'Miel pura de abeja artesanal',
        'descripcion': 'Frasco de 1 litro de miel cosechada en comunidad El Llanito',
        'categoria': 'Alimentos',
        'colonia_comunidad': 'El Llanito',
        'foto_url': 'https://storage.supabase.co/offer_images/miel.jpg',
        'modalidad': 'mixto',
        'lo_que_busca': 'Herramienta de jardín o 100 pesos',
        'precio_estimado': 120.50,
        'fecha_publicacion': '2026-10-21T02:00:00.000Z',
        'activa': true,
      };

      final model = OfferModel.fromJson(postgresRow);

      expect(model.id, 'b8f2c3d4-1111-2222-3333-abcdef123456');
      expect(model.usuarioId, 'usr-789');
      expect(model.titulo, 'Miel pura de abeja artesanal');
      expect(model.categoria, 'Alimentos');
      expect(model.coloniaComunidad, 'El Llanito');
      expect(model.modalidad, 'mixto');
      expect(model.precioEstimado, 120.50);
      expect(model.activa, isTrue);

      final entity = model.toEntity();
      expect(entity.tieneTituloValido, isTrue);
      expect(entity.tieneDescripcionValida, isTrue);
      expect(entity.tieneFoto, isTrue);
      expect(entity.esMixto, isTrue);
      expect(entity.esTruequePuro, isFalse);

      final jsonBack = model.toJson();
      expect(jsonBack['colonia_comunidad'], 'El Llanito');
      expect(jsonBack['foto_url'], 'https://storage.supabase.co/offer_images/miel.jpg');
      expect(jsonBack['precio_estimado'], 120.50);
    });

    test('Desactivación y eliminación de oferta remota', () async {
      final remoteDataSource = MockOffersRemoteDataSource();
      final repository = OfferRepositoryImpl(remoteDataSource: remoteDataSource);

      const offer = OfferEntity(
        id: 'off-delete-test',
        usuarioId: 'usr-1',
        titulo: 'Bicicleta de montaña',
        descripcion: 'Rodada 26 en buen estado funcional',
        categoria: 'Bicicletas',
        coloniaComunidad: 'Centro',
        fotoUrl: 'https://storage.supabase.co/offer_images/bici.jpg',
      );

      await repository.publishOffer(offer);
      expect(await repository.getOfferById('off-delete-test'), isNotNull);

      await repository.deleteOffer('off-delete-test');
      expect(await repository.getOfferById('off-delete-test'), isNull);
    });
  });
}
