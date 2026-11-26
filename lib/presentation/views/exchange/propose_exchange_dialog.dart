import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/offer_entity.dart';
import '../../widgets/custom_button.dart';

/// Datos capturados en el modal [ProposeExchangeDialog] antes de enviar la propuesta.
class ProposeExchangeSubmission {
  final String modalidad; // 'trueque', 'dinero', 'mixto'
  final String propuesta;
  final double? montoEfectivo;
  final String? bienOfrecidoId;
  final String? bienOfrecidoTitulo;

  const ProposeExchangeSubmission({
    required this.modalidad,
    required this.propuesta,
    this.montoEfectivo,
    this.bienOfrecidoId,
    this.bienOfrecidoTitulo,
  });
}

/// Modal interactivo "Proponer Intercambio" (Issue #19).
/// Permite seleccionar la modalidad de pago (Trueque, Efectivo o Mixto),
/// elegir opcionalmente una publicación propia a ofrecer a cambio, indicar
/// monto en efectivo cuando aplique y redactar una propuesta al vecino.
class ProposeExchangeDialog extends StatefulWidget {
  final OfferEntity targetOffer;
  final List<OfferEntity> userOffers;
  final Future<void> Function(ProposeExchangeSubmission submission) onSubmit;

  const ProposeExchangeDialog({
    super.key,
    required this.targetOffer,
    this.userOffers = const [],
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required OfferEntity targetOffer,
    List<OfferEntity> userOffers = const [],
    required Future<void> Function(ProposeExchangeSubmission submission) onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProposeExchangeDialog(
        targetOffer: targetOffer,
        userOffers: userOffers,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<ProposeExchangeDialog> createState() => _ProposeExchangeDialogState();
}

class _ProposeExchangeDialogState extends State<ProposeExchangeDialog> {
  final TextEditingController _proposalController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late String _selectedModality;
  OfferEntity? _selectedOwnOffer;
  bool _isSubmitting = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final norm = widget.targetOffer.modalidad.trim().toLowerCase();
    if (norm == 'dinero' || norm == 'mixto' || norm == 'trueque') {
      _selectedModality = norm;
    } else {
      _selectedModality = 'trueque';
    }
    if (widget.targetOffer.precioEstimado != null &&
        widget.targetOffer.precioEstimado! > 0) {
      _amountController.text =
          widget.targetOffer.precioEstimado!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _proposalController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _proposalController.text.trim();
    if (text.isEmpty || text.length < 3) {
      setState(() {
        _validationError = text.isEmpty
            ? 'Por favor escribe tu propuesta antes de enviar.'
            : 'La propuesta debe tener al menos 3 caracteres.';
      });
      return;
    }

    double? amount;
    if (_selectedModality != 'trueque' &&
        _amountController.text.trim().isNotEmpty) {
      amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount < 0) {
        setState(() {
          _validationError = 'Ingresa un monto en efectivo válido.';
        });
        return;
      }
    }

    setState(() {
      _validationError = null;
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(
        ProposeExchangeSubmission(
          modalidad: _selectedModality,
          propuesta: text,
          montoEfectivo: amount,
          bienOfrecidoId:
              _selectedModality != 'dinero' ? _selectedOwnOffer?.id : null,
          bienOfrecidoTitulo:
              _selectedModality != 'dinero' ? _selectedOwnOffer?.titulo : null,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _validationError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final availableOwnOffers = widget.userOffers
        .where((o) => o.id != widget.targetOffer.id && o.activa)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: AppColors.secondary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proponer Intercambio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Elige el tipo de acuerdo y redacta tu nota',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Oferta de interés: "${widget.targetOffer.titulo}"',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),

              // Selector de modalidad de pago con ChoiceChips (Issue #19)
              const Text(
                'Modalidad de pago acordada',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    key: const Key('modality_chip_trueque'),
                    label: const Text('Trueque'),
                    avatar: const Icon(Icons.swap_horiz, size: 16),
                    selected: _selectedModality == 'trueque',
                    onSelected: (_) =>
                        setState(() => _selectedModality = 'trueque'),
                  ),
                  ChoiceChip(
                    key: const Key('modality_chip_dinero'),
                    label: const Text('Efectivo'),
                    avatar: const Icon(Icons.attach_money, size: 16),
                    selected: _selectedModality == 'dinero',
                    onSelected: (_) =>
                        setState(() => _selectedModality = 'dinero'),
                  ),
                  ChoiceChip(
                    key: const Key('modality_chip_mixto'),
                    label: const Text('Mixto'),
                    avatar: const Icon(Icons.handshake_outlined, size: 16),
                    selected: _selectedModality == 'mixto',
                    onSelected: (_) =>
                        setState(() => _selectedModality = 'mixto'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Campo opcional para seleccionar un bien propio a ofrecer a cambio
              if (_selectedModality != 'dinero') ...[
                DropdownButtonFormField<OfferEntity>(
                  key: const Key('own_offer_dropdown'),
                  initialValue: availableOwnOffers.contains(_selectedOwnOffer)
                      ? _selectedOwnOffer
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Bien o servicio propio a cambio (opcional)',
                    hintText: availableOwnOffers.isEmpty
                        ? 'No tienes publicaciones activas'
                        : 'Selecciona una publicación propia',
                    prefixIcon: const Icon(Icons.inventory_2_outlined, size: 18),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkInputFill
                        : AppColors.lightInputFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<OfferEntity>(
                      value: null,
                      child: Text(
                        'Sin publicación vinculada (solo describir)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...availableOwnOffers.map(
                      (item) => DropdownMenuItem<OfferEntity>(
                        value: item,
                        child: Text(
                          item.titulo,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedOwnOffer = value;
                      if (value != null &&
                          _proposalController.text.trim().isEmpty) {
                        _proposalController.text =
                            'Te propongo intercambiar por: ${value.titulo}';
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Monto en efectivo cuando modalidad es dinero o mixto
              if (_selectedModality != 'trueque') ...[
                TextField(
                  key: const Key('proposal_amount_field'),
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto en efectivo (MXN)',
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkInputFill
                        : AppColors.lightInputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Nota de propuesta
              TextField(
                key: const Key('proposal_input_field'),
                controller: _proposalController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Nota o detalle de tu propuesta *',
                  hintText:
                      'Describe qué ofreces a cambio o tu propuesta de acuerdo...',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkInputFill
                      : AppColors.lightInputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
              ),

              if (_validationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _validationError!,
                  key: const Key('proposal_validation_error'),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),

              CustomButton(
                key: const Key('confirm_proposal_button'),
                text: 'Enviar Propuesta de Trueque',
                icon: const Icon(Icons.send_rounded),
                isLoading: _isSubmitting,
                backgroundColor: AppColors.secondary,
                onPressed: _isSubmitting ? null : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
