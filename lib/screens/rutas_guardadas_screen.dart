import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RutasRecomendadasScreen extends StatefulWidget {
  const RutasRecomendadasScreen({super.key});

  @override
  State<RutasRecomendadasScreen> createState() => _RutasRecomendadasScreenState();
}

class _RutasRecomendadasScreenState extends State<RutasRecomendadasScreen> {
  List<Map<String, dynamic>> rutas = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerRutasGuardadas();
  }

  Future<void> _obtenerRutasGuardadas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => cargando = false);
      }
      return;
    }

    try {
      final respuesta = await Supabase.instance.client
          .from('rutas_realizadas')
          .select()
          .eq('usuario_id', uid)
          .order('fecha', ascending: false);

      if (mounted) {
        setState(() {
          rutas = List<Map<String, dynamic>>.from(respuesta);
          cargando = false;
        });
      }
    } catch (e) {
      print('Error al cargar rutas: $e');
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  // <<< FUNCIÓN MOVIDA DENTRO DE LA CLASE >>>
  Future<void> _eliminarRuta(String rutaId, String nombreRuta) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar Eliminación"),
          content: Text("¿Estás seguro de que quieres eliminar la ruta '$nombreRuta'?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      try {
        await Supabase.instance.client
            .from('rutas_realizadas')
            .delete()
            .eq('id', rutaId);

        if (mounted) {
          setState(() {
            rutas.removeWhere((r) => r['id'] == rutaId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ruta eliminada correctamente.")),
          );
        }
      } catch (e) {
        print("Error al eliminar ruta: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar la ruta: $e")),
        );
      }
    }
  }

  // Dentro de la clase _RutasRecomendadasScreenState en rutas_guardadas_screen.dart

Future<void> _compartirRutaEnComunidad(Map<String, dynamic> rutaData) async {
  final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserUid == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes iniciar sesión para compartir.")));
    }
    return;
  }

  String? mensajeUsuario;
  final TextEditingController mensajeController = TextEditingController();

  // Mostrar diálogo para mensaje opcional
  final bool? confirmarCompartir = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text("Compartir Ruta: ${rutaData['nombre_ruta'] ?? 'Ruta'}"),
        content: TextField(
          controller: mensajeController,
          decoration:
              const InputDecoration(hintText: "Añade un mensaje (opcional)..."),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              mensajeUsuario = mensajeController.text.trim();
              Navigator.pop(dialogContext, true);
            },
            child: const Text("Compartir"),
          ),
        ],
      );
    },
  );

  if (confirmarCompartir != true) {
    return; // El usuario canceló
  }

  // Mostrar indicador de carga si lo deseas
  // if (mounted) setState(() => cargando = true); // Ya tienes _cargando, podrías usarlo

  try {
    await Supabase.instance.client.from('comentarios_comunidad').insert({
      'usuario_id': currentUserUid,
      'contenido': mensajeUsuario?.isEmpty ?? true
          ? "¡Echen un vistazo a esta ruta que guardé: ${rutaData['nombre_ruta'] ?? 'Sin nombre'}!" // Mensaje por defecto
          : mensajeUsuario,
      'tipo': 'ruta_compartida',
      'referencia_ruta_id': rutaData['id'], // El ID de la ruta de la tabla 'rutas_realizadas'
      'fecha': DateTime.now().toIso8601String(),
      // 'imagen_url' es null para este tipo
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Ruta compartida en la comunidad!")));
    }
  } catch (e) {
    print("Error al compartir ruta: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al compartir la ruta: ${e.toString()}")));
    }
  } finally {
    // if (mounted) setState(() => cargando = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rutas Guardadas")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : rutas.isEmpty
              ? const Center(child: Text("No hay rutas guardadas."))
              : ListView.builder(
                  itemCount: rutas.length,
                  itemBuilder: (context, index) {
                    final ruta = rutas[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: const Icon(Icons.route),
                        title: Text(ruta['nombre_ruta'] ?? 'Ruta'),
                        subtitle: Text(
                            "Fecha: ${ruta['fecha']?.toString().split('T').first ?? 'Sin fecha'}\n"
                            "${ruta['descripcion_ruta'] ?? ''}"), // Muestra la descripción
                        // <<< MODIFICADO: Row para botón y icono >>>
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.share_outlined, color: Colors.green[700]),
                              tooltip: 'Compartir en comunidad',
                              onPressed: () {_compartirRutaEnComunidad(ruta);
                                },
                                ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              tooltip: 'Eliminar ruta',
                              onPressed: () => _eliminarRuta(ruta['id'], ruta['nombre_ruta'] ?? 'Ruta Sin Nombre'),
                            ),
                            const Icon(Icons.map_outlined),
                          ],
                        ),
                        onTap: () {
                          // Devolvemos la ruta al hacer tap
                          Navigator.pop(context, ruta);
                        },
                      ),
                    );
                  },
                ),
    );
  }
} // <<< CIERRE CORRECTO DE LA CLASE