import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/offers_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/offer_repository_impl.dart';
import 'domain/models/offer_entity.dart';
import 'domain/usecases/get_session_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/publish_offer_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/create_offer_viewmodel.dart';
import 'presentation/viewmodels/feed_viewmodel.dart';
import 'presentation/views/auth/login_view.dart';
import 'presentation/views/auth/register_view.dart';
import 'presentation/views/exchange/create_offer_view.dart';
import 'presentation/views/exchange/offer_detail_view.dart';
import 'presentation/views/feed/feed_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool supabaseInitialized = false;
  try {
    await dotenv.load(fileName: '.env');
    await SupabaseService.initialize();
    supabaseInitialized = true;
  } catch (e) {
    debugPrint('Supabase/dotenv initialization: $e');
  }

  final localDataSource = SharedPreferencesAuthLocalDataSource();
  final remoteDataSource = supabaseInitialized
      ? SupabaseAuthRemoteDataSource()
      : MockAuthRemoteDataSource();
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

  // Restaurar sesion activa persistida si existe
  await authViewModel.checkSession();

  final offersRemoteDataSource = supabaseInitialized
      ? SupabaseOffersRemoteDataSource()
      : MockOffersRemoteDataSource();
  final offerRepository = OfferRepositoryImpl(
    remoteDataSource: offersRemoteDataSource,
  );
  final publishOfferUseCase = PublishOfferUseCase(offerRepository);
  final createOfferViewModel = CreateOfferViewModel(
    publishOfferUseCase: publishOfferUseCase,
  );
  final feedViewModel = FeedViewModel(
    offerRepository: offerRepository,
  );

  runApp(SwappiaApp(
    authViewModel: authViewModel,
    createOfferViewModel: createOfferViewModel,
    feedViewModel: feedViewModel,
  ));
}

class SwappiaApp extends StatefulWidget {
  final AuthViewModel? authViewModel;
  final CreateOfferViewModel? createOfferViewModel;
  final FeedViewModel? feedViewModel;

  const SwappiaApp({
    super.key,
    this.authViewModel,
    this.createOfferViewModel,
    this.feedViewModel,
  });

  @override
  State<SwappiaApp> createState() => _SwappiaAppState();
}

class _SwappiaAppState extends State<SwappiaApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appWidget = MaterialApp(
      title: 'Swappia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      routes: {
        LoginView.routeName: (context) => const LoginView(),
        RegisterView.routeName: (context) => const RegisterView(),
        FeedView.routeName: (context) => const FeedView(),
        CreateOfferView.routeName: (context) => const CreateOfferView(),
        OfferDetailView.routeName: (context) {
          final offer =
              ModalRoute.of(context)?.settings.arguments as OfferEntity?;
          return OfferDetailView(offer: offer);
        },
      },
      home: Consumer<AuthViewModel>(
        builder: (context, auth, _) {
          if (auth.isLoading &&
              auth.status == AuthStatus.loading &&
              auth.currentUser == null) {
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

    final effectiveAuthVM = widget.authViewModel ??
        AuthViewModel(
          loginUseCase: LoginUseCase(
            AuthRepositoryImpl(
              remoteDataSource: MockAuthRemoteDataSource(),
              localDataSource: SharedPreferencesAuthLocalDataSource(),
            ),
          ),
          registerUseCase: RegisterUseCase(
            AuthRepositoryImpl(
              remoteDataSource: MockAuthRemoteDataSource(),
              localDataSource: SharedPreferencesAuthLocalDataSource(),
            ),
          ),
          getSessionUseCase: GetSessionUseCase(
            AuthRepositoryImpl(
              remoteDataSource: MockAuthRemoteDataSource(),
              localDataSource: SharedPreferencesAuthLocalDataSource(),
            ),
          ),
        );

    final effectiveOfferRepo = OfferRepositoryImpl();
    final effectiveOfferVM = widget.createOfferViewModel ??
        CreateOfferViewModel(
          publishOfferUseCase: PublishOfferUseCase(effectiveOfferRepo),
        );

    final effectiveFeedVM = widget.feedViewModel ??
        FeedViewModel(
          offerRepository: effectiveOfferRepo,
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: effectiveAuthVM),
        ChangeNotifierProvider<CreateOfferViewModel>.value(
            value: effectiveOfferVM),
        ChangeNotifierProvider<FeedViewModel>.value(value: effectiveFeedVM),
      ],
      child: appWidget,
    );
  }
}
