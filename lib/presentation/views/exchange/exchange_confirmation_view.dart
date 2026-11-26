import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/exchange_entity.dart';
import '../../../domain/models/offer_entity.dart';
import '../../viewmodels/exchange_viewmodel.dart';
import '../../widgets/custom_button.dart';
import 'rate_user_view.dart';

/// Argumentos de navegación para [ExchangeConfirmationView].
class ExchangeConfirmationArgs {
  final OfferEntity offer;
  final ExchangeEntity proposal;
  final String? counterpartName;

  const ExchangeConfirmationArgs({
    required this.offer,
    required this.proposal,
    this.counterpartName,
  });
}

/// Pantalla "Confirmación de Acuerdo" (Issue #22).
/// Permite revisar el resumen del acuerdo (modalidad de pago, bien ofrecido,
/// monto en efectivo y nota), aceptar o rechazar la propuesta, y continuar
/// hacia la pantalla de calificación vecinal [RateUserView].
class ExchangeConfirmationView extends StatefulWidget {
  static const String routeName = '/exchange-confirmation';

  final OfferEntity offer;
  final ExchangeEntity proposal;
  final String? counterpartName;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onReject;

  const ExchangeConfirmationView({
    super.key,
    required this.offer,
    required this.proposal,
    this.counterpartName,
    this.onAccept,
    this.onReject,
  });

  @override
  State<ExchangeConfirmationView> createState() =>
      _ExchangeConfirmationViewState();
}

class _ExchangeConfirmationViewState extends State<ExchangeConfirmationView> {
  late ExchangeEntity _proposal;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _proposal = widget.proposal;
  }

  String _modalityLabel(String modalidad) {
    switch (modalidad.toLowerCase()) {
      case 'dinero':
        return 'Efectivo';
      case 'mixto':
        return 'Mixto (Trueque + Efectivo)';
      case 'trueque':
      default:
        return 'Trueque Directo';
    }
  }

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);
    try {
      if (widget.onAccept != null) {
        await widget.onAccept!();
      } else {
        final vm = context.read<ExchangeViewModel?>();
        if (vm != null) {
          await vm.acceptProposal(_proposal.id);
        }
      }
      if (!mounted) return;
      setState(() {
        _proposal = _proposal.copyWith(estado: 'aceptada');
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Acuerdo confirmado con éxito!'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al confirmar acuerdo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleReject() async {
    setState(() => _isProcessing = true);
    try {
      if (widget.onReject != null) {
        await widget.onReject!();
      } else {
        final vm = context.read<ExchangeViewModel?>();
        if (vm != null) {
          await vm.rejectProposal(_proposal.id);
        }
      }
      if (!mounted) return;
      setState(() {
        _proposal = _proposal.copyWith(estado: 'rechazada');
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Propuesta rechazada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final counterpart = widget.counterpartName ?? 'Vecino de Dolores Hidalgo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmación de Acuerdo'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner animado de estado del acuerdo
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildStatusCard(isDark),
                  ),
                  const SizedBox(height: 16),

                  // Resumen de la publicación
                  _buildSummaryCard(
                    isDark: isDark,
                    title: 'Publicación Acordada',
                    icon: Icons.storefront_rounded,
                    iconColor: AppColors.primary,
                    children: [
                      Text(
                        widget.offer.titulo,
                        key: const Key('confirmation_offer_title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 15, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.offer.coloniaComunidad,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Resumen del acuerdo / modalidad de pago
                  _buildSummaryCard(
                    isDark: isDark,
                    title: 'Detalles del Trueque / Pago',
                    icon: Icons.handshake_rounded,
                    iconColor: AppColors.secondary,
                    children: [
                      _buildDetailRow(
                        'Modalidad',
                        _modalityLabel(_proposal.modalidad),
                      ),
                      if (_proposal.bienOfrecidoTitulo != null &&
                          _proposal.bienOfrecidoTitulo!.isNotEmpty)
                        _buildDetailRow(
                          'Bien/Servicio ofrecido',
                          _proposal.bienOfrecidoTitulo!,
                        ),
                      if (_proposal.montoEfectivo != null &&
                          _proposal.montoEfectivo! > 0)
                        _buildDetailRow(
                          'Compensación en efectivo',
                          '\$${_proposal.montoEfectivo!.toStringAsFixed(2)} MXN',
                        ),
                      _buildDetailRow('Nota del acuerdo', _proposal.propuesta),
                      _buildDetailRow('Vecino participante', counterpart),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Acciones según estado actual del acuerdo
                  if (_proposal.esAceptada) ...[
                    CustomButton(
                      key: const Key('go_to_rate_user_button'),
                      text: 'Calificar al Vecino',
                      icon: const Icon(Icons.star_rounded),
                      backgroundColor: Colors.amber.shade700,
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          RateUserView.routeName,
                          arguments: RateUserArgs(
                            targetUserId: widget.offer.usuarioId,
                            targetUserName: counterpart,
                            exchangeId: _proposal.id,
                            offerTitle: widget.offer.titulo,
                          ),
                        );
                      },
                    ),
                  ] else if (_proposal.esRechazada) ...[
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver a la publicación'),
                    ),
                  ] else ...[
                    CustomButton(
                      key: const Key('confirm_agreement_button'),
                      text: 'Confirmar y Aceptar Acuerdo',
                      icon: const Icon(Icons.check_circle_outline),
                      backgroundColor: AppColors.secondary,
                      isLoading: _isProcessing,
                      onPressed: _isProcessing ? null : _handleAccept,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      key: const Key('reject_agreement_button'),
                      onPressed: _isProcessing ? null : _handleReject,
                      icon: const Icon(Icons.cancel_outlined,
                          color: AppColors.error),
                      label: const Text(
                        'Rechazar Propuesta',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    final bool accepted = _proposal.esAceptada;
    final bool rejected = _proposal.esRechazada;

    final Color color = accepted
        ? Colors.green
        : (rejected ? AppColors.error : Colors.orange);
    final IconData icon = accepted
        ? Icons.verified_rounded
        : (rejected ? Icons.cancel_rounded : Icons.hourglass_top_rounded);
    final String title = accepted
        ? 'Acuerdo Confirmado'
        : (rejected ? 'Propuesta Rechazada' : 'Pendiente de Confirmación');
    final String subtitle = accepted
        ? 'Ya pueden coordinar la entrega y calificar su experiencia vecinal.'
        : (rejected
            ? 'Este acuerdo fue cancelado.'
            : 'Revisa los términos del intercambio antes de aceptar.');

    return Container(
      key: ValueKey(_proposal.estado),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: const Key('confirmation_status_title'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
