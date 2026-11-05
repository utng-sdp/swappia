import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/offer_entity.dart';

/// Tarjeta atómica y reutilizable de publicación de intercambio comunitario (OfferCard).
/// Issue #16: feat(ui): Diseñar Feed Principal y tarjeta de publicación (OfferCard)
///
/// Destaca el distintivo visual entre bienes y servicios vecinales, mostrando
/// fotografía/miniatura, título, badges (Ofrezco / Busco, categoría, modalidad),
/// usuario y colonia vecinal en Dolores Hidalgo.
class OfferCard extends StatelessWidget {
  final OfferEntity offer;
  final VoidCallback? onTap;
  final String? usuarioNombre;

  const OfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.usuarioNombre,
  });

  /// Determina si la publicación es un Servicio u Oficio o un Bien tangible.
  bool get _esServicio {
    final cat = offer.categoria.toLowerCase();
    final tit = offer.titulo.toLowerCase();
    final desc = offer.descripcion.toLowerCase();

    return cat.contains('servicio') ||
        cat.contains('oficio') ||
        cat.contains('asesor') ||
        cat.contains('educaci') ||
        cat.contains('costura') ||
        cat.contains('electricidad') ||
        cat.contains('mandado') ||
        cat.contains('plomer') ||
        tit.contains('servicio') ||
        tit.contains('clase') ||
        tit.contains('reparaci') ||
        desc.contains('servicio') ||
        desc.contains('asesor');
  }

  /// Determina si la publicación es una oferta ("Ofrezco") o una solicitud/necesidad ("Busco").
  bool get _esBusqueda {
    final tit = offer.titulo.trim().toLowerCase();
    final desc = offer.descripcion.trim().toLowerCase();
    final cat = offer.categoria.trim().toLowerCase();

    return tit.startsWith('busco') ||
        tit.startsWith('necesito') ||
        tit.startsWith('solicito') ||
        cat.contains('necesidad') ||
        cat.contains('busco') ||
        desc.startsWith('busco') ||
        desc.startsWith('necesito');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedUser = usuarioNombre ??
        (offer.usuarioId.startsWith('usr-')
            ? 'Vecino ${offer.usuarioId.replaceFirst('usr-', '')}'
            : (offer.usuarioId.isNotEmpty ? offer.usuarioId : 'Vecino de la comunidad'));

    return Card(
      key: key ?? Key('offer_card_${offer.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Miniatura multimedia con soporte para URLs y rutas locales
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 76,
                  height: 76,
                  color: isDark ? AppColors.darkSurfaceVariant : Colors.teal.shade50,
                  child: _buildOfferThumbnail(offer.fotoUrl),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Contenido descriptivo e insignias distintivas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila de Badges distintivos: Tipo (Ofrezco / Busco) + Naturaleza (Bien / Servicio) + Modalidad
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Badge Ofrezco / Busco
                        _buildTypeBadge(isDark),

                        // Distintivo Bien vs Servicio
                        _buildNatureBadge(isDark),

                        // Badge de Modalidad (Trueque / Dinero / Mixto)
                        _buildModalityChip(offer.modalidad),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Título de la publicación
                    Text(
                      offer.titulo,
                      key: Key('offer_title_${offer.id}'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Usuario vecinal y Colonia en Dolores Hidalgo
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            resolvedUser,
                            key: Key('offer_user_${offer.id}'),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            offer.coloniaComunidad,
                            key: Key('offer_colonia_${offer.id}'),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey.shade700,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Acuerdo deseado o precio de referencia
                    if (offer.loQueBusca != null &&
                        offer.loQueBusca!.trim().isNotEmpty) ...[
                      Text(
                        'Intercambio: ${offer.loQueBusca}',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (offer.precioEstimado != null) ...[
                      Text(
                        'Ref: \$${offer.precioEstimado!.toStringAsFixed(2)} MXN',
                        style: const TextStyle(
                          color: AppColors.tertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 3. Flecha de navegación a detalle
              const Padding(
                padding: EdgeInsets.only(top: 26),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(bool isDark) {
    final esBusqueda = _esBusqueda;
    final text = esBusqueda ? 'BUSCO' : 'OFREZCO';
    final bgColor = esBusqueda
        ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.4) : Colors.blue.shade50)
        : (isDark ? Colors.teal.shade900.withValues(alpha: 0.4) : Colors.teal.shade50);
    final textColor = esBusqueda
        ? (isDark ? Colors.blue.shade200 : Colors.blue.shade800)
        : (isDark ? Colors.teal.shade200 : Colors.teal.shade800);

    return Container(
      key: Key('offer_type_badge_${offer.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildNatureBadge(bool isDark) {
    final esServicio = _esServicio;
    final text = esServicio ? 'Servicio' : 'Bien';
    final icon = esServicio ? Icons.build_outlined : Icons.inventory_2_outlined;

    final bgColor = isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade100;
    final textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      key: Key('offer_nature_badge_${offer.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalityChip(String modalidad) {
    Color bg;
    Color fg;
    String label;

    switch (modalidad.toLowerCase()) {
      case 'dinero':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Efectivo';
        break;
      case 'mixto':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade900;
        label = 'Mixto';
        break;
      case 'trueque':
      default:
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade800;
        label = 'Trueque';
        break;
    }

    return Container(
      key: Key('offer_modality_badge_${offer.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildOfferThumbnail(String path) {
    if (path.isEmpty) {
      return Center(
        child: Icon(
          _esServicio ? Icons.handyman_rounded : Icons.swap_horiz_rounded,
          color: Colors.teal,
          size: 30,
        ),
      );
    }

    if (kIsWeb || path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        key: Key('offer_image_${offer.id}'),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(
            _esServicio ? Icons.handyman_rounded : Icons.image_outlined,
            color: Colors.teal,
            size: 28,
          ),
        ),
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        key: Key('offer_image_${offer.id}'),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(
            _esServicio ? Icons.handyman_rounded : Icons.image_outlined,
            color: Colors.teal,
            size: 28,
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        _esServicio ? Icons.handyman_rounded : Icons.image_outlined,
        color: Colors.teal,
        size: 28,
      ),
    );
  }
}
