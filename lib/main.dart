import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// Se actualizan las importaciones para reflejar la nueva estructura de carpetas (views).
import 'views/login_view.dart'; // <<< ACTUALIZADO
import 'views/home_screen.dart';
import 'views/perfil_sreen.dart';
import 'views/eventos_view.dart';
import 'views/rutas_screen.dart';
import 'views/rutas_guardadas_screen.dart';
import 'views/talleres_screen.dart';
import 'views/comunidad_screen.dart';
import 'views/crear_usuario_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'views/map_picker_screen.dart';

// --- COMENTARIO EXPLICATIVO ---
// El main.dart ahora es más limpio. La inicialización de servicios como Firebase
// se mantiene aquí, pero la lógica de la aplicación se distribuye en la
// arquitectura MVVM (Model-View-ViewModel).
// La gestión de estado global, si fuera necesaria, se podría iniciar aquí
// utilizando un MultiProvider por encima de MaterialApp.

void main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de usar plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase. Esto es necesario para servicios como FirebaseAuth.
  await Firebase.initializeApp();

  // Inicializa Supabase (aunque en la V2 se migraría a microservicios, se mantiene por compatibilidad).
  await Supabase.initialize(
    url: 'https://rikubpbpxesxcrnspsyf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpa3VicGJweGVzeGNybnNwc3lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzMTc2MjUsImV4cCI6MjA2Mzg5MzYyNX0.uAge8CKWaJxFg49onB48cwtAqPuTIIXdNpSjBzp9kTw',
  );

  // Inicializa el formato de fecha para la localización en español de Colombia.
  await initializeDateFormatting('es_CO', null);

  // Inicia la aplicación Flutter.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MotoConnect',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orangeAccent,
        colorScheme: ColorScheme.dark(
          primary: Colors.orangeAccent,
          secondary: Colors.amberAccent,
          surface: const Color(0xFF1E1E1E),
          background: const Color(0xFF121212),
          error: Colors.redAccent,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onError: Colors.black,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1F1F1F),
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.orangeAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.orangeAccent.shade100),
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
          style: TextButton.styleFrom(
            foregroundColor: Colors.orangeAccent.shade100,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.black,
        ),
        cardTheme: CardThemeData(
          // <<< CORRECCIÓN AQUÍ
          color: const Color(0xFF222222),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withOpacity(0.4),
          hintStyle: TextStyle(color: Colors.grey[600]),
          labelStyle: TextStyle(color: Colors.orangeAccent.shade100),
          prefixIconColor: Colors.orangeAccent.shade100,
          suffixIconColor: Colors.orangeAccent.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[800]!, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.orangeAccent.shade200,
              width: 2.0,
            ),
          ),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
        textTheme: Typography.material2021(
          platform: TargetPlatform.android,
        ).white.copyWith(
          bodyLarge: TextStyle(color: Colors.grey[300]),
          bodyMedium: TextStyle(color: Colors.grey[400]),
          titleLarge: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          labelLarge: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(color: Colors.orangeAccent.shade100),
          displayMedium: TextStyle(color: Colors.orangeAccent.shade100),
          displayLarge: TextStyle(color: Colors.orangeAccent.shade100),
          headlineSmall: TextStyle(color: Colors.orangeAccent.shade100),
          headlineMedium: TextStyle(color: Colors.orangeAccent.shade100),
        ),
        iconTheme: IconThemeData(color: Colors.orangeAccent.shade100),
        dividerColor: Colors.grey[850],
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.orangeAccent,
        ),
        dialogTheme: DialogThemeData(
          // <<< CORRECCIÓN AQUÍ
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.orangeAccent.withOpacity(0.2),
          disabledColor: Colors.grey.shade800,
          selectedColor: Colors.orangeAccent,
          secondarySelectedColor: Colors.amber,
          padding: const EdgeInsets.all(4.0),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
          brightness: Brightness.dark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      // La ruta inicial sigue siendo /login.
      initialRoute: '/login',
      // El sistema de rutas se mantiene, pero la pantalla de login ahora
      // apunta a la nueva vista refactorizada (LoginScreen que contiene _LoginViewBody).
      routes: {
        '/login':
            (context) => const LoginScreen(), // <- Apunta a la nueva vista MVVM
        '/home': (context) => const HomeScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/eventos':
            (context) =>
                const EventosScreen(), // <- Apunta a la nueva vista MVVM
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
        '/crear-usuario': (context) => const CrearUsuarioScreen(),
        '/map-picker': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          return MapPickerScreen(
            initialPosition:
                args?['initialPosition']
                    as LatLng?, // <<< LatLng ahora es reconocido
            initialSearchQuery: args?['initialSearchQuery'] as String?,
          );
        },
      },
    );
  }
}
