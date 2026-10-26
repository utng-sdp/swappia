import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/dolores_hidalgo_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/create_offer_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_banner.dart';

/// Tipo de publicación: Ofrezco (servicio o bien) vs Busco (necesidad comunitaria)
enum OfferType {
  ofrezco,
  busco,
}

/// Categorías predefinidas para ofertas y necesidades en Dolores Hidalgo.
/// Incluye las categorías especializadas de la Issue #13 (Electricidad, Costura, Mandados, Artesanía, Bienes)
/// y las categorías ampliadas para toda la comunidad.
const List<String> kOfferCategories = [
  'Electricidad',
  'Costura',
  'Mandados',
  'Artesanía',
  'Bienes',
  'Servicios u Oficios',
  'Herramientas y Maquinaria',
  'Alimentos y Cosecha Local',
  'Ropa y Calzado',
  'Materiales de Construcción',
  'Educación y Asesoría',
  'Otro',
];

/// Pantalla para publicar una nueva oferta o necesidad en la comunidad vecinal (CreateOfferView).
/// Conectada a [CreateOfferViewModel] para el envío asíncrono, validación en tiempo real,
/// toggle interactivo (Ofrezco / Busco), captura con image_picker (cámara/galería)
/// y previsualización multimedia antes de enviar.
class CreateOfferView extends StatefulWidget {
  static const String routeName = '/create-offer';

  final ImagePicker? imagePicker;
  final Future<void> Function(Map<String, dynamic> offerData)? onSubmitOffer;
  final VoidCallback? onSuccess;

  const CreateOfferView({
    super.key,
    this.imagePicker,
    this.onSubmitOffer,
    this.onSuccess,
  });

  @override
  State<CreateOfferView> createState() => _CreateOfferViewState();
}

class _CreateOfferViewState extends State<CreateOfferView> {
  final _formKey = GlobalKey<FormState>();

  OfferType _offerType = OfferType.ofrezco;
  XFile? _pickedImage;
  late final ImagePicker _imagePicker;

  @override
  void initState() {
    super.initState();
    _imagePicker = widget.imagePicker ?? ImagePicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillUserData();
    });
  }

  void _prefillUserData() {
    final authViewModel = context.read<AuthViewModel?>();
    final createOfferVM = context.read<CreateOfferViewModel?>();
    final user = authViewModel?.currentUser;

    if (user != null && createOfferVM != null && createOfferVM.coloniaComunidad.isEmpty) {
      if (DoloresHidalgoConstants.coloniasYComunidades.contains(user.coloniaComunidad)) {
        createOfferVM.setColoniaComunidad(user.coloniaComunidad);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image != null) {
        if (!mounted) return;
        setState(() {
          _pickedImage = image;
        });

        // Sincronizar con el ViewModel si existe
        final createOfferVM = context.read<CreateOfferViewModel?>();
        if (createOfferVM != null) {
          createOfferVM.setFotoPath(image.path);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No fue posible acceder a la cámara o galería: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
    });

    final createOfferVM = context.read<CreateOfferViewModel?>();
    if (createOfferVM != null) {
      createOfferVM.fotoUrlController.clear();
      createOfferVM.setFotoPath('');
    }
  }

  Future<void> _handleSubmit() async {
    final createOfferVM = context.read<CreateOfferViewModel?>();
    final authVM = context.read<AuthViewModel?>();
    final userId = authVM?.currentUser?.id ?? 'usr_anon';

    // Si hay callback desacoplado provisto (modo standalone / widget testing)
    if (widget.onSubmitOffer != null) {
      if (createOfferVM != null) {
        if (!_validateForm(createOfferVM)) return;
        await widget.onSubmitOffer!({
          'type': _offerType.name,
          'category': createOfferVM.categoria,
          'title': createOfferVM.tituloController.text.trim(),
          'description': createOfferVM.descripcionController.text.trim(),
          'tradePreference': createOfferVM.loQueBuscaController.text.trim(),
          'imagePath': _pickedImage?.path ?? createOfferVM.fotoUrlController.text.trim(),
          'colonia': createOfferVM.coloniaComunidad,
        });
        widget.onSuccess?.call();
        return;
      }
    }

    if (createOfferVM == null) return;

    createOfferVM.clearError();

    // Sincronizar foto seleccionada con el controlador antes de enviar
    if (_pickedImage != null && createOfferVM.fotoUrlController.text.trim().isEmpty) {
      createOfferVM.setFotoPath(_pickedImage!.path);
    }

    final success = await createOfferVM.publishOffer(
      usuarioId: userId,
    );

    if (mounted && success) {
      setState(() {
        _pickedImage = null;
      });

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

      widget.onSuccess?.call();
    }
  }

  bool _validateForm(CreateOfferViewModel vm) {
    if (vm.tituloController.text.trim().isEmpty) {
      return false;
    }
    if (vm.categoria.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final vm = context.watch<CreateOfferViewModel?>();

    if (vm == null) {
      return const Scaffold(
        body: Center(
          child: Text('CreateOfferViewModel no encontrado en el árbol de widgets'),
        ),
      );
    }

    final hasPhoto = _pickedImage != null || vm.fotoUrlController.text.trim().isNotEmpty;
    final currentPhotoPath = _pickedImage?.path ?? vm.fotoUrlController.text.trim();

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
                // Banner de error si las validaciones fallan
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

                // Selector Toggle Interactivo: Ofrezco vs Busco (Issue #13 Task 1)
                _buildOfferTypeToggle(colorScheme, isDark),
                const SizedBox(height: 20),

                // 1. Título de la oferta
                const Text(
                  'Título de lo que ofreces o buscas *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                CustomTextField(
                  key: const Key('offer_title_field'),
                  controller: vm.tituloController,
                  hint: _offerType == OfferType.ofrezco
                      ? 'Ej. Clases de costura básica o Reparación de contactos'
                      : 'Ej. Busco electricista o Necesito herramientas de jardinería',
                  prefixIcon: const Icon(Icons.title),
                ),
                const SizedBox(height: 16),

                // 2. Categoría (Issue #13 Task 3)
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
                      value: kOfferCategories.contains(vm.categoria)
                          ? vm.categoria
                          : null,
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

                // 4. Fotografía con image_picker y Previsualización (Issue #13 Task 2 & Criterio de Aceptación)
                const Text(
                  'Fotografía de la oferta o necesidad *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                _buildPhotoSection(context, isDark, hasPhoto, currentPhotoPath, vm),
                const SizedBox(height: 16),

                // 5. Colonia o Comunidad de Dolores Hidalgo
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
                      value: DoloresHidalgoConstants.coloniasYComunidades
                              .contains(vm.coloniaComunidad)
                          ? vm.coloniaComunidad
                          : null,
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
                  text: _offerType == OfferType.ofrezco
                      ? 'Publicar Oferta en la Comunidad'
                      : 'Publicar Necesidad en la Comunidad',
                  isLoading: vm.isLoading,
                  icon: const Icon(Icons.send_rounded),
                  onPressed: vm.isLoading ? null : _handleSubmit,
                ),

                const SizedBox(height: 12),

                // Botón secundario para limpiar formulario
                if (!vm.isLoading)
                  TextButton.icon(
                    key: const Key('clear_offer_form_button'),
                    onPressed: () {
                      setState(() {
                        _pickedImage = null;
                      });
                      vm.clearForm();
                    },
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

  /// Construye el selector Toggle para alternar entre Ofrezco y Busco
  Widget _buildOfferTypeToggle(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption(
              label: 'Ofrezco',
              subtitle: 'Servicio o bien',
              icon: Icons.volunteer_activism_rounded,
              isSelected: _offerType == OfferType.ofrezco,
              activeColor: AppColors.secondary,
              activeTextColor: Colors.white,
              onTap: () {
                setState(() {
                  _offerType = OfferType.ofrezco;
                });
              },
              key: const Key('toggle_ofrezco'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildToggleOption(
              label: 'Busco',
              subtitle: 'Necesito apoyo',
              icon: Icons.search_rounded,
              isSelected: _offerType == OfferType.busco,
              activeColor: AppColors.primary,
              activeTextColor: Colors.white,
              onTap: () {
                setState(() {
                  _offerType = OfferType.busco;
                });
              },
              key: const Key('toggle_busco'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeTextColor,
    required VoidCallback onTap,
    required Key key,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? activeTextColor : null,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected ? activeTextColor : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? activeTextColor.withValues(alpha: 0.85)
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la sección de selección de foto y previsualización
  Widget _buildPhotoSection(
    BuildContext context,
    bool isDark,
    bool hasPhoto,
    String photoPath,
    CreateOfferViewModel vm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Input manual para retrocompatibilidad
        CustomTextField(
          key: const Key('offer_photo_field'),
          controller: vm.fotoUrlController,
          hint: 'https://ejemplo.com/foto.jpg o adjunta abajo con la cámara',
          prefixIcon: const Icon(Icons.camera_alt_outlined),
          helperText: 'Formatos admitidos: JPG, JPEG, PNG o WEBP',
          onChanged: (val) {
            setState(() {});
          },
        ),
        const SizedBox(height: 10),

        // Botones de image_picker (Cámara y Galería)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('pick_camera_button'),
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Cámara'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('pick_gallery_button'),
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: const Text('Galería'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Previsualización de la foto seleccionada (Criterio de Aceptación)
        if (hasPhoto) ...[
          const SizedBox(height: 12),
          Container(
            key: const Key('image_preview'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  child: _buildImageThumbnail(photoPath),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.secondary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Foto adjuntada correctamente',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        key: const Key('remove_image_button'),
                        onPressed: _removeImage,
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.error),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageThumbnail(String path) {
    if (kIsWeb || path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(path),
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(path),
      );
    }

    return _buildPlaceholder(path);
  }

  Widget _buildPlaceholder(String path) {
    return Container(
      height: 140,
      width: double.infinity,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 6),
          Text(
            'Vista previa: ${path.split(Platform.pathSeparator).last}',
            style: const TextStyle(color: Colors.black87, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
