import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:swappia_app/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/widgets/custom_button.dart';
import 'presentation/widgets/custom_text_field.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase/dotenv: $e');
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
      home: UIKitShowcaseScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class UIKitShowcaseScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const UIKitShowcaseScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<UIKitShowcaseScreen> createState() => _UIKitShowcaseScreenState();
}

class _UIKitShowcaseScreenState extends State<UIKitShowcaseScreen> {
  bool _loadingButton = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swappia UI Kit'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: widget.isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sistema de Diseno & UI Kit',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Componentes atomicos configurados con Material 3 y temas dinamicos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Inputs de Texto (CustomTextField)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            const CustomTextField(
              label: 'Nombre completo',
              hint: 'Ej. Don Carlos Martinez',
              prefixIcon: Icon(Icons.person_outline),
            ),
            const SizedBox(height: 16),
            const CustomTextField(
              label: 'Contrasena',
              hint: 'Ingresa tu clave de acceso',
              isPassword: true,
              prefixIcon: Icon(Icons.lock_outline),
            ),
            const SizedBox(height: 16),
            const CustomTextField(
              label: 'Descripcion del oficio o bien',
              hint: 'Describe lo que ofreces o buscas en tu colonia...',
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            const Text('Botones Atomicos (CustomButton)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Boton Primario (Terracota)',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Boton Secundario (Verde Intercambio)',
              variant: CustomButtonVariant.secondary,
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Boton Delineado (Outlined)',
              variant: CustomButtonVariant.outlined,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: _loadingButton ? 'Cargando...' : 'Simular Estado de Carga',
              isLoading: _loadingButton,
              onPressed: () async {
                setState(() => _loadingButton = true);
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) setState(() => _loadingButton = false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
