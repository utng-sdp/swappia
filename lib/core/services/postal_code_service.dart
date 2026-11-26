import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/dolores_hidalgo_constants.dart';

/// Opción de código postal devuelta para poblar el selector desplegable de C.P.
class PostalCodeOption {
  final String codigoPostal;
  final String municipio;
  final String estado;

  const PostalCodeOption({
    required this.codigoPostal,
    required this.municipio,
    required this.estado,
  });

  String get displayLabel => '$codigoPostal — $municipio';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostalCodeOption &&
          runtimeType == other.runtimeType &&
          codigoPostal == other.codigoPostal;

  @override
  int get hashCode => codigoPostal.hashCode;
}

/// Resultado detallado de un código postal mexicano con su estado, municipios y colonias.
class PostalCodeInfo {
  final String codigoPostal;
  final String estado;
  final List<String> municipios;
  final List<String> colonias;
  final bool fromFallback;

  const PostalCodeInfo({
    required this.codigoPostal,
    required this.estado,
    required this.municipios,
    required this.colonias,
    this.fromFallback = false,
  });

  String get primaryMunicipio => municipios.isNotEmpty ? municipios.first : '';
}

/// Servicio para consultar códigos postales de México mediante APIs públicas
/// (OpenDataSoft Geonames MX y Zippopotam.us MX) con caché en memoria y
/// respaldo local para Dolores Hidalgo, C.I.N. y municipios cercanos de Guanajuato.
class PostalCodeService {
  static final Map<String, PostalCodeInfo> _sharedCache = {};
  static List<PostalCodeOption>? _sharedPostalCodesCache;

  final http.Client _client;
  final bool _useSharedCache;
  final Duration timeout;

  final Map<String, PostalCodeInfo> _instanceCache = {};
  List<PostalCodeOption>? _instancePostalCodesCache;

  Map<String, PostalCodeInfo> get _cache =>
      _useSharedCache ? _sharedCache : _instanceCache;

  List<PostalCodeOption>? get _postalCodesCache =>
      _useSharedCache ? _sharedPostalCodesCache : _instancePostalCodesCache;

  set _postalCodesCache(List<PostalCodeOption>? value) {
    if (_useSharedCache) {
      _sharedPostalCodesCache = value;
    } else {
      _instancePostalCodesCache = value;
    }
  }

  PostalCodeService({
    http.Client? client,
    this.timeout = const Duration(seconds: 3),
  })  : _client = client ?? http.Client(),
        _useSharedCache = client == null;

  /// Catálogo local curado de respaldo (Dolores Hidalgo y Guanajuato).
  static const List<PostalCodeOption> fallbackPostalCodes = [
    PostalCodeOption(
      codigoPostal: '37800',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37803',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37804',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37805',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37806',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37807',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37810',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37812',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37813',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37814',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37815',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37816',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37817',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37819',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37820',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37825',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37830',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37840',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37849',
      municipio: 'Dolores Hidalgo Cuna de la Independencia Nacional',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37850',
      municipio: 'San Diego de la Unión',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37700',
      municipio: 'San Miguel de Allende',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '36000',
      municipio: 'Guanajuato',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37900',
      municipio: 'San Luis de la Paz',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '37000',
      municipio: 'León',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '38000',
      municipio: 'Celaya',
      estado: 'Guanajuato',
    ),
    PostalCodeOption(
      codigoPostal: '36500',
      municipio: 'Irapuato',
      estado: 'Guanajuato',
    ),
  ];

  static const Map<String, List<String>> _fallbackColoniasByCp = {
    '37800': [
      'Centro',
      'Colonia San Antonio',
      'Colonia El Calvario',
      'Colonia La Florida',
      'Colonia Lindavista',
      'Colonia La Campana',
      'Las Flores',
      'Loma Bonita',
      'La Esperanza',
    ],
    '37803': [
      'Valle Verde',
      'Mariano Balleza',
      'Héroes de San Cristóbal',
      'Vista Hermosa',
      'Los Olivos',
      'Gladiolas',
    ],
    '37804': [
      'Colonia Rinconada',
      'Fraccionamiento Los Pinos',
      'Fraccionamiento Guanajuato',
      'El Llanito',
    ],
    '37805': [
      'Insurgentes',
      'Bolaños',
      'San Pablo',
      'El Paraíso',
      'FOVISSSTE',
      'Ex Haciendas Pablo',
    ],
    '37806': [
      'Colonia 15 de Septiembre',
      'Fraccionamiento Cuna de la Independencia',
      'Las Águilas',
    ],
    '37807': ['San Cristóbal', 'Ejido Jesús María', 'Los Álamos'],
    '37810': ['Comunidad Río Laja', 'Comunidad La Erre', 'Adjuntas del Río'],
    '37815': ['Comunidad San Gabriel', 'Comunidad Tequisquiapan'],
    '37820': ['Comunidad Santa Teresa', 'Comunidad El Gallinero'],
    '37830': ['Comunidad Xoconoxtle', 'Comunidad San Marcos'],
    '37850': ['San Diego de la Unión Centro', 'La Sauceda'],
    '37700': ['San Miguel de Allende Centro', 'La Aldea', 'San Antonio'],
    '36000': ['Guanajuato Centro', 'Marfil', 'Pastita'],
    '37900': ['San Luis de la Paz Centro', 'Misión de Chichimecas'],
    '37000': ['León Centro', 'San Juan de Dios', 'Obregón'],
    '38000': ['Celaya Centro', 'Alameda', 'Las Fuentes'],
    '36500': ['Irapuato Centro', 'Las Reynas', 'Villas de Irapuato'],
  };

  /// Obtiene la lista de códigos postales disponibles para el dropdown de C.P.
  /// Combina resultados de la API OpenDataSoft Geonames MX con el catálogo local.
  Future<List<PostalCodeOption>> fetchPostalCodes({
    String estado = 'Guanajuato',
    String prefix = '378',
  }) async {
    if (_postalCodesCache != null) {
      return _postalCodesCache!;
    }

    final Map<String, PostalCodeOption> merged = {
      for (final item in fallbackPostalCodes) item.codigoPostal: item,
    };

    try {
      final uri = Uri.https(
        'data.opendatasoft.com',
        '/api/explore/v2.1/catalog/datasets/geonames-postal-code@public/records',
        {
          'select': 'postal_code, admin_name2, admin_name1',
          'where':
              'country_code="MX" AND admin_name1="$estado" AND startswith(postal_code, "$prefix")',
          'group_by': 'postal_code, admin_name2, admin_name1',
          'limit': '50',
        },
      );

      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final results = (decoded['results'] as List?) ?? const [];
        for (final raw in results) {
          if (raw is Map<String, dynamic>) {
            final cp = (raw['postal_code'] ?? '').toString().trim();
            final municipio = (raw['admin_name2'] ?? '').toString().trim();
            final stateName = (raw['admin_name1'] ?? estado).toString().trim();
            if (cp.isNotEmpty && municipio.isNotEmpty) {
              merged[cp] = PostalCodeOption(
                codigoPostal: cp,
                municipio: municipio,
                estado: stateName,
              );
            }
          }
        }
      }
    } catch (_) {
      // Silencioso: conserva el catálogo local curado como respaldo.
    }

    final list = merged.values.toList()
      ..sort((a, b) => a.codigoPostal.compareTo(b.codigoPostal));
    _postalCodesCache = list;
    return list;
  }

  /// Consulta municipio(s) y colonias a partir de un código postal usando
  /// OpenDataSoft Geonames MX y Zippopotam.us MX en paralelo.
  Future<PostalCodeInfo> fetchByPostalCode(String codigoPostal) async {
    final cp = codigoPostal.trim();
    if (_cache.containsKey(cp)) {
      return _cache[cp]!;
    }

    final results = await Future.wait([
      _fetchOpenDataSoftByCp(cp),
      _fetchZippopotamByCp(cp),
    ]);

    final ods = results[0];
    final zip = results[1];

    String estado = '';
    final Set<String> municipios = <String>{};
    final Set<String> colonias = <String>{};

    if (ods != null) {
      if (ods.estado.isNotEmpty) estado = ods.estado;
      municipios.addAll(ods.municipios.where((m) => m.trim().isNotEmpty));
      colonias.addAll(ods.colonias.where((c) => c.trim().isNotEmpty));
    }

    if (zip != null) {
      if (estado.isEmpty && zip.estado.isNotEmpty) estado = zip.estado;
      municipios.addAll(zip.municipios.where((m) => m.trim().isNotEmpty));
      colonias.addAll(zip.colonias.where((c) => c.trim().isNotEmpty));
    }

    final bool usedFallback = municipios.isEmpty && colonias.isEmpty;
    if (usedFallback) {
      final fallback = _buildFallbackInfo(cp);
      _cache[cp] = fallback;
      return fallback;
    }

    if (municipios.isEmpty) {
      final match = fallbackPostalCodes.where((o) => o.codigoPostal == cp);
      if (match.isNotEmpty) {
        municipios.add(match.first.municipio);
        if (estado.isEmpty) estado = match.first.estado;
      } else if (cp.startsWith('378')) {
        municipios.add('Dolores Hidalgo Cuna de la Independencia Nacional');
        if (estado.isEmpty) estado = 'Guanajuato';
      }
    }

    if (colonias.isEmpty) {
      colonias.addAll(_fallbackColoniasForCp(cp));
    }

    final sortedColonias = colonias.toList()..sort();
    final info = PostalCodeInfo(
      codigoPostal: cp,
      estado: estado.isNotEmpty ? estado : 'Guanajuato',
      municipios: municipios.toList(),
      colonias: sortedColonias,
      fromFallback: false,
    );
    _cache[cp] = info;
    return info;
  }

  Future<PostalCodeInfo?> _fetchOpenDataSoftByCp(String cp) async {
    try {
      final uri = Uri.https(
        'data.opendatasoft.com',
        '/api/explore/v2.1/catalog/datasets/geonames-postal-code@public/records',
        {
          'where': 'country_code="MX" AND postal_code="$cp"',
          'limit': '100',
        },
      );
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = (decoded['results'] as List?) ?? const [];
      if (rows.isEmpty) return null;

      String estado = '';
      final Set<String> municipios = <String>{};
      final Set<String> colonias = <String>{};

      for (final raw in rows) {
        if (raw is Map<String, dynamic>) {
          final stateName = (raw['admin_name1'] ?? '').toString().trim();
          final mun = (raw['admin_name2'] ?? '').toString().trim();
          final col = (raw['place_name'] ?? '').toString().trim();
          if (estado.isEmpty && stateName.isNotEmpty) estado = stateName;
          if (mun.isNotEmpty) municipios.add(mun);
          if (col.isNotEmpty) colonias.add(col);
        }
      }

      return PostalCodeInfo(
        codigoPostal: cp,
        estado: estado,
        municipios: municipios.toList(),
        colonias: colonias.toList(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<PostalCodeInfo?> _fetchZippopotamByCp(String cp) async {
    try {
      final uri = Uri.https('api.zippopotam.us', '/mx/$cp');
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final places = (decoded['places'] as List?) ?? const [];
      if (places.isEmpty) return null;

      String estado = '';
      final Set<String> colonias = <String>{};

      for (final raw in places) {
        if (raw is Map<String, dynamic>) {
          final stateName = (raw['state'] ?? '').toString().trim();
          final placeName = (raw['place name'] ?? '').toString().trim();
          if (estado.isEmpty && stateName.isNotEmpty) estado = stateName;
          if (placeName.isNotEmpty) colonias.add(placeName);
        }
      }

      return PostalCodeInfo(
        codigoPostal: cp,
        estado: estado,
        municipios: const [],
        colonias: colonias.toList(),
      );
    } catch (_) {
      return null;
    }
  }

  PostalCodeInfo _buildFallbackInfo(String cp) {
    final match = fallbackPostalCodes.where((o) => o.codigoPostal == cp);
    final municipio = match.isNotEmpty
        ? match.first.municipio
        : (cp.startsWith('378')
            ? 'Dolores Hidalgo Cuna de la Independencia Nacional'
            : 'Dolores Hidalgo Cuna de la Independencia Nacional');
    final estado = match.isNotEmpty ? match.first.estado : 'Guanajuato';
    final colonias = _fallbackColoniasForCp(cp);

    return PostalCodeInfo(
      codigoPostal: cp,
      estado: estado,
      municipios: [municipio],
      colonias: colonias,
      fromFallback: true,
    );
  }

  List<String> _fallbackColoniasForCp(String cp) {
    if (_fallbackColoniasByCp.containsKey(cp)) {
      return List<String>.from(_fallbackColoniasByCp[cp]!);
    }
    return List<String>.from(DoloresHidalgoConstants.coloniasYComunidades);
  }

  void clearCache() {
    _cache.clear();
    _postalCodesCache = null;
  }
}
