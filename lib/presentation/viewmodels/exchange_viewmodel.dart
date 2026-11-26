import 'package:flutter/material.dart';
import '../../domain/models/exchange_entity.dart';
import '../../domain/models/offer_entity.dart';
import '../../domain/usecases/propose_exchange_usecase.dart';

/// Estados del flujo de negociación de intercambio.
enum ExchangeStatus {
  initial,
  loading,
  success,
  error,
}

/// ViewModel para gestionar el flujo de propuestas y acuerdos de intercambio.
/// Controla el proceso asíncrono de envío, validación reactiva de la propuesta
/// y notificación del cambio de estado de la publicación a la UI.
class ExchangeViewModel extends ChangeNotifier {
  final ProposeExchangeUseCase _proposeExchangeUseCase;

  ExchangeStatus _status = ExchangeStatus.initial;
  String? _errorMessage;
  String? _successMessage;
  ExchangeEntity? _currentProposal;
  OfferEntity? _updatedOffer;

  final TextEditingController proposalController = TextEditingController();

  ExchangeViewModel({
    required ProposeExchangeUseCase proposeExchangeUseCase,
  }) : _proposeExchangeUseCase = proposeExchangeUseCase;

  // Getters reactivos
  ExchangeStatus get status => _status;
  bool get isLoading => _status == ExchangeStatus.loading;
  bool get isSuccess => _status == ExchangeStatus.success;
  bool get hasError => _status == ExchangeStatus.error;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  ExchangeEntity? get currentProposal => _currentProposal;
  OfferEntity? get updatedOffer => _updatedOffer;

  /// Limpia los campos del formulario de propuesta
  void clearForm() {
    proposalController.clear();
    notifyListeners();
  }

  /// Limpia mensaje de error activo
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      if (_status == ExchangeStatus.error) {
        _status = ExchangeStatus.initial;
      }
      notifyListeners();
    }
  }

  /// Restablece todo el estado a su valor inicial
  void reset() {
    clearForm();
    _status = ExchangeStatus.initial;
    _errorMessage = null;
    _successMessage = null;
    _currentProposal = null;
    _updatedOffer = null;
    notifyListeners();
  }

  /// Ejecuta el envío asíncrono de una propuesta de intercambio.
  /// Si tiene éxito, persiste la propuesta en Supabase, actualiza el estado
  /// de la publicación a "Pendiente de Aceptación" / "En propuesta" y limpia el formulario.
  Future<bool> sendProposal({
    required String offerId,
    required String usuarioProponenteId,
    String? propuesta,
    String? usuarioReceptorId,
  }) async {
    _status = ExchangeStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final textToSend = (propuesta ?? proposalController.text).trim();

      final result = await _proposeExchangeUseCase.execute(
        offerId: offerId,
        usuarioProponenteId: usuarioProponenteId,
        propuesta: textToSend,
        usuarioReceptorId: usuarioReceptorId,
      );

      _currentProposal = result.proposal;
      _updatedOffer = result.updatedOffer;
      _status = ExchangeStatus.success;
      _successMessage = '¡Propuesta de intercambio enviada con éxito!';
      _errorMessage = null;

      clearForm();
      notifyListeners();
      return true;
    } catch (e) {
      _status = ExchangeStatus.error;
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
    proposalController.dispose();
    super.dispose();
  }
}
