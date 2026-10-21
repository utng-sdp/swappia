import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_banner.dart';
import '../feed/feed_view.dart';
import 'register_view.dart';

/// Vista de inicio de sesion (LoginView) para Swappia.
/// Construida con diseno minimalista, accesible y responsivo.
/// Soporta integracion tanto con [AuthViewModel] como con callbacks desacoplados para testing.
class LoginView extends StatefulWidget {
  static const routeName = '/login';

  final VoidCallback? onNavigateToRegister;
  final Future<void> Function(String email, String password)? onLoginSubmit;

  const LoginView({
    super.key,
    this.onNavigateToRegister,
    this.onLoginSubmit,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu correo electronico';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contrasena';
    }
    if (value.length < 6) {
      return 'La contrasena debe tener al menos 6 caracteres';
    }
    return null;
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.onLoginSubmit != null) {
      setState(() => _isLoading = true);
      try {
        await widget.onLoginSubmit!(
          _identifierController.text.trim(),
          _passwordController.text,
        );
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
      final success = await authViewModel.login(
        emailOrPhone: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(FeedView.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    AuthViewModel? authViewModel;
    try {
      authViewModel = context.watch<AuthViewModel>();
    } catch (_) {}

    final bool isBusy = _isLoading || (authViewModel?.isLoading ?? false);
    final String? effectiveError = _errorMessage ??
        (authViewModel?.hasError == true ? authViewModel?.errorMessage : null);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Swappia',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lo que tu tienes, alguien mas lo necesita.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13.5,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesion para conectar con oficios y trueques en Dolores Hidalgo.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (effectiveError != null)
                      StatusBanner(
                        key: const Key('login_error_banner'),
                        textKey: const Key('login_error_text'),
                        message: effectiveError,
                        type: StatusBannerType.error,
                        onDismiss: () {
                          setState(() => _errorMessage = null);
                          authViewModel?.clearError();
                        },
                      ),

                    CustomTextField(
                      key: const Key('login_email_field'),
                      controller: _identifierController,
                      label: 'Correo electronico',
                      hint: 'vecino@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                      validator: _validateEmailOrPhone,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      key: const Key('login_password_field'),
                      controller: _passwordController,
                      label: 'Contrasena',
                      hint: 'Ingresa tu contrasena',
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submitLogin(),
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Proximamente recuperacion de acceso.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Olvidaste tu contrasena?',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    CustomButton(
                      key: const Key('login_submit_button'),
                      text: 'Iniciar Sesion',
                      icon: const Icon(Icons.login_rounded),
                      isLoading: isBusy,
                      onPressed: isBusy ? null : _submitLogin,
                    ),
                    const SizedBox(height: 28),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Aun no tienes cuenta? ',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          key: const Key('goto_register_button'),
                          onPressed: () {
                            authViewModel?.clearError();
                            if (widget.onNavigateToRegister != null) {
                              widget.onNavigateToRegister!();
                            } else {
                              Navigator.of(context).pushNamed(RegisterView.routeName);
                            }
                          },
                          child: Text(
                            'Registrate aqui',
                            style: TextStyle(
                              color: colorScheme.primary,
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
