import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/postal_code_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/postal_code_location_selector.dart';
import '../../widgets/status_banner.dart';
import '../feed/feed_view.dart';
import 'login_view.dart';

/// Vista de registro vecinal (RegisterView) para Swappia.
/// Permite capturar nombre, telefono de 10 digitos, correo, ubicacion
/// mediante API de codigos postales (CP -> Municipio -> Colonia) y credenciales seguras.
class RegisterView extends StatefulWidget {
  static const routeName = '/register';

  final VoidCallback? onNavigateToLogin;
  final Future<void> Function(Map<String, dynamic> data)? onRegisterSubmit;
  final PostalCodeService? postalCodeService;

  const RegisterView({
    super.key,
    this.onNavigateToLogin,
    this.onRegisterSubmit,
    this.postalCodeService,
  });

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedCodigoPostal;
  String? _selectedMunicipio;
  String? _selectedColonia;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateNombre(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    return null;
  }

  String? _validateTelefono(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'El telefono debe tener exactamente 10 digitos';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Por favor ingresa tu correo electronico';
    }
    if (!v.contains('@') || !v.contains('.')) {
      return 'Ingrese un correo electrónico válido';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v != null && v.isNotEmpty && v != _passwordController.text) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }

  Future<void> _submitRegister() async {
    FocusScope.of(context).unfocus();
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.onRegisterSubmit != null) {
      setState(() => _isLoading = true);
      try {
        await widget.onRegisterSubmit!({
          'nombre': _nombreController.text.trim(),
          'codigoPostal': _selectedCodigoPostal ?? '',
          'municipio': _selectedMunicipio ?? '',
          'colonia': (_selectedColonia ?? '').trim(),
          'telefono': _telefonoController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        });
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
      return;
    }

    AuthViewModel? authViewModel;
    try {
      authViewModel = context.read<AuthViewModel>();
    } catch (_) {}

    if (authViewModel != null) {
      authViewModel.clearError();
      final success = await authViewModel.register(
        nombre: _nombreController.text.trim(),
        coloniaComunidad: (_selectedColonia ?? '').trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          FeedView.routeName,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    AuthViewModel? authViewModel;
    try {
      authViewModel = context.watch<AuthViewModel>();
    } catch (_) {}

    final bool isBusy = _isLoading || (authViewModel?.isLoading ?? false);
    final String? effectiveError = _errorMessage ??
        (authViewModel?.hasError == true ? authViewModel?.errorMessage : null);

    const EdgeInsets fieldPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Vecino'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 46,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onNavigateToLogin != null) {
              widget.onNavigateToLogin!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed(LoginView.routeName);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crear Perfil Vecinal',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (effectiveError != null)
                      StatusBanner(
                        key: const Key('register_error_banner'),
                        textKey: const Key('register_error_text'),
                        message: effectiveError,
                        type: StatusBannerType.error,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        onDismiss: () {
                          setState(() => _errorMessage = null);
                          authViewModel?.clearError();
                        },
                      ),

                    // Campo 0: Nombre
                    CustomTextField(
                      key: const Key('register_nombre_field'),
                      controller: _nombreController,
                      label: 'Nombre completo',
                      hint: 'Ej. Don Carlos Martinez',
                      contentPadding: fieldPadding,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                      validator: _validateNombre,
                    ),
                    const SizedBox(height: 6),

                    // Campo 1: Telefono
                    CustomTextField(
                      key: const Key('register_telefono_field'),
                      controller: _telefonoController,
                      label: 'Telefono celular (10 digitos)',
                      hint: '4181234567',
                      contentPadding: fieldPadding,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      validator: _validateTelefono,
                    ),
                    const SizedBox(height: 6),

                    // Campo 2: Correo
                    CustomTextField(
                      key: const Key('register_email_field'),
                      controller: _emailController,
                      label: 'Correo electronico',
                      hint: 'vecino@ejemplo.com',
                      contentPadding: fieldPadding,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 6),

                    // Campo 3: Ubicacion en cascada via API (Codigo Postal -> Municipio -> Colonia)
                    PostalCodeLocationSelector(
                      postalCodeService: widget.postalCodeService,
                      initialCodigoPostal: _selectedCodigoPostal,
                      initialMunicipio: _selectedMunicipio,
                      initialColonia: _selectedColonia,
                      cpDropdownKey: const Key('register_cp_dropdown'),
                      municipioDropdownKey: const Key('register_municipio_dropdown'),
                      coloniaDropdownKey: const Key('register_colonia_dropdown'),
                      coloniaLabel: 'Colonia o comunidad (Dolores Hidalgo)',
                      compact: true,
                      onLocationChanged: ({codigoPostal, municipio, colonia}) {
                        setState(() {
                          _selectedCodigoPostal = codigoPostal;
                          _selectedMunicipio = municipio;
                          _selectedColonia = colonia;
                        });
                      },
                    ),
                    const SizedBox(height: 6),

                    // Campo 4: Contrasena
                    CustomTextField(
                      key: const Key('register_password_field'),
                      controller: _passwordController,
                      label: 'Contrasena',
                      hint: 'Minimo 6 caracteres',
                      contentPadding: fieldPadding,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 6),

                    // Campo 5: Confirmar contrasena
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar contrasena',
                      hint: 'Repite tu contrasena',
                      contentPadding: fieldPadding,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_reset_rounded, size: 18),
                      validator: _validateConfirmPassword,
                      onFieldSubmitted: (_) => _submitRegister(),
                    ),
                    const SizedBox(height: 12),

                    CustomButton(
                      key: const Key('register_submit_button'),
                      text: 'Registrarme como Vecino',
                      variant: CustomButtonVariant.secondary,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      height: 44,
                      isLoading: isBusy,
                      onPressed: isBusy ? null : _submitRegister,
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Ya tienes cuenta? ',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            authViewModel?.clearError();
                            if (widget.onNavigateToLogin != null) {
                              widget.onNavigateToLogin!();
                            } else if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pushReplacementNamed(LoginView.routeName);
                            }
                          },
                          child: Text(
                            'Inicia sesion aqui',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
