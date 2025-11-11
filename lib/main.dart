import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 👈 IMPORTANTE: Importar provider
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/supabase_config.dart'; // 👈 IMPORTANTE: Importar SupabaseConfig

// SCREENS - Archivos en lib/presentation/views/
import 'presentation/views/auth/splash_screen.dart';
import 'screens/login_screen.dart'; // Mantener el original
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

// VIEWMODELS - 👈 IMPORTANTE: Importar ViewModels
import 'presentation/viewmodels/auth/splash_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa el formato de fechas para español
  await initializeDateFormatting('es_ES', null);

  // Inicializa Supabase usando SupabaseConfig
  await SupabaseConfig.initialize(
    url: 'https://otxzwutudsruildrtuzy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90eHp3dXR1ZHNydWlsZHJ0dXp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4NDk2OTIsImV4cCI6MjA3ODQyNTY5Mn0.cAfcpSPDGdfDDNbk6bq6KiGdzuQhsOLUAcGz7dNwE5w',
  );

  // 👇 IMPORTANTE: Envolver con MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        // Aquí puedes agregar más providers conforme los necesites
        // Por ejemplo:
        // ChangeNotifierProvider(create: (_) => AuthViewModel()),
        // ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: const MotoConnectApp(),
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

      // Ruta inicial
      initialRoute: '/splash',

      // Definición de rutas
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
