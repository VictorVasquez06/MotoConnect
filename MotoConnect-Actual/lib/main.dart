import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/supabase_config.dart';

// REPOSITORIES - Interfaces y Implementaciones
import 'domain/repositories/i_auth_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'domain/repositories/i_event_repository.dart';
import 'data/repositories/event_repository.dart';
import 'domain/repositories/i_route_repository.dart';
import 'data/repositories/route_repository.dart';
import 'domain/repositories/i_user_repository.dart';
import 'data/repositories/user_repository.dart';
import 'domain/repositories/i_post_repository.dart';
import 'data/repositories/post_repository.dart';
import 'domain/repositories/i_taller_repository.dart';
import 'data/repositories/taller_repository.dart';
import 'domain/repositories/i_grupo_repository.dart';
import 'data/repositories/grupo_repository.dart';
import 'domain/repositories/i_navigation_repository.dart';
import 'data/repositories/navigation_repository.dart';

// BLOCS
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/events/events_bloc.dart';
import 'presentation/blocs/events/events_event.dart';
import 'presentation/blocs/routes/routes_bloc.dart';
import 'presentation/blocs/routes/routes_event.dart';
import 'presentation/blocs/profile/profile_bloc.dart';
import 'presentation/blocs/community/community_bloc.dart';
import 'presentation/blocs/community/community_event.dart';
import 'presentation/blocs/talleres/talleres_bloc.dart';
import 'presentation/blocs/talleres/talleres_event.dart';
import 'presentation/blocs/grupos/grupos_bloc.dart';
import 'presentation/blocs/grupos/grupos_event.dart';
import 'presentation/blocs/navigation/navigation_bloc.dart';

// SCREENS - Archivos en lib/presentation/views/
import 'presentation/views/auth/splash_screen.dart';
import 'screens/login_screen.dart';
import 'presentation/views/auth/register_screen.dart';
import 'presentation/views/home/home_screen.dart';
import 'presentation/views/profile/profile_screen.dart';

// VIEWS - Archivos en lib/presentation/views/
import 'presentation/views/events/events_screen.dart';
import 'presentation/views/routes/rutas_screen.dart';
import 'presentation/views/routes/saved_routes_screen.dart';
import 'presentation/views/talleres/talleres_screen.dart';
import 'presentation/views/community/community_screen.dart';
import 'presentation/views/routes/map_picker_screen.dart';
import 'presentation/views/grupos/grupos_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await SupabaseConfig.initialize(
    url: 'https://otxzwutudsruildrtuzy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90eHp3dXR1ZHNydWlsZHJ0dXp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4NDk2OTIsImV4cCI6MjA3ODQyNTY5Mn0.cAfcpSPDGdfDDNbk6bq6KiGdzuQhsOLUAcGz7dNwE5w',
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IAuthRepository>(create: (_) => AuthRepository()),
        RepositoryProvider<IEventRepository>(create: (_) => EventRepository()),
        RepositoryProvider<IRouteRepository>(create: (_) => RouteRepository()),
        RepositoryProvider<IUserRepository>(create: (_) => UserRepository()),
        RepositoryProvider<IPostRepository>(create: (_) => PostRepository()),
        RepositoryProvider<ITallerRepository>(
          create: (_) => TallerRepository(),
        ),
        RepositoryProvider<IGrupoRepository>(create: (_) => GrupoRepository()),
        RepositoryProvider<INavigationRepository>(
          create: (_) => NavigationRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) =>
                    AuthBloc(authRepository: context.read<IAuthRepository>())
                      ..add(const AuthCheckStatus()),
          ),
          BlocProvider(
            create:
                (context) => EventsBloc(
                  eventRepository: context.read<IEventRepository>(),
                )..add(const EventsFetchRequested()),
          ),
          BlocProvider(
            create:
                (context) => RoutesBloc(
                  routeRepository: context.read<IRouteRepository>(),
                )..add(const RoutesFetchRecentRequested()),
          ),
          BlocProvider(
            create:
                (context) => ProfileBloc(
                  userRepository: context.read<IUserRepository>(),
                ),
          ),
          BlocProvider(
            create:
                (context) => CommunityBloc(
                  postRepository: context.read<IPostRepository>(),
                )..add(const CommunityFetchPosts()),
          ),
          BlocProvider(
            create:
                (context) => TalleresBloc(
                  tallerRepository: context.read<ITallerRepository>(),
                )..add(const TalleresFetchRequested()),
          ),
          BlocProvider(
            create:
                (context) => GruposBloc(
                  grupoRepository: context.read<IGrupoRepository>(),
                )..add(const GruposFetchRequested()),
          ),
          BlocProvider(
            create:
                (context) => NavigationBloc(
                  navigationRepository: context.read<INavigationRepository>(),
                ),
          ),
        ],
        child: const MotoConnectApp(),
      ),
    ),
  );
}

class MotoConnectApp extends StatelessWidget {
  const MotoConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MotoConnect',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orangeAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.orangeAccent,
          secondary: Colors.amberAccent,
          surface: Color(0xFF1E1E1E),
          error: Colors.redAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.orangeAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.orangeAccent),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.black,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF222222),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.4),
          hintStyle: const TextStyle(color: Colors.grey),
          labelStyle: const TextStyle(color: Colors.orangeAccent),
          prefixIconColor: Colors.orangeAccent,
          suffixIconColor: Colors.orangeAccent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: Colors.orangeAccent,
              width: 2.0,
            ),
          ),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.orangeAccent,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/home': (context) => const HomeScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/eventos': (context) => const EventosScreen(),
        '/rutas': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          Map<String, dynamic>? rutaInicialArgs;
          if (arguments != null && arguments is Map<String, dynamic>) {
            rutaInicialArgs = arguments;
          }
          return RutasScreen(rutaInicial: rutaInicialArgs);
        },
        '/rutas-recomendadas': (context) => const RutasRecomendadasScreen(),
        '/talleres': (context) => const TalleresScreen(),
        '/comunidad': (context) => const ComunidadScreen(),
        '/grupos': (context) => const GruposScreen(),
        '/map-picker': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return MapPickerScreen(
            initialPosition: args?['initialPosition'] as LatLng?,
            initialSearchQuery: args?['initialSearchQuery'] as String?,
          );
        },
      },
    );
  }
}
