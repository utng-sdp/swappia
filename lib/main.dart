import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:swappia_app/core/services/supabase_service.dart';
import 'package:swappia_app/core/theme/app_theme.dart';
import 'package:swappia_app/presentation/views/auth/login_view.dart';
import 'package:swappia_app/presentation/views/auth/register_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar variables de entorno y Supabase si existen
  try {
    await dotenv.load(fileName: '.env');
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Nota: Inicializacion de Supabase/dotenv: $e');
  }

  runApp(const SwappiaApp());
}

class SwappiaApp extends StatefulWidget {
  const SwappiaApp({super.key});

  @override
  State<SwappiaApp> createState() => _SwappiaAppState();
}

class _SwappiaAppState extends State<SwappiaApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swappia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: AuthNavigationWrapper(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class AuthNavigationWrapper extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AuthNavigationWrapper({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<AuthNavigationWrapper> createState() => _AuthNavigationWrapperState();
}

class _AuthNavigationWrapperState extends State<AuthNavigationWrapper> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showLogin ? 'Swappia - Inicio de Sesion' : 'Swappia - Registro'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: widget.isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showLogin
            ? LoginView(
                key: const ValueKey('login_view'),
                onNavigateToRegister: () => setState(() => _showLogin = false),
              )
            : RegisterView(
                key: const ValueKey('register_view'),
                onNavigateToLogin: () => setState(() => _showLogin = true),
              ),
      ),
    );
  }
}