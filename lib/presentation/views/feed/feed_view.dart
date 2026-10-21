import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  static const String routeName = '/feed';

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

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
              await authViewModel.logout();
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
                await authViewModel.checkSession();
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Tarjeta de perfil y sesión activa
                  Card(
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
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Colors.teal),
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
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          if (authViewModel.token != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Token Persistido: ${authViewModel.token!.substring(0, authViewModel.token!.length > 25 ? 25 : authViewModel.token!.length)}...',
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
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Oportunidades de Trueque en tu Colonia',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildTradeItem(
                    title: 'Herramientas de Jardinería',
                    owner: 'Don Chema',
                    colonia: user.coloniaComunidad,
                    modalidad: 'Trueque por fruta de temporada',
                    icon: Icons.park,
                  ),
                  _buildTradeItem(
                    title: 'Clases de Matemáticas Secundaria',
                    owner: 'Maestra Elena',
                    colonia: user.coloniaComunidad,
                    modalidad: 'Mixto (50 MXN o despensa)',
                    icon: Icons.school,
                  ),
                  _buildTradeItem(
                    title: 'Bicicleta Rodada 26',
                    owner: 'Carlos V.',
                    colonia: user.coloniaComunidad,
                    modalidad: 'Trueque por taladro o mano de obra',
                    icon: Icons.pedal_bike,
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('feed_publish_offer_fab'),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Publicar Oferta'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).pushNamed('/create-offer');
        },
      ),
    );
  }

  Widget _buildTradeItem({
    required String title,
    required String owner,
    required String colonia,
    required String modalidad,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: Icon(icon, color: Colors.teal),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('Vecino: $owner • $colonia'),
            const SizedBox(height: 2),
            Text(
              modalidad,
              style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}
