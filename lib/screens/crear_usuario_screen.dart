import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrearUsuarioScreen extends StatefulWidget {
  const CrearUsuarioScreen({super.key});

  @override
  State<CrearUsuarioScreen> createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends State<CrearUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  void _registrarUsuario() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Crear el usuario en Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _correoController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. Verificar si la creación en Firebase fue exitosa y obtener el UID
        if (userCredential.user != null) {
          String uid = userCredential.user!.uid;
          String nombre = _nombreController.text.trim();
          String correo = _correoController.text.trim();

          // 3. <<< PUNTO CLAVE: Intentar insertar los datos del usuario en tu tabla 'usuarios' de Supabase >>>
          try {
            await Supabase.instance.client
                .from('usuarios') // Nombre EXACTO de tu tabla en Supabase
                .insert({
                  'id': uid,       // El UID de Firebase se guarda como 'id' en tu tabla 'usuarios'
                  'nombre': nombre,
                  'correo': correo,
                  // 'fecha_creacion' usualmente se pone por defecto con NOW() en Supabase si así lo configuraste
                  // 'modelo_moto' inicialmente será null aquí, el usuario lo actualizará en su perfil
                });

            // Si llegamos aquí, el usuario se creó en Firebase y se guardó en Supabase
            if (mounted) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Usuario creado"),
                  content: Text("¡Bienvenido, $nombre! Tu cuenta ha sido creada."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Cierra el diálogo
                        Navigator.pushReplacementNamed(context, '/login'); // Navega a la pantalla de login
                      },
                      child: const Text("Aceptar"),
                    ),
                  ],
                ),
              );
            }
          } catch (e_supabase) {
            // Error al intentar guardar en Supabase
            print("Error al guardar datos del usuario en Supabase: $e_supabase");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error al finalizar el registro del perfil: ${e_supabase.toString()}")),
              );
            }
            // Consideración: Si falla aquí, el usuario YA ESTÁ en Firebase Auth.
            // Podrías intentar eliminarlo de Firebase Auth para consistencia:
            // await userCredential.user?.delete();
            // O simplemente informar al usuario que contacte a soporte.
          }
        }
      } on FirebaseAuthException catch (e_auth) {
        // Tu manejo de errores de FirebaseAuth existente (déjalo como está)
        String mensajeError = 'Error desconocido al crear usuario';
        if (e_auth.code == 'email-already-in-use') {
          mensajeError = 'El correo ya está en uso.';
        } else if (e_auth.code == 'weak-password') {
          mensajeError = 'La contraseña es demasiado débil.';
        } else if (e_auth.code == 'invalid-email') {
          mensajeError = 'Correo inválido.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensajeError)),
          );
        }
      } catch (e_general) {
        print("Error general en _registrarUsuario: $e_general");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ocurrió un error inesperado: ${e_general.toString()}")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Usuario")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: "Nombre completo"),
                validator:
                    (value) => value!.isEmpty ? "Ingrese su nombre" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                ),
                validator:
                    (value) => value!.isEmpty ? "Ingrese su correo" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Contraseña"),
                obscureText: true,
                validator:
                    (value) => value!.isEmpty ? "Ingrese una contraseña" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmarPasswordController,
                decoration: const InputDecoration(
                  labelText: "Confirmar contraseña",
                ),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) return "Confirme su contraseña";
                  if (value != _passwordController.text) {
                    return "Las contraseñas no coinciden";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _registrarUsuario,
                child: const Text("Registrar"),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text("Cancelar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
