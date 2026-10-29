import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/offer_entity.dart';
import '../../domain/repositories/offer_repository.dart';

/// ViewModel para la gestión del Feed principal de ofertas comunitarias.
/// Provee carga de publicaciones, búsqueda en tiempo real con debounce
/// y filtrado reactivo de ofertas locales.
class FeedViewModel extends ChangeNotifier {
  final OfferRepository _offerRepository;
  final Duration debounceDuration;

  List<OfferEntity> _allOffers = [];
  List<OfferEntity> _filteredOffers = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  final TextEditingController searchController = TextEditingController();

  FeedViewModel({
    required OfferRepository offerRepository,
    this.debounceDuration = const Duration(milliseconds: 350),
  }) : _offerRepository = offerRepository;

  // Getters reactivos
  List<OfferEntity> get offers => _filteredOffers;
  List<OfferEntity> get allOffers => _allOffers;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  int get count => _filteredOffers.length;
  bool get hasActiveSearch => _searchQuery.trim().isNotEmpty;

  /// Carga las ofertas desde el repositorio. Si el repositorio no tiene datos,
  /// inicializa publicaciones de ejemplo de Dolores Hidalgo para permitir interacción inmediata.
  Future<void> loadOffers({String? colonia, bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<OfferEntity> loaded;
      if (colonia != null && colonia.isNotEmpty) {
        loaded = await _offerRepository.getOffersByColonia(colonia);
      } else {
        loaded = await _offerRepository.getOffers();
      }

      // Si no hay ofertas registradas aún, poblamos con publicaciones iniciales comunitarias
      if (loaded.isEmpty) {
        loaded = _getInitialSampleOffers(colonia: colonia);
      }

      _allOffers = loaded;
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar ofertas: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Maneja los cambios de texto en la barra de búsqueda aplicando un Debounce.
  /// Evita saturar la UI y el motor de búsqueda en cada pulsación de tecla.
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();

    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      _searchQuery = '';
      _applyFilter();
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(debounceDuration, () {
      _searchQuery = cleanQuery;
      _applyFilter();
      notifyListeners();
    });
  }

  /// Ejecuta la búsqueda de forma inmediata sin esperar el tiempo de debounce.
  void searchImmediate(String query) {
    _debounceTimer?.cancel();
    _searchQuery = query.trim();
    searchController.text = query;
    _applyFilter();
    notifyListeners();
  }

  /// Limpia la barra de búsqueda y restablece el listado completo de ofertas.
  void clearSearch() {
    _debounceTimer?.cancel();
    _searchQuery = '';
    searchController.clear();
    _applyFilter();
    notifyListeners();
  }

  /// Agrega una nueva oferta en la parte superior del feed (ej. recién creada)
  void addOffer(OfferEntity offer) {
    _allOffers.insert(0, offer);
    _applyFilter();
    notifyListeners();
  }

  /// Aplica el filtro de búsqueda sobre `_allOffers`
  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredOffers = List.from(_allOffers);
      return;
    }

    final queryLower = _searchQuery.toLowerCase();
    _filteredOffers = _allOffers.where((offer) {
      final matchTitulo = offer.titulo.toLowerCase().contains(queryLower);
      final matchDescripcion =
          offer.descripcion.toLowerCase().contains(queryLower);
      final matchCategoria = offer.categoria.toLowerCase().contains(queryLower);
      final matchColonia =
          offer.coloniaComunidad.toLowerCase().contains(queryLower);
      final matchLoQueBusca =
          offer.loQueBusca?.toLowerCase().contains(queryLower) ?? false;
      final matchModalidad =
          offer.modalidad.toLowerCase().contains(queryLower);

      return matchTitulo ||
          matchDescripcion ||
          matchCategoria ||
          matchColonia ||
          matchLoQueBusca ||
          matchModalidad;
    }).toList();
  }

  /// Publicaciones iniciales de muestra para la comunidad de Dolores Hidalgo
  List<OfferEntity> _getInitialSampleOffers({String? colonia}) {
    final now = DateTime.now();
    return [
      OfferEntity(
        id: 'sample-offer-1',
        usuarioId: 'usr-chema',
        titulo: 'Herramientas de Jardinería y Podadora',
        descripcion:
            'Presto juego completo de herramientas para jardín (podadora manual, tijeras de poda y rastrillo) en excelente estado.',
        categoria: 'Herramientas y Maquinaria',
        coloniaComunidad: colonia ?? 'Centro',
        fotoUrl: 'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?w=600',
        modalidad: 'trueque',
        loQueBusca: 'Fruta de temporada o asesoría básica de plomería',
        fechaPublicacion: now.subtract(const Duration(hours: 2)),
        activa: true,
      ),
      OfferEntity(
        id: 'sample-offer-2',
        usuarioId: 'usr-elena',
        titulo: 'Clases de Matemáticas para Secundaria y Preparatoria',
        descripcion:
            'Profesora jubilada ofrece regularización y asesorías personalizadas de álgebra, geometría y cálculo básico.',
        categoria: 'Educación y Asesoría',
        coloniaComunidad: colonia ?? 'Colonia Lindavista',
        fotoUrl: 'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=600',
        modalidad: 'mixto',
        loQueBusca: 'Despensa básica o frutas',
        precioEstimado: 50.0,
        fechaPublicacion: now.subtract(const Duration(hours: 5)),
        activa: true,
      ),
      OfferEntity(
        id: 'sample-offer-3',
        usuarioId: 'usr-carlos',
        titulo: 'Bicicleta de Montaña Rodada 26',
        descripcion:
            'Bicicleta de montaña en muy buen estado, llantas seminuevas y frenos recién ajustados. Ideal para traslados en la ciudad.',
        categoria: 'Bienes',
        coloniaComunidad: colonia ?? 'Colonia La Florida',
        fotoUrl: 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=600',
        modalidad: 'trueque',
        loQueBusca: 'Taladro percutor o mano de obra en pintura',
        fechaPublicacion: now.subtract(const Duration(days: 1)),
        activa: true,
      ),
      OfferEntity(
        id: 'sample-offer-4',
        usuarioId: 'usr-dona-luz',
        titulo: 'Reparación y Ajuste de Prendas (Costura)',
        descripcion:
            'Ajusto dobladillos, cambio de cierres y costura en general. Trabajo rápido y garantizado en Dolores Hidalgo.',
        categoria: 'Costura',
        coloniaComunidad: colonia ?? 'Colonia San Antonio',
        fotoUrl: 'https://images.unsplash.com/photo-1528458876885-54424332497b?w=600',
        modalidad: 'dinero',
        precioEstimado: 80.0,
        fechaPublicacion: now.subtract(const Duration(days: 2)),
        activa: true,
      ),
    ];
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }
}

