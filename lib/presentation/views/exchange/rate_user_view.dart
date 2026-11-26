import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/exchange_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_banner.dart';
import '../feed/feed_view.dart';

/// Argumentos de navegación para [RateUserView].
class RateUserArgs {
  final String targetUserId;
  final String targetUserName;
  final String? exchangeId;
  final String? offerTitle;

  const RateUserArgs({
    required this.targetUserId,
    required this.targetUserName,
    this.exchangeId,
    this.offerTitle,
  });
}

/// Pantalla "Calificar Vecino" (Issue #22).
/// Presenta selector interactivo de 1 a 5 estrellas, caja de comentario,
/// envío mediante [ExchangeViewModel.rateUser] (o callback desacoplado)
/// y confirmación visual de agradecimiento.
class RateUserView extends StatefulWidget {
  static const String routeName = '/rate-user';

  final String targetUserId;
  final String targetUserName;
  final String? exchangeId;
  final String? offerTitle;
  final Future<bool> Function(double rating, String comment)? onSubmitRating;

  const RateUserView({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.exchangeId,
    this.offerTitle,
    this.onSubmitRating,
  });

  @override
  State<RateUserView> createState() => _RateUserViewState();
}

class _RateUserViewState extends State<RateUserView> {
  final TextEditingController _commentController = TextEditingController();
  double _selectedRating = 5.0;
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _ratingLabel(double stars) {
    switch (stars.round()) {
      case 1:
        return 'Mala experiencia (1/5)';
      case 2:
        return 'Regular (2/5)';
      case 3:
        return 'Aceptable (3/5)';
      case 4:
        return 'Muy buena experiencia (4/5)';
      case 5:
      default:
        return '¡Excelente vecino! (5/5)';
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final comment = _commentController.text.trim();
    bool success = false;

    try {
      if (widget.onSubmitRating != null) {
        success = await widget.onSubmitRating!(_selectedRating, comment);
      } else {
        final exchangeVM = context.read<ExchangeViewModel?>();
        final authVM = context.read<AuthViewModel?>();
        final reviewerId = authVM?.currentUser?.id ?? 'usr-001';

        if (exchangeVM != null) {
          success = await exchangeVM.rateUser(
            targetUserId: widget.targetUserId,
            reviewerUserId: reviewerId,
            rating: _selectedRating,
            comment: comment,
            exchangeId: widget.exchangeId,
          );
          if (!success && exchangeVM.errorMessage != null) {
            _errorMessage = exchangeVM.errorMessage;
          }
        } else {
          success = true;
        }
      }
    } catch (e) {
      success = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _submitted = success;
      if (!success && _errorMessage == null) {
        _errorMessage = 'No se pudo enviar la calificación.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificar Vecino'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _submitted
                    ? _buildThankYouCard(isDark)
                    : _buildRatingForm(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingForm(bool isDark) {
    return Column(
      key: const Key('rate_user_form_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null)
          StatusBanner(
            key: const Key('rate_view_error_banner'),
            message: _errorMessage!,
            type: StatusBannerType.error,
            onDismiss: () => setState(() => _errorMessage = null),
          ),

        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.amber.shade100,
                  child: Icon(
                    Icons.person_rounded,
                    size: 34,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.targetUserName,
                  key: const Key('rate_view_target_name'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.offerTitle != null &&
                    widget.offerTitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Intercambio: ${widget.offerTitle}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  '¿Cómo fue tu experiencia con este vecino?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),

                // Selector interactivo de 5 estrellas
                Wrap(
                  alignment: WrapAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1.0;
                    return IconButton(
                      key: Key('rate_view_star_${index + 1}'),
                      iconSize: 40,
                      onPressed: () {
                        setState(() => _selectedRating = value);
                      },
                      icon: Icon(
                        value <= _selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  _ratingLabel(_selectedRating),
                  key: const Key('rate_view_rating_label'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  key: const Key('rate_view_comment_field'),
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Comentario sobre el intercambio (opcional)',
                    hintText:
                        'Ej. Muy puntual y amable en la entrega del servicio...',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkInputFill
                        : AppColors.lightInputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                CustomButton(
                  key: const Key('rate_view_submit_button'),
                  text: 'Enviar Calificación',
                  icon: const Icon(Icons.check_rounded),
                  isLoading: _isSubmitting,
                  backgroundColor: Colors.amber.shade700,
                  onPressed: _isSubmitting ? null : _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThankYouCard(bool isDark) {
    return Card(
      key: const Key('rate_user_thank_you_view'),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volunteer_activism_rounded,
                size: 48,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '¡Gracias por tu calificación!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu evaluación de ${_selectedRating.toInt()} estrellas ayuda a fortalecer la confianza en nuestra comunidad de Dolores Hidalgo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              key: const Key('rate_view_back_to_feed_button'),
              text: 'Volver al Feed Comunitario',
              icon: const Icon(Icons.home_rounded),
              backgroundColor: AppColors.secondary,
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  FeedView.routeName,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
