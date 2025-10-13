import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _modeloMotoController = TextEditingController();

  bool _cargando = true;
  String? _userId; // Para guardar el UID del usuario actual

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _modeloMotoController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
    });

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _userId = firebaseUser.uid;
      _correoController.text = firebaseUser.email ?? 'No disponible';

      // <<< INICIO DE LA MODIFICACIÓN: Verificación explícita de _userId >>>
      if (_userId == null) {
        print("Error crítico: _userId es nulo antes de la consulta a Supabase en _cargarDatosUsuario.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error fatal: No se pudo identificar al usuario.")),
          );
          setState(() {
            _cargando = false;
            _nombreController.text = 'Error de ID';
            _modeloMotoController.text = '';
          });
        }
        return; // Salimos de la función si _userId es nulo
      }
      // <<< FIN DE LA MODIFICACIÓN >>>

      try {
        final respuesta = await Supabase.instance.client
            .from('usuarios')
            .select('nombre, modelo_moto')
            .eq('id', _userId!) // El '!' es más seguro después de la verificación explícita
            .single();

        if (mounted) {
          _nombreController.text = respuesta['nombre'] ?? 'Completa tu nombre';
          _modeloMotoController.text = respuesta['modelo_moto'] ?? '';
        }
      } catch (e) {
        print("Error al cargar datos de 'usuarios' en Supabase: $e");
        if (mounted) {
          _nombreController.text = '';
          _modeloMotoController.text = '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No se pudieron cargar los datos del perfil: ${e.toString()}")),
          );
        }
      }
    } else {
      print("Error: Usuario de Firebase no encontrado en PerfilScreen.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario no autenticado.")),
        );
        // Considera navegar a login si esto ocurre:
        // Navigator.of(context).pushReplacementNamed('/login');
      }
    }

    if (mounted) {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _guardarPerfil() async {
    if (_formKey.currentState!.validate()) {
      if (_userId == null) { // Esta guarda es crucial
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: No se pudo identificar al usuario. Intenta recargar.")),
          );
        }
        setState(() => _cargando = false);
        return;
      }

      if (!mounted) return;
      setState(() {
        _cargando = true;
      });

      try {
        await Supabase.instance.client
            .from('usuarios')
            .upsert({
              'id': _userId!,
              'correo': _correoController.text.trim(),
              'nombre': _nombreController.text.trim(),
              'modelo_moto': _modeloMotoController.text.trim().isEmpty ? null : _modeloMotoController.text.trim(),
            });
            

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Perfil guardado con éxito.")),
          );
        }
      } catch (e) {
        print("Error al guardar perfil en Supabase: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al guardar perfil: ${e.toString()}")),
          );
        }
      }

      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.person, size: 50, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: "Nombre",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _correoController,
                      decoration: const InputDecoration(
                        labelText: "Correo Electrónico",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modeloMotoController,
                      decoration: const InputDecoration(
                        labelText: "Modelo de Moto",
                        hintText: "Ej: Yamaha MT-07",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.motorcycle_outlined),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text("Guardar Cambios"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _cargando ? null : _guardarPerfil,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      "Mis Rutas Guardadas",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                        icon: const Icon(Icons.list_alt_outlined),
                        label: const Text("Ver mis rutas"),
                        onPressed:  () async {
                          final resultado = await Navigator.pushNamed(context, '/rutas-recomendadas');
                          if (resultado != null && resultado is Map<String, dynamic>){
                            if (mounted) {
                             Navigator.pushNamed(context, '/rutas', arguments: resultado);
                            }
                          }
                        },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}