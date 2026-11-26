import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swappia_app/core/services/postal_code_service.dart';
import 'package:swappia_app/presentation/widgets/postal_code_location_selector.dart';

void main() {
  group('PostalCodeService API & Cascading Dropdowns', () {
    test('Combina respuestas de OpenDataSoft y Zippopotam para un C.P. y usa caché',
        () async {
      int calls = 0;
      final mockClient = MockClient((request) async {
        calls++;
        if (request.url.host.contains('opendatasoft.com')) {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'postal_code': '37803',
                  'admin_name1': 'Guanajuato',
                  'admin_name2': 'Dolores Hidalgo Cuna de la Independencia Nacional',
                  'place_name': 'Valle Verde',
                },
                {
                  'postal_code': '37803',
                  'admin_name1': 'Guanajuato',
                  'admin_name2': 'Dolores Hidalgo Cuna de la Independencia Nacional',
                  'place_name': 'Mariano Balleza',
                },
              ],
            }),
            200,
          );
        }
        if (request.url.host.contains('zippopotam.us')) {
          return http.Response(
            jsonEncode({
              'country': 'Mexico',
              'post code': '37803',
              'places': [
                {'place name': 'Vista Hermosa', 'state': 'Guanajuato'},
              ],
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = PostalCodeService(client: mockClient);
      final info = await service.fetchByPostalCode('37803');

      expect(info.fromFallback, isFalse);
      expect(info.estado, 'Guanajuato');
      expect(
        info.municipios,
        contains('Dolores Hidalgo Cuna de la Independencia Nacional'),
      );
      expect(info.colonias, containsAll(['Valle Verde', 'Mariano Balleza', 'Vista Hermosa']));

      // Segunda llamada debe usar caché sin hacer nuevas peticiones HTTP
      final callsBeforeCache = calls;
      final cachedInfo = await service.fetchByPostalCode('37803');
      expect(cachedInfo.colonias, info.colonias);
      expect(calls, callsBeforeCache);
    });

    test('Usa respaldo local si las APIs fallan o devuelven error', () async {
      final failingClient = MockClient((_) async => http.Response('Error', 500));
      final service = PostalCodeService(client: failingClient);

      final info = await service.fetchByPostalCode('37800');
      expect(info.fromFallback, isTrue);
      expect(info.municipios, isNotEmpty);
      expect(info.colonias, contains('Centro'));
    });

    testWidgets(
        'PostalCodeLocationSelector llena Municipio y Colonia al elegir Código Postal',
        (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.host.contains('opendatasoft.com') &&
            request.url.query.contains('group_by')) {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'postal_code': '37805',
                  'admin_name1': 'Guanajuato',
                  'admin_name2': 'Dolores Hidalgo Cuna de la Independencia Nacional',
                },
              ],
            }),
            200,
          );
        }
        if (request.url.host.contains('opendatasoft.com')) {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'admin_name1': 'Guanajuato',
                  'admin_name2': 'Dolores Hidalgo Cuna de la Independencia Nacional',
                  'place_name': 'Insurgentes',
                },
                {
                  'admin_name1': 'Guanajuato',
                  'admin_name2': 'Dolores Hidalgo Cuna de la Independencia Nacional',
                  'place_name': 'San Pablo',
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'places': [
              {'place name': 'FOVISSSTE', 'state': 'Guanajuato'},
            ],
          }),
          200,
        );
      });

      final service = PostalCodeService(client: mockClient);
      String? lastCp;
      String? lastMun;
      String? lastCol;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: PostalCodeLocationSelector(
                postalCodeService: service,
                cpDropdownKey: const Key('test_cp_dropdown'),
                municipioDropdownKey: const Key('test_mun_dropdown'),
                coloniaDropdownKey: const Key('test_col_dropdown'),
                onLocationChanged: ({codigoPostal, municipio, colonia}) {
                  lastCp = codigoPostal;
                  lastMun = municipio;
                  lastCol = colonia;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abrir dropdown de Código Postal y elegir 37805
      await tester.tap(find.byKey(const Key('test_cp_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('37805 — Dolores Hidalgo Cuna de la Independencia Nacional').last,
      );
      await tester.pumpAndSettle();

      expect(lastCp, '37805');
      expect(lastMun, 'Dolores Hidalgo Cuna de la Independencia Nacional');
      expect(lastCol, isNotNull);

      // Abrir dropdown de Colonia y elegir 'San Pablo' llenada desde la API
      await tester.tap(find.byKey(const Key('test_col_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('San Pablo').last);
      await tester.pumpAndSettle();

      expect(lastCol, 'San Pablo');
    });
  });
}
