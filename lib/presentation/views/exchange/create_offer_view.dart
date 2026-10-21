import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/dolores_hidalgo_constants.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/create_offer_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_banner.dart';

/// Categorías predefinidas para ofertas y necesidades en Dolores Hidalgo
const List<String> kOfferCategories = [
  'Servicios u Oficios',
  'Bienes y Artículos',
  'Herramientas y Maquinaria',
  'Alimentos y Cosecha Local',
  'Ropa y Calzado',
  'Materiales de Construcción',
  'Educación y Asesoría',
  'Otro',
];

/// Pantalla para publicar una nueva oferta o necesidad en la comunidad vecinal.
/// Conectada a [CreateOfferViewModel] para el envío asíncrono, validación en tiempo real
/// y limpieza automática de campos tras la confirmación.
class CreateOfferView extends StatefulWidget {
  static const String routeName = '/create-offer';

  const CreateOfferView({super.key});

  @override
  State<CreateOfferView> createState() => _CreateOfferViewState();
}

class _CreateOfferViewState extends State<CreateOfferView> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillUserData();
    });
  }

  void _prefillUserData() {
    final authViewModel = context.read<AuthViewModel?>();
    final createOfferVM = context.read<CreateOfferViewModel>();
    final user = authViewModel?.currentUser;

    if (user != null && createOfferVM.coloniaComunidad.isEmpty) {
      createOfferVM.setColoniaComunidad(user.coloniaComunidad);
    }
  }

  Future<void> _handleSubmit() async {
    final createOfferVM = context.read<CreateOfferViewModel>();
    final authVM = context.read<AuthViewModel?>();
    final userId = authVM?.currentUser?.id ?? 'usr_anon';

    createOfferVM.clearError();

    final success = await createOfferVM.publishOffer(
      usuarioId: userId,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                createOfferVM.successMessage ?? '¡Oferta publicada exitosamente!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<CreateOfferViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Oferta o Necesidad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner de error si las validaciones de negocio fallan
                if (vm.hasError && vm.errorMessage != null)
                  StatusBanner(
                    message: vm.errorMessage!,
                    type: StatusBannerType.error,
                    onDismiss: vm.clearError,
                    textKey: const Key('create_offer_error_banner'),
                  ),

                // Banner de éxito tras la confirmación
                if (vm.isSuccess && vm.successMessage != null)
                  StatusBanner(
                    message: vm.successMessage!,
                    type: StatusBannerType.success,
                    textKey: const Key('create_offer_success_banner'),
                  ),

                // 1. Título de la oferta
                const Text(
                  'Título de lo que ofreces o buscas *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                CustomTextField(
                  key: const Key('offer_title_field'),
                  controller: vm.tituloController,
                  hint: 'Ej. Reparación de calzado, Taladro 1/2 pulgada...',
                  prefixIcon: const Icon(Icons.title),
                ),
                const SizedBox(height: 16),

                // 2. Categoría
                const Text(
                  'Categoría *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category_outlined),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: const Key('offer_category_dropdown'),
                      value: vm.categoria.isNotEmpty ? vm.categoria : null,
                      hint: const Text('Selecciona una categoría'),
                      isExpanded: true,
                      items: kOfferCategories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) vm.setCategoria(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Descripción
                const Text(
                  'Descripción detallada *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                CustomTextField(
                  key: const Key('offer_description_field'),
                  controller: vm.descripcionController,
                  hint: 'Describe el estado del bien, experiencia del servicio o detalles del acuerdo.',
                  maxLines: 4,
                  minLines: 3,
                ),
                const SizedBox(height: 16),

                // 4. Fotografía
                const Text(
                  'Fotografía de la oferta (URL o ruta .jpg, .png, .webp) *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                CustomTextField(
                  key: const Key('offer_photo_field'),
                  controller: vm.fotoUrlController,
                  hint: 'https://ejemplo.com/foto.jpg o imagen.png',
                  prefixIcon: const Icon(Icons.camera_alt_outlined),
                  helperText: 'Formatos admitidos: JPG, JPEG, PNG o WEBP',
                ),
                const SizedBox(height: 16),

                // 5. Colonia o Comunidad
                const Text(
                  'Colonia o Comunidad de Dolores Hidalgo *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: const Key('offer_colonia_dropdown'),
                      value: vm.coloniaComunidad.isNotEmpty ? vm.coloniaComunidad : null,
                      hint: const Text('Selecciona colonia o comunidad'),
                      isExpanded: true,
                      items: DoloresHidalgoConstants.coloniasYComunidades
                          .map((col) => DropdownMenuItem(
                                value: col,
                                child: Text(col, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) vm.setColoniaComunidad(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Modalidad de intercambio
                const Text(
                  'Modalidad de Intercambio',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  key: const Key('offer_modalidad_segmented'),
                  segments: const [
                    ButtonSegment(
                      value: 'trueque',
                      label: Text('Trueque'),
                      icon: Icon(Icons.swap_horiz),
                    ),
                    ButtonSegment(
                      value: 'dinero',
                      label: Text('Efectivo'),
                      icon: Icon(Icons.attach_money),
                    ),
                    ButtonSegment(
                      value: 'mixto',
                      label: Text('Mixto'),
                      icon: Icon(Icons.handshake),
                    ),
                  ],
                  selected: {vm.modalidad},
                  onSelectionChanged: (set) {
                    vm.setModalidad(set.first);
                  },
                ),
                const SizedBox(height: 16),

                // 7. Lo que busca a cambio (opcional o requerido para trueque/mixto)
                if (vm.modalidad != 'dinero') ...[
                  const Text(
                    '¿Qué buscas a cambio? (Opcional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  CustomTextField(
                    key: const Key('offer_lo_que_busca_field'),
                    controller: vm.loQueBuscaController,
                    hint: 'Ej. Fruta de temporada, ayuda con albañilería...',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  const SizedBox(height: 16),
                ],

                // 8. Precio estimado (si aplica)
                if (vm.modalidad != 'trueque') ...[
                  const Text(
                    'Precio o compensación monetaria estimada (MXN)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  CustomTextField(
                    key: const Key('offer_precio_field'),
                    controller: vm.precioEstimadoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hint: '0.00',
                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 12),

                // Botón de envío con spinner de carga
                CustomButton(
                  key: const Key('submit_offer_button'),
                  text: 'Publicar en la Comunidad',
                  isLoading: vm.isLoading,
                  icon: const Icon(Icons.send_rounded),
                  onPressed: vm.isLoading ? null : _handleSubmit,
                ),

                const SizedBox(height: 12),

                // Botón secundario para limpiar formulario
                if (!vm.isLoading)
                  TextButton.icon(
                    key: const Key('clear_offer_form_button'),
                    onPressed: vm.clearForm,
                    icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                    label: const Text('Limpiar Formulario'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
