import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/offer_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/exchange_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../widgets/custom_button.dart';

/// Pantalla de detalle de una publicación u oferta comunitaria (OfferDetailView).
/// Muestra información completa del bien o servicio ofertado, detalles de intercambio,
/// ubicación vecinal en Dolores Hidalgo y el botón de acción principal "Proponer Intercambio".
class OfferDetailView extends StatefulWidget {
  static const String routeName = '/offer-detail';

  final OfferEntity? offer;
  final Future<void> Function(String proposalText)? onProposeExchange;

  const OfferDetailView({
    super.key,
    this.offer,
    this.onProposeExchange,
  });

  @override
  State<OfferDetailView> createState() => _OfferDetailViewState();
}

class _OfferDetailViewState extends State<OfferDetailView> {
  final TextEditingController _proposalController = TextEditingController();
  bool _isSendingProposal = false;
  OfferEntity? _currentOffer;

  @override
  void initState() {
    super.initState();
    _currentOffer = widget.offer;
  }

  @override
  void dispose() {
    _proposalController.dispose();
    super.dispose();
  }

  OfferEntity? _resolveOffer(BuildContext context) {
    if (_currentOffer != null) return _currentOffer;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OfferEntity) {
      _currentOffer = args;
      return _currentOffer;
    }
    return null;
  }

  void _showProposeExchangeModal(BuildContext context, OfferEntity offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
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
                                'Inicia una conversación vecinal',
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
                          onPressed: () => Navigator.of(bottomSheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oferta de interés: "${offer.titulo}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('proposal_input_field'),
                      controller: _proposalController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe qué ofreces a cambio o tu propuesta de acuerdo...',
                        filled: true,
                        fillColor: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      key: const Key('confirm_proposal_button'),
                      text: 'Enviar Propuesta de Trueque',
                      icon: const Icon(Icons.send_rounded),
                      isLoading: _isSendingProposal,
                      backgroundColor: AppColors.secondary,
                      onPressed: () async {
                        final text = _proposalController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor escribe tu propuesta antes de enviar.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        setModalState(() => _isSendingProposal = true);

                        // 1. Integración con ExchangeViewModel o callback provisto
                        final exchangeVM = context.read<ExchangeViewModel?>();
                        final authVM = context.read<AuthViewModel?>();
                        final currentUserId = authVM?.currentUser?.id ?? 'usr_anon';

                        if (widget.onProposeExchange != null) {
                          await widget.onProposeExchange!(text);
                        } else if (exchangeVM != null) {
                          await exchangeVM.sendProposal(
                            offerId: offer.id,
                            usuarioProponenteId: currentUserId,
                            propuesta: text,
                            usuarioReceptorId: offer.usuarioId,
                          );
                        } else {
                          // Simular persistencia
                          await Future.delayed(const Duration(milliseconds: 300));
                        }

                        setModalState(() => _isSendingProposal = false);

                        if (bottomSheetContext.mounted) {
                          Navigator.of(bottomSheetContext).pop();
                        }

                        _proposalController.clear();

                        // 2. Actualización de estado visual a "En propuesta" / "Pendiente de Aceptación"
                        final updated = offer.copyWith(estado: 'en_propuesta');
                        setState(() {
                          _currentOffer = updated;
                        });

                        // Sincronizar con el FeedViewModel si está presente
                        if (context.mounted) {
                          final feedVM = context.read<FeedViewModel?>();
                          feedVM?.updateOffer(updated);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '¡Propuesta de intercambio enviada al vecino con éxito!',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.secondary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final offer = _resolveOffer(context);

    if (offer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Publicación')),
        body: const Center(
          child: Text(
            'No se proporcionó información de la oferta.',
            key: Key('offer_not_found_text'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Publicación'),
        leading: IconButton(
          key: const Key('offer_detail_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartir',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Enlace a "${offer.titulo}" copiado.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen principal de la publicación
            _buildMainImage(offer.fotoUrl),

            // Contenedor principal de detalles
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges de Modalidad, Categoría y Estado
                  Row(
                    children: [
                      _buildModalityBadge(offer.modalidad),
                      const SizedBox(width: 8),
                      _buildCategoryBadge(offer.categoria, isDark),
                      const Spacer(),
                      _buildStatusBadge(offer),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Título principal
                  Text(
                    offer.titulo,
                    key: const Key('offer_detail_title'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Colonia y fecha
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          offer.coloniaComunidad,
                          key: const Key('offer_detail_colonia'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      if (offer.fechaPublicacion != null) ...[
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(offer.fechaPublicacion!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Sección: Descripción
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offer.descripcion,
                    key: const Key('offer_detail_description'),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sección: Preferencias de intercambio / Lo que busca a cambio
                  if (offer.loQueBusca != null && offer.loQueBusca!.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.swap_horiz_rounded,
                      iconColor: AppColors.secondary,
                      title: 'Lo que el vecino busca a cambio:',
                      content: offer.loQueBusca!,
                      contentKey: const Key('offer_detail_lo_que_busca'),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Sección: Compensación o precio estimado (si aplica)
                  if (offer.precioEstimado != null && offer.precioEstimado! > 0) ...[
                    _buildInfoCard(
                      icon: Icons.attach_money_rounded,
                      iconColor: AppColors.tertiary,
                      title: 'Compensación estimada de referencia:',
                      content: '\$${offer.precioEstimado!.toStringAsFixed(2)} MXN',
                      contentKey: const Key('offer_detail_price'),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Sección: Información del Vecino Publicador
                  _buildNeighborCard(offer.usuarioId, isDark),
                  const SizedBox(height: 28),

                  // Botón principal de acción: "Proponer Intercambio"
                  CustomButton(
                    key: const Key('propose_exchange_button'),
                    text: offer.estaEnPropuesta
                        ? 'Propuesta en Negociación'
                        : 'Proponer Intercambio',
                    icon: Icon(offer.estaEnPropuesta
                        ? Icons.hourglass_top_rounded
                        : Icons.handshake_rounded),
                    backgroundColor: offer.estaEnPropuesta
                        ? Colors.orange.shade700
                        : AppColors.secondary,
                    onPressed: () => _showProposeExchangeModal(context, offer),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImage(String path) {
    return Container(
      height: 240,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: _renderImageWidget(path),
    );
  }

  Widget _renderImageWidget(String path) {
    if (kIsWeb || path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.teal.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 54,
              color: Colors.teal.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              'Publicación Vecinal Swappia',
              style: TextStyle(
                color: Colors.teal.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalityBadge(String modalidad) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (modalidad.toLowerCase()) {
      case 'dinero':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        label = 'Efectivo';
        icon = Icons.attach_money;
        break;
      case 'mixto':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        label = 'Mixto';
        icon = Icons.handshake;
        break;
      case 'trueque':
      default:
        bg = Colors.teal.shade100;
        fg = Colors.teal.shade900;
        label = 'Trueque';
        icon = Icons.swap_horiz;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String categoria, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        categoria,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OfferEntity offer) {
    // Si la publicación está en propuesta / pendiente de aceptación
    if (offer.estaEnPropuesta) {
      return Container(
        key: const Key('offer_detail_status_badge'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(
            color: Colors.orange.shade400,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 12,
              color: Colors.orange.shade800,
            ),
            const SizedBox(width: 4),
            Text(
              'En propuesta',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
          ],
        ),
      );
    }

    final activa = offer.activa;
    return Container(
      key: const Key('offer_detail_status_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: activa ? Colors.green.shade50 : Colors.grey.shade200,
        border: Border.all(
          color: activa ? Colors.green.shade300 : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            activa ? Icons.check_circle : Icons.pause_circle_outline,
            size: 12,
            color: activa ? Colors.green.shade700 : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            activa ? 'Disponible' : 'Pausada',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: activa ? Colors.green.shade800 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required Key contentKey,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  content,
                  key: contentKey,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeighborCard(String usuarioId, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.teal.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.teal.shade100,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.teal.shade700,
            radius: 20,
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vecino de Dolores Hidalgo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.verified_user, size: 13, color: Colors.teal),
                    SizedBox(width: 4),
                    Text(
                      'Miembro verificado de la comunidad',
                      style: TextStyle(fontSize: 12, color: Colors.teal),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
