import 'package:flutter/material.dart';
import 'package:swappia_app/core/theme/app_colors.dart';
import 'package:swappia_app/presentation/widgets/custom_button.dart';
import 'package:swappia_app/presentation/widgets/custom_text_field.dart';
import 'package:swappia_app/presentation/widgets/status_banner.dart';

/// Vista de inicio de sesion para vecinos de Swappia.
class LoginView extends StatefulWidget {
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu correo electronico';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un formato de correo valido (ej. vecino@correo.com)';
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

  Future<void> _handleLogin() async {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.onLoginSubmit != null) {
        await widget.onLoginSubmit!(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await Future.delayed(const Duration(seconds: 1));
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
    final isDark = theme.brightness == Brightness.dark;

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
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"Lo que tu tienes, alguien mas lo necesita."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13.5,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesion para conectar con oficios y trueques en Dolores Hidalgo.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_errorMessage != null)
                      StatusBanner(
                        message: _errorMessage!,
                        type: StatusBannerType.error,
                        onDismiss: () => setState(() => _errorMessage = null),
                      ),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Correo electronico',
                      hint: 'vecino@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Contrasena',
                      hint: 'Ingresa tu contrasena',
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _handleLogin(),
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
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Iniciar Sesion',
                      icon: const Icon(Icons.login_rounded),
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Aun no tienes cuenta?',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToRegister,
                          child: Text(
                            'Registrate aqui',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
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