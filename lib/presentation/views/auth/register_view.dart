import 'package:flutter/material.dart';
import 'package:swappia_app/core/constants/dolores_hidalgo_constants.dart';
import 'package:swappia_app/core/theme/app_colors.dart';
import 'package:swappia_app/presentation/widgets/custom_button.dart';
import 'package:swappia_app/presentation/widgets/custom_text_field.dart';
import 'package:swappia_app/presentation/widgets/status_banner.dart';

/// Vista de registro para nuevos vecinos de Swappia en Dolores Hidalgo.
/// Incluye formulario completo, seleccion hiperlocal de colonia/comunidad,
/// validaciones sincronizadas con las reglas de negocio y diseno minimalista.
class RegisterView extends StatefulWidget {
  final VoidCallback? onNavigateToLogin;
  final Future<void> Function({
    required String nombre,
    required String telefono,
    required String email,
    required String colonia,
    String? oficio,
    required String password,
  })? onRegisterSubmit;

  const RegisterView({
    super.key,
    this.onNavigateToLogin,
    this.onRegisterSubmit,
  });

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _oficioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedColonia;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _oficioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu nombre completo';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 letras';
    }
    return null;
  }

  String? _validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu telefono para contacto vecinal';
    }
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 10) {
      return 'El telefono debe tener exactamente 10 digitos';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu correo electronico';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un formato de correo valido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa una contrasena';
    }
    if (value.length < 6) {
      return 'La contrasena debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contrasena';
    }
    if (value != _passwordController.text) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedColonia == null) {
      setState(() {
        _errorMessage = 'Selecciona tu colonia o comunidad de Dolores Hidalgo';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.onRegisterSubmit != null) {
        await widget.onRegisterSubmit!(
          nombre: _nombreController.text.trim(),
          telefono: _telefonoController.text.trim(),
          email: _emailController.text.trim(),
          colonia: _selectedColonia!,
          oficio: _oficioController.text.trim().isEmpty ? null : _oficioController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro exitoso. Bienvenido a Swappia!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- ENCABEZADO ---
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 32,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Crear Perfil Vecinal',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Registrate para intercambiar bienes, ofrecer tus oficios o solicitar ayuda en tu colonia.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- BANNER DE ERROR ---
                    if (_errorMessage != null)
                      StatusBanner(
                        message: _errorMessage!,
                        type: StatusBannerType.error,
                        onDismiss: () => setState(() => _errorMessage = null),
                      ),

                    // --- CAMPOS DE FORMULARIO ---
                    CustomTextField(
                      controller: _nombreController,
                      label: 'Nombre completo',
                      hint: 'Ej. Don Carlos Martinez',
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      validator: _validateNombre,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _telefonoController,
                      label: 'Telefono celular (10 digitos)',
                      hint: '4181234567',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      validator: _validateTelefono,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _emailController,
                      label: 'Correo electronico',
                      hint: 'vecino@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 14),

                    // --- DROPDOWN DE COLONIAS / COMUNIDADES ---
                    DropdownButtonFormField<String>(
                      initialValue: _selectedColonia,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      dropdownColor: theme.colorScheme.surface,
                      decoration: InputDecoration(
                        labelText: 'Colonia o comunidad (Dolores Hidalgo)',
                        hintText: 'Selecciona tu colonia o comunidad',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                      ),
                      items: DoloresHidalgoConstants.coloniasYComunidades
                          .map((colonia) => DropdownMenuItem(
                                value: colonia,
                                child: Text(
                                  colonia,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedColonia = val;
                          if (_errorMessage != null) _errorMessage = null;
                        });
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Por favor selecciona tu colonia o comunidad';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _oficioController,
                      label: 'Oficio principal o bien para trueque (opcional)',
                      hint: 'Ej. Electricista, Costura, Artesanias, Ropa...',
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.handyman_outlined, size: 20),
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _passwordController,
                      label: 'Contrasena',
                      hint: 'Minimo 6 caracteres',
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar contrasena',
                      hint: 'Repite tu contrasena',
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                      validator: _validateConfirmPassword,
                      onFieldSubmitted: (_) => _handleRegister(),
                    ),
                    const SizedBox(height: 24),

                    // --- BOTON DE ACCION PRINCIPAL ---
                    CustomButton(
                      text: 'Registrarme como Vecino',
                      variant: CustomButtonVariant.secondary,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 24),

                    // --- PIE / VOLVER A LOGIN ---
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Ya tienes cuenta?',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToLogin,
                          child: Text(
                            'Inicia sesion aqui',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}