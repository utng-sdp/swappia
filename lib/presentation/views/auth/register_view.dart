import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../feed/feed_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _coloniaController = TextEditingController(text: 'La Lindavista');
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _coloniaController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.register(
      nombre: _nombreController.text.trim(),
      coloniaComunidad: _coloniaController.text.trim(),
      telefono: _telefonoController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Criterio de Aceptación: Al autenticarse con éxito, redirige de forma automática al Feed principal
      Navigator.of(context).pushNamedAndRemoveUntil(
        FeedView.routeName,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Registro de Vecino'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Únete a la Red de Swappia',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Intercambia bienes y oficios en Dolores Hidalgo con vecinos verificados.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (authViewModel.hasError && authViewModel.errorMessage != null)
                    Container(
                      key: const Key('register_error_banner'),
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        authViewModel.errorMessage!,
                        key: const Key('register_error_text'),
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),

                  // Nombre
                  TextFormField(
                    key: const Key('register_nombre_field'),
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre y Apellido',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Colonia o Comunidad
                  TextFormField(
                    key: const Key('register_colonia_field'),
                    controller: _coloniaController,
                    decoration: InputDecoration(
                      labelText: 'Colonia o Comunidad (Dolores Hidalgo)',
                      hintText: 'ej. La Lindavista, Centro, Río Laja',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Indique su colonia o comunidad';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Teléfono
                  TextFormField(
                    key: const Key('register_telefono_field'),
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Teléfono Móvil (10 dígitos)',
                      hintText: '4181234567',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (digits.length != 10) {
                        return 'Debe ingresar 10 dígitos numéricos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Correo
                  TextFormField(
                    key: const Key('register_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      hintText: 'ej. vecino@correo.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) {
                      if (v == null || !v.contains('@') || !v.contains('.')) {
                        return 'Ingrese un correo electrónico válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Contraseña
                  TextFormField(
                    key: const Key('register_password_field'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña (mínimo 6 caracteres)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    key: const Key('register_submit_button'),
                    onPressed: authViewModel.isLoading ? null : _submitRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: authViewModel.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Registrarse e Ingresar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
