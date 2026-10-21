import 'package:flutter/material.dart';
import '../../domain/models/offer_entity.dart';
import '../../domain/usecases/publish_offer_usecase.dart';

/// Estados del ciclo de vida de publicacion de una oferta
enum CreateOfferStatus {
  initial,
  loading,
  success,
  error,
}

/// ViewModel para la gestion y publicacion de ofertas en la comunidad.
/// Gestiona el proceso asincrono de envio, notificaciones de estado y
/// la limpieza reactiva de los campos tras la confirmacion.
class CreateOfferViewModel extends ChangeNotifier {
  final PublishOfferUseCase _publishOfferUseCase;

  CreateOfferStatus _status = CreateOfferStatus.initial;
  String? _errorMessage;
  String? _successMessage;
  OfferEntity? _createdOffer;

  // Controladores de texto para integracion directa con formularios UI
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();
  final TextEditingController fotoUrlController = TextEditingController();
  final TextEditingController loQueBuscaController = TextEditingController();
  final TextEditingController precioEstimadoController = TextEditingController();
  final TextEditingController coloniaController = TextEditingController();

  // Estados seleccionables del formulario
  String _categoria = '';
  String _coloniaComunidad = '';
  String _modalidad = 'trueque'; // 'trueque', 'dinero', 'mixto'
  String? _selectedFotoPath;

  CreateOfferViewModel({
    required PublishOfferUseCase publishOfferUseCase,
  }) : _publishOfferUseCase = publishOfferUseCase;

  // Getters de estado reactivo
  CreateOfferStatus get status => _status;
  bool get isLoading => _status == CreateOfferStatus.loading;
  bool get isSuccess => _status == CreateOfferStatus.success;
  bool get hasError => _status == CreateOfferStatus.error;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  OfferEntity? get createdOffer => _createdOffer;

  String get categoria => _categoria;
  String get coloniaComunidad => _coloniaComunidad;
  String get modalidad => _modalidad;
  String? get selectedFotoPath => _selectedFotoPath;

  // Actualizadores de campos seleccionables
  void setCategoria(String nuevaCategoria) {
    _categoria = nuevaCategoria;
    categoriaController.text = nuevaCategoria;
    notifyListeners();
  }

  void setColoniaComunidad(String nuevaColonia) {
    _coloniaComunidad = nuevaColonia;
    coloniaController.text = nuevaColonia;
    notifyListeners();
  }

  void setModalidad(String nuevaModalidad) {
    _modalidad = nuevaModalidad;
    notifyListeners();
  }

  void setFotoPath(String path) {
    _selectedFotoPath = path;
    fotoUrlController.text = path;
    notifyListeners();
  }

  /// Limpia los campos del formulario tras la confirmacion exitosa o cancelacion.
  /// Cumple directamente con el criterio de aceptacion del requerimiento.
  void clearForm() {
    tituloController.clear();
    descripcionController.clear();
    categoriaController.clear();
    fotoUrlController.clear();
    loQueBuscaController.clear();
    precioEstimadoController.clear();
    coloniaController.clear();
    _categoria = '';
    _coloniaComunidad = '';
    _modalidad = 'trueque';
    _selectedFotoPath = null;
    notifyListeners();
  }

  /// Restablece tanto el formulario como los estados de exito y error
  void reset() {
    clearForm();
    _status = CreateOfferStatus.initial;
    _errorMessage = null;
    _successMessage = null;
    _createdOffer = null;
    notifyListeners();
  }

  /// Limpia el mensaje de error activo
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      if (_status == CreateOfferStatus.error) {
        _status = CreateOfferStatus.initial;
      }
      notifyListeners();
    }
  }

  /// Maneja el proceso asincrono de envio de la oferta a la capa de dominio.
  /// Si se omiten argumentos opcionales, se extraen automaticamente de los controladores de texto.
  Future<bool> publishOffer({
    String? titulo,
    String? descripcion,
    String? categoria,
    String? coloniaComunidad,
    String? usuarioId,
    String? fotoUrl,
    String? modalidad,
    String? loQueBusca,
    double? precioEstimado,
  }) async {
    _status = CreateOfferStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final finalTitulo = (titulo ?? tituloController.text).trim();
      final finalDescripcion = (descripcion ?? descripcionController.text).trim();
      final finalCategoria = (categoria ?? (_categoria.isNotEmpty ? _categoria : categoriaController.text)).trim();
      final finalColonia = (coloniaComunidad ?? (_coloniaComunidad.isNotEmpty ? _coloniaComunidad : coloniaController.text)).trim();
      final finalFoto = (fotoUrl ?? (_selectedFotoPath ?? fotoUrlController.text)).trim();
      final finalModalidad = modalidad ?? _modalidad;
      final finalLoQueBusca = (loQueBusca ?? loQueBuscaController.text).trim();
      final finalUsuarioId = (usuarioId ?? '').trim();

      double? parsedPrecio = precioEstimado;
      if (parsedPrecio == null && precioEstimadoController.text.trim().isNotEmpty) {
        parsedPrecio = double.tryParse(precioEstimadoController.text.trim());
      }

      final result = await _publishOfferUseCase.execute(
        titulo: finalTitulo,
        descripcion: finalDescripcion,
        categoria: finalCategoria,
        coloniaComunidad: finalColonia,
        usuarioId: finalUsuarioId,
        fotoUrl: finalFoto,
        modalidad: finalModalidad,
        loQueBusca: finalLoQueBusca.isNotEmpty ? finalLoQueBusca : null,
        precioEstimado: parsedPrecio,
      );

      _createdOffer = result;
      _status = CreateOfferStatus.success;
      _successMessage = '¡Oferta publicada exitosamente!';
      _errorMessage = null;

      // Criterio de aceptacion: se limpian los campos del formulario tras la confirmacion
      clearForm();
      notifyListeners();
      return true;
    } catch (e) {
      _status = CreateOfferStatus.error;
      _errorMessage = _cleanExceptionMessage(e);
      _successMessage = null;
      notifyListeners();
      return false;
    }
  }

  String _cleanExceptionMessage(dynamic error) {
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str;
  }

  @override
  void dispose() {
    tituloController.dispose();
    descripcionController.dispose();
    categoriaController.dispose();
    fotoUrlController.dispose();
    loQueBuscaController.dispose();
    precioEstimadoController.dispose();
    coloniaController.dispose();
    super.dispose();
  }
}
