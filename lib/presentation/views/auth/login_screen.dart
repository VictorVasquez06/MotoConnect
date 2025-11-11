import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/login_viewmodel.dart';

/// La Vista (View) para la pantalla de inicio de sesión.
///
/// Esta clase es responsable únicamente de construir la interfaz de usuario.
/// Es un `StatelessWidget` que utiliza `ChangeNotifierProvider` para crear
/// y proporcionar el `LoginViewModel` al árbol de widgets.
///
/// El widget `Consumer` se suscribe a los cambios en `LoginViewModel` y
/// reconstruye la UI cuando es notificado.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider crea una instancia del ViewModel y la hace disponible
    // para sus descendientes. Se asegura de que el ViewModel se limpie correctamente
    // cuando el widget se elimina del árbol.
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: const _LoginViewBody(),
    );
  }
}

/// El cuerpo de la vista de login.
///
/// Separado en un widget privado para que pueda acceder al `LoginViewModel`
/// proporcionado por `ChangeNotifierProvider` usando `context.watch` o `Consumer`.
class _LoginViewBody extends StatelessWidget {
  const _LoginViewBody();

  @override
  Widget build(BuildContext context) {
    // `context.watch<T>()` es una forma de escuchar los cambios en un Provider.
    // Hace que el método `build` se vuelva a ejecutar cada vez que `notifyListeners()`
    // es llamado en el LoginViewModel.
    final viewModel = context.watch<LoginViewModel>();

    // Se utiliza un Scaffold como base para la pantalla.
    return Scaffold(
      body: Container(
        // Decoración con gradiente, similar a la implementación original.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB0BEC5), Color(0xFF455A64)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // El logo de la aplicación.
                Image.asset('assets/images/logo.png', height: 120),
                const SizedBox(height: 40),

                // Campo de texto para el email, controlado por el ViewModel.
                TextField(
                  controller: viewModel.emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    // Muestra el mensaje de error si existe.
                    errorText: viewModel.errorMessage,
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de texto para la contraseña.
                TextField(
                  controller: viewModel.passwordController,
                  obscureText: !viewModel.isPasswordVisible,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        viewModel.isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: viewModel.togglePasswordVisibility,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón para restablecer la contraseña.
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    // La acción se delega al ViewModel.
                    onPressed:
                        viewModel.isLoading
                            ? null
                            : () async {
                              final message = await viewModel.resetPassword();
                              if (context.mounted) {
                                // Mostrar diálogo con el resultado
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text(
                                          message.contains('Por favor')
                                              ? 'Atención'
                                              : 'Correo Enviado',
                                        ),
                                        content: Text(
                                          message.contains('Por favor')
                                              ? message
                                              : '$message\n\nRevisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('Aceptar'),
                                          ),
                                        ],
                                      ),
                                );
                              }
                            },
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Muestra un indicador de progreso si está cargando, si no, los botones.
                if (viewModel.isLoading)
                  const CircularProgressIndicator(color: Colors.orangeAccent)
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Botón para registrarse.
                      ElevatedButton(
                        onPressed:
                            () =>
                                Navigator.pushNamed(context, '/crear-usuario'),
                        child: const Text('Sign Up'),
                      ),
                      // Botón para iniciar sesión.
                      ElevatedButton(
                        // La acción de login se delega completamente al ViewModel.
                        onPressed: () async {
                          final success = await viewModel.login();
                          if (success && context.mounted) {
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),

                  // Divisor "O"
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.white.withOpacity(0.5)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'O',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón de Google Sign In
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await viewModel.signInWithGoogle();
                        if (success && context.mounted) {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          // Si no existe el logo, mostrar ícono genérico
                          return const Icon(
                            Icons.g_mobiledata,
                            size: 32,
                            color: Colors.blue,
                          );
                        },
                      ),
                      label: const Text(
                        'Continuar con Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
