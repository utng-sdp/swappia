import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/usecases/get_session_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/views/auth/login_view.dart';
import 'presentation/views/auth/register_view.dart';
import 'presentation/views/feed/feed_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase/dotenv initialization: $e');
  }

  final localDataSource = SharedPreferencesAuthLocalDataSource();
  final remoteDataSource = MockAuthRemoteDataSource();
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );

  final loginUseCase = LoginUseCase(authRepository);
  final registerUseCase = RegisterUseCase(authRepository);
  final getSessionUseCase = GetSessionUseCase(authRepository);

  final authViewModel = AuthViewModel(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    getSessionUseCase: getSessionUseCase,
  );

  // Restaurar sesión activa persistida si existe
  await authViewModel.checkSession();

  runApp(SwappiaApp(authViewModel: authViewModel));
}

class SwappiaApp extends StatefulWidget {
  final AuthViewModel? authViewModel;

  const SwappiaApp({
    super.key,
    this.authViewModel,
  });

  @override
  State<SwappiaApp> createState() => _SwappiaAppState();
}

class _SwappiaAppState extends State<SwappiaApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget appWidget = MaterialApp(
      title: 'Swappia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      routes: {
        LoginView.routeName: (context) => const LoginView(),
        RegisterView.routeName: (context) => const RegisterView(),
        FeedView.routeName: (context) => const FeedView(),
      },
      home: Consumer<AuthViewModel>(
        builder: (context, auth, _) {
          if (auth.isLoading && auth.status == AuthStatus.loading && auth.currentUser == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (auth.isAuthenticated) {
            return const FeedView();
          }
          return const LoginView();
        },
      ),
    );

    if (widget.authViewModel != null) {
      return ChangeNotifierProvider<AuthViewModel>.value(
        value: widget.authViewModel!,
        child: appWidget,
      );
    }

    return appWidget;
  }
}
