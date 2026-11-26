import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/postal_code_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/exchange_entity.dart';
import '../../../domain/models/offer_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/exchange_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/postal_code_location_selector.dart';
import '../exchange/create_offer_view.dart';
import '../exchange/exchange_confirmation_view.dart';
import '../exchange/offer_detail_view.dart';

/// Pantalla principal de Swappia con navegación inferior en 4 secciones:
/// 0. Explorar (Feed comunitario con búsqueda y filtros en cascada)
/// 1. Mis Ofertas (Publicaciones creadas por el usuario autenticado)
/// 2. Acuerdos (Propuestas de intercambio activas e historial)
/// 3. Perfil (Datos del vecino, reputación y cerrar sesión)
class FeedView extends StatefulWidget {
  static const String routeName = '/feed';

  final PostalCodeService? postalCodeService;

  const FeedView({super.key, this.postalCodeService});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  bool _initialized = false;
  bool _showFilters = false;
  int _selectedTabIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final feedVM = context.read<FeedViewModel?>();
      if (feedVM != null && feedVM.allOffers.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            feedVM.loadOffers();
          }
        });
      }
    }
  }

  void _navigateToDetail(BuildContext context, OfferEntity offer) {
    Navigator.of(context).pushNamed(
      OfferDetailView.routeName,
      arguments: offer,
    );
  }

  Future<void> _openCreateOffer(FeedViewModel? feedViewModel) async {
    final result =
        await Navigator.of(context).pushNamed(CreateOfferView.routeName);
    if (result is OfferEntity && feedViewModel != null) {
      final exists = feedViewModel.allOffers.any((o) => o.id == result.id);
      if (!exists) {
        feedViewModel.addOffer(result);
      }
    }
  }

  void _onTabSelected(
    int index,
    String userId,
    ExchangeViewModel? exchangeViewModel,
  ) {
    setState(() => _selectedTabIndex = index);
    if (index == 2 && exchangeViewModel != null) {
      exchangeViewModel.loadUserProposals(userId);
    }
  }

  Future<void> _handleLogout(
    BuildContext context,
    AuthViewModel? authViewModel,
    FeedViewModel? feedViewModel,
    ExchangeViewModel? exchangeViewModel,
  ) async {
    exchangeViewModel?.reset();
    feedViewModel?.clearSearch();
    feedViewModel?.clearFilters();
    if (authViewModel != null) {
      await authViewModel.logout();
    }
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  String _appBarTitle() {
    switch (_selectedTabIndex) {
      case 1:
        return 'Mis Ofertas';
      case 2:
        return 'Mis Acuerdos';
      case 3:
        return 'Mi Perfil Vecinal';
      case 0:
      default:
        return 'Swappia Feed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel?>();
    final feedViewModel = context.watch<FeedViewModel?>();
    final exchangeViewModel = context.watch<ExchangeViewModel?>();
    final user = authViewModel?.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.swap_horizontal_circle, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _appBarTitle(),
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(
              context,
              authViewModel,
              feedViewModel,
              exchangeViewModel,
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _buildTabBody(
              context: context,
              user: user,
              authViewModel: authViewModel,
              feedViewModel: feedViewModel,
              exchangeViewModel: exchangeViewModel,
              isDark: isDark,
            ),
      bottomNavigationBar: user == null
          ? null
          : NavigationBar(
              key: const Key('main_bottom_nav'),
              selectedIndex: _selectedTabIndex,
              onDestinationSelected: (idx) =>
                  _onTabSelected(idx, user.id, exchangeViewModel),
              destinations: const [
                NavigationDestination(
                  key: Key('nav_explore'),
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Explorar',
                ),
                NavigationDestination(
                  key: Key('nav_my_offers'),
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Mis Ofertas',
                ),
                NavigationDestination(
                  key: Key('nav_exchanges'),
                  icon: Icon(Icons.handshake_outlined),
                  selectedIcon: Icon(Icons.handshake),
                  label: 'Acuerdos',
                ),
                NavigationDestination(
                  key: Key('nav_profile'),
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
      floatingActionButton: (user != null && _selectedTabIndex <= 1)
          ? FloatingActionButton.extended(
              key: const Key('feed_publish_offer_fab'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Publicar Oferta'),
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              onPressed: () => _openCreateOffer(feedViewModel),
            )
          : null,
    );
  }

  Widget _buildTabBody({
    required BuildContext context,
    required dynamic user,
    required AuthViewModel? authViewModel,
    required FeedViewModel? feedViewModel,
    required ExchangeViewModel? exchangeViewModel,
    required bool isDark,
  }) {
    switch (_selectedTabIndex) {
      case 1:
        return _buildMyOffersTab(
          context: context,
          userId: user.id,
          feedViewModel: feedViewModel,
          isDark: isDark,
        );
      case 2:
        return _buildExchangesTab(
          context: context,
          userId: user.id,
          feedViewModel: feedViewModel,
          exchangeViewModel: exchangeViewModel,
          isDark: isDark,
        );
      case 3:
        return _buildProfileTab(
          context: context,
          user: user,
          authViewModel: authViewModel,
          feedViewModel: feedViewModel,
          exchangeViewModel: exchangeViewModel,
          isDark: isDark,
        );
      case 0:
      default:
        return _buildExploreTab(
          context: context,
          user: user,
          authViewModel: authViewModel,
          feedViewModel: feedViewModel,
          isDark: isDark,
        );
    }
  }

  /// Tab 0: Explorar (Feed principal)
  Widget _buildExploreTab({
    required BuildContext context,
    required dynamic user,
    required AuthViewModel? authViewModel,
    required FeedViewModel? feedViewModel,
    required bool isDark,
  }) {
    final bool filteringMyColonia =
        feedViewModel?.selectedColonia?.toLowerCase() ==
            user.coloniaComunidad.toString().toLowerCase();

    return RefreshIndicator(
      onRefresh: () async {
        if (feedViewModel != null) {
          await feedViewModel.loadOffers(refresh: true);
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
        children: [
          // 1. Encabezado compacto de vecino y sesión activa
          _buildCompactUserBanner(user),
          const SizedBox(height: 10),

          // 2. Barra de búsqueda activa con Debounce y filtros desplegables
          _buildSearchBar(feedViewModel, isDark),
          const SizedBox(height: 8),

          // 2b. Chips rápidos de alcance (Todas vs Mi colonia)
          Row(
            children: [
              ChoiceChip(
                key: const Key('feed_scope_all_chip'),
                label: const Text('Todas', style: TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
                selected: !filteringMyColonia,
                onSelected: (_) => feedViewModel?.setLocationFilter(),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ChoiceChip(
                  key: const Key('feed_scope_colonia_chip'),
                  label: Text(
                    'Mi colonia (${user.coloniaComunidad})',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  visualDensity: VisualDensity.compact,
                  selected: filteringMyColonia,
                  onSelected: (selected) {
                    if (selected) {
                      feedViewModel?.setLocationFilter(
                        colonia: user.coloniaComunidad.toString(),
                      );
                    } else {
                      feedViewModel?.setLocationFilter();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          _buildFilterPanel(feedViewModel, isDark),
          const SizedBox(height: 10),

          // 3. Título de sección y contador reactivo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  feedViewModel?.hasActiveSearch == true
                      ? 'Resultados para "${feedViewModel!.searchQuery}"'
                      : 'Oportunidades de Trueque en tu Comunidad',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (feedViewModel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            ...feedViewModel.offers.map(
              (offer) => _buildOfferCard(context, offer, isDark),
            ),
          ],
        ],
      ),
    );
  }

  /// Tab 1: Mis Ofertas publicadas por el usuario
  Widget _buildMyOffersTab({
    required BuildContext context,
    required String userId,
    required FeedViewModel? feedViewModel,
    required bool isDark,
  }) {
    final myOffers = feedViewModel?.offersByUser(userId) ?? const [];

    return RefreshIndicator(
      onRefresh: () async {
        if (feedViewModel != null) {
          await feedViewModel.loadOffers(refresh: true);
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Text(
            'Publicaciones que has creado (${myOffers.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (feedViewModel == null || feedViewModel.isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (myOffers.isEmpty) ...[
            Card(
              elevation: 0,
              color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Aún no has publicado ofertas',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Publica un servicio, oficio o bien que quieras intercambiar con tus vecinos.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Crear mi primera oferta',
                      icon: const Icon(Icons.add),
                      backgroundColor: AppColors.secondary,
                      onPressed: () => _openCreateOffer(feedViewModel),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...myOffers.map(
              (offer) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OfferCard(
                    offer: offer,
                    usuarioNombre: 'Tú',
                    onTap: () => _navigateToDetail(context, offer),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextButton.icon(
                        onPressed: () async {
                          final ok = await feedViewModel.deleteOffer(offer.id);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Oferta desactivada.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        label: const Text(
                          'Desactivar publicación',
                          style:
                              TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tab 2: Acuerdos y propuestas de intercambio
  Widget _buildExchangesTab({
    required BuildContext context,
    required String userId,
    required FeedViewModel? feedViewModel,
    required ExchangeViewModel? exchangeViewModel,
    required bool isDark,
  }) {
    final proposals = exchangeViewModel?.userProposals ?? const [];

    return RefreshIndicator(
      onRefresh: () async {
        if (exchangeViewModel != null) {
          await exchangeViewModel.loadUserProposals(userId);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tus propuestas y acuerdos vecinales',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (exchangeViewModel != null &&
              exchangeViewModel.isLoadingProposals) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (proposals.isEmpty) ...[
            Card(
              elevation: 0,
              color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.handshake_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No tienes acuerdos activos todavía',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Abre cualquier oferta en Explorar y presiona "Proponer Intercambio" para iniciar una negociación.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...proposals.map((proposal) => _buildExchangeTile(
                  context: context,
                  proposal: proposal,
                  feedViewModel: feedViewModel,
                  isDark: isDark,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildExchangeTile({
    required BuildContext context,
    required ExchangeEntity proposal,
    required FeedViewModel? feedViewModel,
    required bool isDark,
  }) {
    final matchingOffer = (feedViewModel?.allOffers ?? const <OfferEntity>[])
        .cast<OfferEntity?>()
        .firstWhere(
          (o) => o?.id == proposal.offerId,
          orElse: () => null,
        );

    final offerForConfirmation = matchingOffer ??
        OfferEntity(
          id: proposal.offerId,
          usuarioId: proposal.usuarioReceptorId ?? '',
          titulo: 'Publicación #${proposal.offerId}',
          descripcion: proposal.propuesta,
          categoria: 'Intercambio',
          coloniaComunidad: 'Dolores Hidalgo',
          fotoUrl: '',
          modalidad: proposal.modalidad,
        );

    final Color statusColor = proposal.esAceptada
        ? Colors.green
        : (proposal.esRechazada ? AppColors.error : Colors.orange);
    final String statusText = proposal.esAceptada
        ? 'Aceptada'
        : (proposal.esRechazada ? 'Rechazada' : 'Pendiente');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.handshake_rounded, color: statusColor),
        ),
        title: Text(
          offerForConfirmation.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              proposal.propuesta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text(statusText, style: const TextStyle(fontSize: 10)),
                  backgroundColor: statusColor.withValues(alpha: 0.14),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                Chip(
                  label: Text(
                    proposal.modalidad.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).pushNamed(
            ExchangeConfirmationView.routeName,
            arguments: ExchangeConfirmationArgs(
              offer: offerForConfirmation,
              proposal: proposal,
            ),
          );
        },
      ),
    );
  }

  /// Tab 3: Perfil Vecinal
  Widget _buildProfileTab({
    required BuildContext context,
    required dynamic user,
    required AuthViewModel? authViewModel,
    required FeedViewModel? feedViewModel,
    required ExchangeViewModel? exchangeViewModel,
    required bool isDark,
  }) {
    final myCount = feedViewModel?.offersByUser(user.id).length ?? 0;
    final dealsCount = exchangeViewModel?.userProposals.length ?? 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildUserProfileCard(user, authViewModel),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen Comunitario',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20),
                _profileInfoRow(Icons.phone_outlined, 'Teléfono', user.telefono),
                _profileInfoRow(
                  Icons.location_on_outlined,
                  'Colonia / Comunidad',
                  user.coloniaComunidad,
                ),
                _profileInfoRow(
                  Icons.inventory_2_outlined,
                  'Mis publicaciones activas',
                  '$myCount',
                ),
                _profileInfoRow(
                  Icons.handshake_outlined,
                  'Acuerdos registrados',
                  '$dealsCount',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        CustomButton(
          text: 'Publicar nueva oferta',
          icon: const Icon(Icons.add_circle_outline),
          backgroundColor: AppColors.secondary,
          onPressed: () => _openCreateOffer(feedViewModel),
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Cerrar Sesión',
          variant: CustomButtonVariant.outlined,
          icon: const Icon(Icons.logout),
          onPressed: () => _handleLogout(
            context,
            authViewModel,
            feedViewModel,
            exchangeViewModel,
          ),
        ),
      ],
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactUserBanner(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.teal.shade700,
            child: Text(
              user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nombre,
                  key: const Key('feed_user_name'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.teal),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        user.coloniaComunidad,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, size: 12, color: Colors.teal),
                SizedBox(width: 3),
                Text(
                  'Sesión Activa',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.teal),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.coloniaComunidad,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
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

  /// Panel desplegable de filtros hiperlocales (CP -> Municipio -> Colonia y Categoría)
  Widget _buildFilterPanel(FeedViewModel? vm, bool isDark) {
    final hasFilters = vm?.hasActiveFilters == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('feed_toggle_filters_button'),
                onPressed: () {
                  setState(() => _showFilters = !_showFilters);
                },
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.tune_rounded,
                  size: 18,
                ),
                label: Text(
                  hasFilters
                      ? 'Filtros activos (Ubicación / Categoría)'
                      : 'Filtrar por Código Postal, Colonia o Categoría',
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(width: 8),
              IconButton(
                key: const Key('feed_clear_filters_button'),
                tooltip: 'Limpiar filtros',
                icon: const Icon(Icons.close_rounded, color: AppColors.error),
                onPressed: () => vm?.clearFilters(),
              ),
            ],
          ],
        ),
        if (_showFilters)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PostalCodeLocationSelector(
                  postalCodeService: widget.postalCodeService,
                  initialCodigoPostal: vm?.selectedCodigoPostal,
                  initialMunicipio: vm?.selectedMunicipio,
                  initialColonia: vm?.selectedColonia,
                  isRequired: false,
                  compact: true,
                  cpDropdownKey: const Key('feed_cp_dropdown'),
                  municipioDropdownKey: const Key('feed_municipio_dropdown'),
                  coloniaDropdownKey: const Key('feed_colonia_dropdown'),
                  onLocationChanged: ({codigoPostal, municipio, colonia}) {
                    vm?.setLocationFilter(
                      codigoPostal: codigoPostal,
                      municipio: municipio,
                      colonia: colonia,
                    );
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const Key('feed_category_dropdown'),
                  initialValue:
                      kOfferCategories.contains(vm?.selectedCategoria)
                          ? vm?.selectedCategoria
                          : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: const Icon(Icons.category_outlined, size: 18),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'Todas las categorías',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...kOfferCategories.map(
                      (cat) => DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) => vm?.setCategoryFilter(value),
                ),
              ],
            ),
          ),
      ],
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
  Widget _buildOfferCard(
    BuildContext context,
    OfferEntity offer,
    bool isDark,
  ) {
    return OfferCard(
      offer: offer,
      onTap: () => _navigateToDetail(context, offer),
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
                  : 'Aún no hay publicaciones activas con los filtros seleccionados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            if (vm.hasActiveSearch || vm.hasActiveFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('empty_state_clear_button'),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Mostrar todas las ofertas'),
                onPressed: () {
                  vm.clearSearch();
                  vm.clearFilters();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
