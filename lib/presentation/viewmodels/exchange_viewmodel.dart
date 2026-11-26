import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/exchange_entity.dart';
import '../../domain/models/offer_entity.dart';
import '../../domain/models/user_entity.dart';
import '../../domain/repositories/exchange_repository.dart';
import '../../domain/usecases/propose_exchange_usecase.dart';
import '../../domain/usecases/rate_user_usecase.dart';

/// Estados del flujo de negociación de intercambio.
enum ExchangeStatus {
  initial,
  loading,
  success,
  error,
}

/// ViewModel para gestionar el flujo de propuestas y acuerdos de intercambio.
/// Controla el proceso asíncrono de envío, validación reactiva de la propuesta,
/// suscripción a Supabase Realtime (WebSockets) y el procesamiento de calificaciones con RateUserUseCase.
class ExchangeViewModel extends ChangeNotifier {
  final ProposeExchangeUseCase _proposeExchangeUseCase;
  final RateUserUseCase? _rateUserUseCase;
  final ExchangeRepository? _exchangeRepository;

  ExchangeStatus _status = ExchangeStatus.initial;
  String? _errorMessage;
  String? _successMessage;
  ExchangeEntity? _currentProposal;
  OfferEntity? _updatedOffer;
  UserEntity? _ratedUser;
  bool _isRatingSubmitting = false;

  StreamSubscription<ExchangeEntity>? _realtimeSubscription;

  final TextEditingController proposalController = TextEditingController();

  ExchangeViewModel({
    required ProposeExchangeUseCase proposeExchangeUseCase,
    RateUserUseCase? rateUserUseCase,
    ExchangeRepository? exchangeRepository,
  })  : _proposeExchangeUseCase = proposeExchangeUseCase,
        _rateUserUseCase = rateUserUseCase,
        _exchangeRepository = exchangeRepository;

  // Getters reactivos
  ExchangeStatus get status => _status;
  bool get isLoading => _status == ExchangeStatus.loading;
  bool get isSuccess => _status == ExchangeStatus.success;
  bool get hasError => _status == ExchangeStatus.error;
  bool get isRatingSubmitting => _isRatingSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  ExchangeEntity? get currentProposal => _currentProposal;
  OfferEntity? get updatedOffer => _updatedOffer;
  UserEntity? get ratedUser => _ratedUser;

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

  /// Restablece todo el estado a su valor inicial y cancela suscripciones
  void reset() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    clearForm();
    _status = ExchangeStatus.initial;
    _errorMessage = null;
    _successMessage = null;
    _currentProposal = null;
    _updatedOffer = null;
    _ratedUser = null;
    _isRatingSubmitting = false;
    notifyListeners();
  }

  /// Suscribe el ViewModel a eventos en vivo mediante WebSockets con Supabase Realtime.
  /// Cuando la propuesta cambia de estado (ej. de 'pendiente' a 'aceptada'),
  /// se actualiza automáticamente el estado local y se notifica a la UI en vivo.
  void subscribeToExchangeUpdates({String? offerId, String? exchangeId}) {
    if (_exchangeRepository == null) return;

    _realtimeSubscription?.cancel();
    _realtimeSubscription = _exchangeRepository!
        .listenToExchangeUpdates(offerId: offerId, exchangeId: exchangeId)
        .listen((updatedExchange) {
      _currentProposal = updatedExchange;

      // Si la propuesta fue aceptada, actualizar el estado de la oferta y mostrar banner
      if (updatedExchange.estaAceptada) {
        if (_updatedOffer != null) {
          _updatedOffer = _updatedOffer!.copyWith(estado: 'aceptada');
        }
        _successMessage = '¡Tu propuesta ha sido aceptada por el vecino!';
      }
      notifyListeners();
    });
  }

  /// Cancela la suscripción a Realtime
  void unsubscribeFromExchangeUpdates() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }

  /// Ejecuta el envío asíncrono de una propuesta de intercambio.
  /// Si tiene éxito, persiste la propuesta en Supabase, actualiza el estado
  /// de la publicación a "Pendiente de Aceptación" / "En propuesta", activa Realtime
  /// y notifica a los listeners.
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

      // Iniciar escucha en tiempo real para esta propuesta
      subscribeToExchangeUpdates(
        offerId: offerId,
        exchangeId: result.proposal.id,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _status = ExchangeStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _successMessage = null;
      notifyListeners();
      return false;
    }
  }

  /// Procesa el envío de reseñas y calificaciones a un vecino mediante RateUserUseCase.
  Future<bool> rateUser({
    required String targetUserId,
    required String reviewerUserId,
    required double rating,
    String? comment,
  }) async {
    if (_rateUserUseCase == null) {
      _errorMessage = 'El servicio de calificaciones no está disponible.';
      notifyListeners();
      return false;
    }

    _isRatingSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _rateUserUseCase!.execute(
        targetUserId: targetUserId,
        reviewerUserId: reviewerUserId,
        rating: rating,
        comment: comment,
      );

      _ratedUser = updatedUser;
      _isRatingSubmitting = false;
      _successMessage = '¡Gracias! Tu reseña ha sido registrada exitosamente.';
      notifyListeners();
      return true;
    } catch (e) {
      _isRatingSubmitting = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Permite actualizar la propuesta manualmente o en pruebas
  void setCurrentProposal(ExchangeEntity proposal) {
    _currentProposal = proposal;
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    proposalController.dispose();
    super.dispose();
  }
}
