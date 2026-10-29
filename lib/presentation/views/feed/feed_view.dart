import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/offer_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../exchange/offer_detail_view.dart';

/// Pantalla principal de Swappia Feed.
/// Muestra información de perfil del vecino autenticado, barra de búsqueda activa con debounce
/// y la lista interactiva de ofertas de la comunidad en Dolores Hidalgo.
/// Al pulsar sobre cualquier tarjeta de oferta, navega a [OfferDetailView] pasando la entidad como parámetro.
class FeedView extends StatefulWidget {
  static const String routeName = '/feed';

  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final feedVM = context.read<FeedViewModel?>();
      final authVM = context.read<AuthViewModel?>();
      if (feedVM != null && feedVM.allOffers.isEmpty) {
        feedVM.loadOffers(colonia: authVM?.currentUser?.coloniaComunidad);
      }
    }
  }

  void _navigateToDetail(BuildContext context, OfferEntity offer) {
    Navigator.of(context).pushNamed(
      OfferDetailView.routeName,
      arguments: offer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel?>();
    final feedViewModel = context.watch<FeedViewModel?>();
    final user = authViewModel?.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.swap_horizontal_circle, color: Colors.teal),
            SizedBox(width: 8),
            Text(
              'Swappia Feed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              if (authViewModel != null) {
                await authViewModel.logout();
              }
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (authViewModel != null) {
                  await authViewModel.checkSession();
                }
                if (feedViewModel != null) {
                  await feedViewModel.loadOffers(
                    colonia: user.coloniaComunidad,
                    refresh: true,
                  );
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 1. Tarjeta de perfil y sesión activa
                  _buildUserProfileCard(user, authViewModel),
                  const SizedBox(height: 18),

                  // 2. Barra de búsqueda activa con Debounce
                  _buildSearchBar(feedViewModel, isDark),
                  const SizedBox(height: 20),

                  // 3. Título de sección y contador reactivo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          feedViewModel?.hasActiveSearch == true
                              ? 'Resultados para "${feedViewModel!.searchQuery}"'
                              : 'Oportunidades de Trueque en tu Colonia',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (feedViewModel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Text(
                            '${feedViewModel.count} disponibles',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4. Listado dinámico de publicaciones
                  if (feedViewModel == null || feedViewModel.isLoading) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if (feedViewModel.offers.isEmpty) ...[
                    _buildEmptyState(feedViewModel, isDark),
                  ] else ...[
                    ...feedViewModel.offers.map((offer) => _buildOfferCard(
                          context,
                          offer,
                          isDark,
                        )),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('feed_publish_offer_fab'),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Publicar Oferta'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result =
              await Navigator.of(context).pushNamed('/create-offer');
          if (result is OfferEntity && feedViewModel != null) {
            feedViewModel.addOffer(result);
          }
        },
      ),
    );
  }

  Widget _buildUserProfileCard(dynamic user, AuthViewModel? authViewModel) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.teal.shade700,
                  child: Text(
                    user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nombre,
                        key: const Key('feed_user_name'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(
                            user.coloniaComunidad,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Reputación: ${user.reputacionLegible}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, size: 14, color: Colors.teal),
                      SizedBox(width: 4),
                      Text(
                        'Sesión Activa',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (authViewModel?.token != null) ...[
              const SizedBox(height: 8),
              Text(
                'Token Persistido: ${authViewModel!.token!.substring(0, authViewModel.token!.length > 25 ? 25 : authViewModel.token!.length)}...',
                key: const Key('feed_token_preview'),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construye la barra de búsqueda activa con Debounce conectado al ViewModel
  Widget _buildSearchBar(FeedViewModel? vm, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        key: const Key('feed_search_bar'),
        controller: vm?.searchController,
        onChanged: (val) {
          vm?.onSearchChanged(val);
        },
        decoration: InputDecoration(
          hintText: 'Buscar por título, categoría, trueque o colonia...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.teal),
          suffixIcon: (vm?.hasActiveSearch == true)
              ? IconButton(
                  key: const Key('clear_search_button'),
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () => vm?.clearSearch(),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  /// Tarjeta de publicación en el Feed.
  /// Cumple con el criterio de aceptación: al presionar abre el detalle completo [OfferDetailView].
  Widget _buildOfferCard(
    BuildContext context,
    OfferEntity offer,
    bool isDark,
  ) {
    return Card(
      key: Key('offer_card_${offer.id}'),
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
        onTap: () => _navigateToDetail(context, offer),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniatura de la oferta
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 72,
                  height: 72,
                  color: Colors.teal.shade50,
                  child: _buildOfferThumbnail(offer.fotoUrl),
                ),
              ),
              const SizedBox(width: 12),

              // Contenido informativo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chips de categoría y modalidad
                    Row(
                      children: [
                        _buildSmallBadge(
                          offer.categoria,
                          bgColor: isDark
                              ? AppColors.darkSurfaceVariant
                              : Colors.grey.shade100,
                          textColor: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        _buildModalityChip(offer.modalidad),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Título de la oferta
                    Text(
                      offer.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Ubicación / Colonia
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            offer.coloniaComunidad,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey.shade700,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Lo que busca o precio
                    if (offer.loQueBusca != null &&
                        offer.loQueBusca!.isNotEmpty) ...[
                      Text(
                        'Busca: ${offer.loQueBusca}',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (offer.precioEstimado != null) ...[
                      Text(
                        'Precio ref: \$${offer.precioEstimado!.toStringAsFixed(2)} MXN',
                        style: const TextStyle(
                          color: AppColors.tertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Flecha de navegación a detalle
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Icon(
                  Icons.arrow_forward_ios,
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

  Widget _buildOfferThumbnail(String path) {
    if (path.isEmpty) {
      return const Center(
        child: Icon(Icons.swap_horiz, color: Colors.teal, size: 30),
      );
    }

    if (kIsWeb || path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.image_outlined, color: Colors.teal, size: 28),
        ),
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.image_outlined, color: Colors.teal, size: 28),
        ),
      );
    }

    return const Center(
      child: Icon(Icons.image_outlined, color: Colors.teal, size: 28),
    );
  }

  Widget _buildSmallBadge(String text,
      {required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildModalityChip(String modalidad) {
    Color bg;
    Color fg;
    String label;

    switch (modalidad.toLowerCase()) {
      case 'dinero':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'Efectivo';
        break;
      case 'mixto':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
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

  Widget _buildEmptyState(FeedViewModel vm, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'No encontramos publicaciones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              vm.hasActiveSearch
                  ? 'No hay ofertas o servicios que coincidan con "${vm.searchQuery}".'
                  : 'Aún no hay publicaciones activas en tu colonia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            if (vm.hasActiveSearch) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('empty_state_clear_button'),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Mostrar todas las ofertas'),
                onPressed: () => vm.clearSearch(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
