import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/exchange_remote_datasource.dart';
import 'data/datasources/remote/offers_remote_datasource.dart';
import 'data/datasources/remote/ratings_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/exchange_repository_impl.dart';
import 'data/repositories/offer_repository_impl.dart';
import 'data/repositories/ratings_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'domain/models/offer_entity.dart';
import 'domain/usecases/get_session_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/propose_exchange_usecase.dart';
import 'domain/usecases/publish_offer_usecase.dart';
import 'domain/usecases/rate_user_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/create_offer_viewmodel.dart';
import 'presentation/viewmodels/exchange_viewmodel.dart';
import 'presentation/viewmodels/feed_viewmodel.dart';
import 'presentation/views/auth/login_view.dart';
import 'presentation/views/auth/register_view.dart';
import 'presentation/views/exchange/create_offer_view.dart';
import 'presentation/views/exchange/exchange_confirmation_view.dart';
import 'presentation/views/exchange/offer_detail_view.dart';
import 'presentation/views/exchange/rate_user_view.dart';
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

  final exchangeRemoteDataSource = supabaseInitialized
      ? SupabaseExchangeRemoteDataSource()
      : MockExchangeRemoteDataSource();
  final exchangeRepository = ExchangeRepositoryImpl(
    remoteDataSource: exchangeRemoteDataSource,
  );
  final proposeExchangeUseCase = ProposeExchangeUseCase(
    exchangeRepository: exchangeRepository,
    offerRepository: offerRepository,
  );

  final userRepository = UserRepositoryImpl();
  final ratingsRemoteDataSource = supabaseInitialized
      ? SupabaseRatingsRemoteDataSource()
      : MockRatingsRemoteDataSource();
  final ratingsRepository = RatingsRepositoryImpl(
    remoteDataSource: ratingsRemoteDataSource,
  );
  final rateUserUseCase = RateUserUseCase(
    userRepository,
    ratingsRepository: ratingsRepository,
  );

  final exchangeViewModel = ExchangeViewModel(
    proposeExchangeUseCase: proposeExchangeUseCase,
    rateUserUseCase: rateUserUseCase,
    exchangeRepository: exchangeRepository,
  );

  runApp(SwappiaApp(
    authViewModel: authViewModel,
    createOfferViewModel: createOfferViewModel,
    feedViewModel: feedViewModel,
    exchangeViewModel: exchangeViewModel,
  ));
}

class SwappiaApp extends StatefulWidget {
  final AuthViewModel? authViewModel;
  final CreateOfferViewModel? createOfferViewModel;
  final FeedViewModel? feedViewModel;
  final ExchangeViewModel? exchangeViewModel;

  const SwappiaApp({
    super.key,
    this.authViewModel,
    this.createOfferViewModel,
    this.feedViewModel,
    this.exchangeViewModel,
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
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case LoginView.routeName:
            page = const LoginView();
            break;
          case RegisterView.routeName:
            page = const RegisterView();
            break;
          case FeedView.routeName:
            page = const FeedView();
            break;
          case CreateOfferView.routeName:
            page = const CreateOfferView();
            break;
          case OfferDetailView.routeName:
            final offer = settings.arguments as OfferEntity?;
            page = OfferDetailView(offer: offer);
            break;
          case ExchangeConfirmationView.routeName:
            final args = settings.arguments as ExchangeConfirmationArgs;
            page = ExchangeConfirmationView(
              offer: args.offer,
              proposal: args.proposal,
              counterpartName: args.counterpartName,
            );
            break;
          case RateUserView.routeName:
            final args = settings.arguments as RateUserArgs;
            page = RateUserView(
              targetUserId: args.targetUserId,
              targetUserName: args.targetUserName,
              exchangeId: args.exchangeId,
              offerTitle: args.offerTitle,
            );
            break;
          default:
            return null;
        }

        return PageRouteBuilder(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
      },
      home: Consumer<AuthViewModel>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const FeedView();
          }
          return const LoginView();
        },
      ),
    );

    return MultiProvider(
      providers: [
        if (widget.authViewModel != null)
          ChangeNotifierProvider<AuthViewModel>.value(
            value: widget.authViewModel!,
          )
        else
          ChangeNotifierProvider<AuthViewModel>(
            create: (_) {
              final authRepo = AuthRepositoryImpl(
                remoteDataSource: MockAuthRemoteDataSource(),
                localDataSource: SharedPreferencesAuthLocalDataSource(),
              );
              return AuthViewModel(
                loginUseCase: LoginUseCase(authRepo),
                registerUseCase: RegisterUseCase(authRepo),
                getSessionUseCase: GetSessionUseCase(authRepo),
              );
            },
          ),
        if (widget.createOfferViewModel != null)
          ChangeNotifierProvider<CreateOfferViewModel>.value(
            value: widget.createOfferViewModel!,
          )
        else
          ChangeNotifierProvider<CreateOfferViewModel>(
            create: (_) {
              final repo = OfferRepositoryImpl(
                remoteDataSource: MockOffersRemoteDataSource(),
              );
              return CreateOfferViewModel(
                publishOfferUseCase: PublishOfferUseCase(repo),
              );
            },
          ),
        if (widget.feedViewModel != null)
          ChangeNotifierProvider<FeedViewModel>.value(
            value: widget.feedViewModel!,
          )
        else
          ChangeNotifierProvider<FeedViewModel>(
            create: (_) {
              final repo = OfferRepositoryImpl(
                remoteDataSource: MockOffersRemoteDataSource(),
              );
              return FeedViewModel(
                offerRepository: repo,
              );
            },
          ),
        if (widget.exchangeViewModel != null)
          ChangeNotifierProvider<ExchangeViewModel>.value(
            value: widget.exchangeViewModel!,
          )
        else
          ChangeNotifierProvider<ExchangeViewModel>(
            create: (_) {
              final exRepo = ExchangeRepositoryImpl(
                remoteDataSource: MockExchangeRemoteDataSource(),
              );
              final offRepo = OfferRepositoryImpl(
                remoteDataSource: MockOffersRemoteDataSource(),
              );
              final userRepo = UserRepositoryImpl();
              final ratingsRepo = RatingsRepositoryImpl(
                remoteDataSource: MockRatingsRemoteDataSource(),
              );
              return ExchangeViewModel(
                proposeExchangeUseCase: ProposeExchangeUseCase(
                  exchangeRepository: exRepo,
                  offerRepository: offRepo,
                ),
                rateUserUseCase: RateUserUseCase(
                  userRepo,
                  ratingsRepository: ratingsRepo,
                ),
                exchangeRepository: exRepo,
              );
            },
          ),
      ],
      child: appWidget,
    );
  }
}
