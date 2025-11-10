/// Pantalla Splash - Pantalla de carga inicial
///
/// Responsabilidades:
/// - Mostrar logo de la aplicación
/// - Verificar estado de autenticación
/// - Redirigir a login o home según corresponda
///
/// Patrón: MVVM
/// - Esta es la View (solo UI)
/// - Usa SplashViewModel para la lógica
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/splash_viewmodel.dart';
import '../../../core/constants/route_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Espera a que el primer frame se construya, luego verifica auth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  /// Verifica el estado de autenticación y navega
  Future<void> _checkAuthentication() async {
    // Obtiene el ViewModel sin escuchar cambios
    final viewModel = context.read<SplashViewModel>();

    // Verifica autenticación
    final isAuthenticated = await viewModel.checkAuthentication();

    if (!mounted) return;

    // Navega según el resultado
    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, RouteConstants.home);
    } else {
      Navigator.pushReplacementNamed(context, RouteConstants.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo con gradiente
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB0BEC5), // Gris claro
              Color(0xFF455A64), // Gris oscuro
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de la aplicación
              Image.asset(
                'assets/images/logo.png',
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback si no se encuentra el logo
                  return const Icon(
                    Icons.motorcycle,
                    size: 100,
                    color: Colors.white,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Nombre de la app
              const Text(
                'MotoConnect',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Indicador de carga
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),

              // Texto de carga
              const Text(
                'Cargando...',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
