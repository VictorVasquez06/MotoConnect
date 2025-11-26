/// Repository de Grupos de Rutas
///
/// Patrón Repository:
/// - Abstrae la fuente de datos de grupos
/// - Permite cambiar implementación sin afectar ViewModels
/// - Facilita testing con mocks
///
/// Responsabilidades:
/// - Operaciones CRUD de grupos de rutas
/// - Gestión de miembros de grupos
/// - Gestión de sesiones activas
/// - Gestión de ubicaciones en tiempo real
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grupo_ruta_model.dart';
import '../models/miembro_grupo_model.dart';
import '../models/sesion_ruta_activa_model.dart';
import '../models/ubicacion_tiempo_real_model.dart';
import 'dart:math';

class GrupoRepository {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  /// Cliente de Supabase
  final SupabaseClient _supabase;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  /// Constructor con inyección de dependencias
  GrupoRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  // ========================================
  // MÉTODOS DE GRUPOS
  // ========================================

  /// Crea un nuevo grupo
  ///
  /// [nombre] - Nombre del grupo
  /// [descripcion] - Descripción del grupo (opcional)
  ///
  /// Retorna:
  /// - GrupoRutaModel del grupo creado
  Future<GrupoRutaModel> crearGrupo({
    required String nombre,
    String? descripcion,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Generar código único de invitación
      final codigoInvitacion = await _generarCodigoUnico();

      final response = await _supabase.from('grupos_ruta').insert({
        'nombre': nombre,
        'descripcion': descripcion,
        'codigo_invitacion': codigoInvitacion,
        'creado_por': userId,
        'activo': true,
      }).select().single();

      return GrupoRutaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear grupo: ${e.toString()}');
    }
  }

  /// Obtiene los grupos del usuario actual
  ///
  /// Retorna:
  /// - Lista de grupos donde el usuario es miembro
  Future<List<GrupoRutaModel>> obtenerMisGrupos() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Primero obtener los IDs de grupos donde es miembro
      final miembrosResponse = await _supabase
          .from('miembros_grupo')
          .select('grupo_id')
          .eq('usuario_id', userId);

      // Si no tiene grupos, retornar lista vacía
      if (miembrosResponse.isEmpty) {
        return [];
      }

      // Extraer los IDs de grupos
      final grupoIds = (miembrosResponse as List)
          .map((e) => e['grupo_id'] as String)
          .toList();

      // Obtener los grupos
      final response = await _supabase
          .from('grupos_ruta')
          .select()
          .inFilter('id', grupoIds);

      return (response as List)
          .map((json) => GrupoRutaModel.fromJson(json))
          .toList();
    } catch (e) {
      // Si no hay grupos, retornar lista vacía
      if (e.toString().contains('empty')) {
        return [];
      }
      throw Exception('Error al obtener grupos: ${e.toString()}');
    }
  }

  /// Obtiene un grupo por ID
  ///
  /// [grupoId] - ID del grupo
  ///
  /// Retorna:
  /// - GrupoRutaModel del grupo
  Future<GrupoRutaModel?> obtenerGrupo(String grupoId) async {
    try {
      final response = await _supabase
          .from('grupos_ruta')
          .select()
          .eq('id', grupoId)
          .single();

      return GrupoRutaModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Busca un grupo por código de invitación
  ///
  /// [codigo] - Código de invitación
  ///
  /// Retorna:
  /// - GrupoRutaModel del grupo
  /// - null si no se encuentra
  Future<GrupoRutaModel?> buscarGrupoPorCodigo(String codigo) async {
    try {
      final response = await _supabase
          .from('grupos_ruta')
          .select()
          .eq('codigo_invitacion', codigo.toUpperCase())
          .eq('activo', true)
          .single();

      return GrupoRutaModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Actualiza un grupo
  ///
  /// [grupoId] - ID del grupo
  /// [nombre] - Nuevo nombre (opcional)
  /// [descripcion] - Nueva descripción (opcional)
  /// [activo] - Nuevo estado activo (opcional)
  Future<void> actualizarGrupo({
    required String grupoId,
    String? nombre,
    String? descripcion,
    bool? activo,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (nombre != null) updates['nombre'] = nombre;
      if (descripcion != null) updates['descripcion'] = descripcion;
      if (activo != null) updates['activo'] = activo;

      if (updates.isEmpty) return;

      await _supabase.from('grupos_ruta').update(updates).eq('id', grupoId);
    } catch (e) {
      throw Exception('Error al actualizar grupo: ${e.toString()}');
    }
  }

  /// Elimina un grupo (solo admins)
  ///
  /// [grupoId] - ID del grupo
  Future<void> eliminarGrupo(String grupoId) async {
    try {
      await _supabase.from('grupos_ruta').delete().eq('id', grupoId);
    } catch (e) {
      throw Exception('Error al eliminar grupo: ${e.toString()}');
    }
  }

  // ========================================
  // MÉTODOS DE MIEMBROS
  // ========================================

  /// Unirse a un grupo mediante código
  ///
  /// [codigo] - Código de invitación
  ///
  /// Retorna:
  /// - GrupoRutaModel del grupo al que se unió
  Future<GrupoRutaModel> unirseAGrupo(String codigo) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Buscar el grupo por código
      final grupo = await buscarGrupoPorCodigo(codigo);
      if (grupo == null) {
        throw Exception('Código de invitación inválido');
      }

      // Verificar si ya es miembro
      final yaMiembro = await esMiembroDeGrupo(grupo.id);
      if (yaMiembro) {
        throw Exception('Ya eres miembro de este grupo');
      }

      // Agregar como miembro
      await _supabase.from('miembros_grupo').insert({
        'grupo_id': grupo.id,
        'usuario_id': userId,
        'es_admin': false,
      });

      return grupo;
    } catch (e) {
      throw Exception('Error al unirse al grupo: ${e.toString()}');
    }
  }

  /// Obtiene los miembros de un grupo
  ///
  /// [grupoId] - ID del grupo
  ///
  /// Retorna:
  /// - Lista de miembros con información de usuario
  Future<List<MiembroGrupoModel>> obtenerMiembrosGrupo(String grupoId) async {
    try {
      final response = await _supabase
          .from('miembros_grupo')
          .select('*, usuarios(*)')
          .eq('grupo_id', grupoId)
          .order('fecha_union');

      return (response as List)
          .map((json) => MiembroGrupoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener miembros: ${e.toString()}');
    }
  }

  /// Verifica si el usuario actual es miembro de un grupo
  ///
  /// [grupoId] - ID del grupo
  ///
  /// Retorna:
  /// - true si es miembro, false si no
  Future<bool> esMiembroDeGrupo(String grupoId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('miembros_grupo')
          .select('id')
          .eq('grupo_id', grupoId)
          .eq('usuario_id', userId);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si el usuario actual es admin de un grupo
  ///
  /// [grupoId] - ID del grupo
  ///
  /// Retorna:
  /// - true si es admin, false si no
  Future<bool> esAdminDeGrupo(String grupoId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('miembros_grupo')
          .select('es_admin')
          .eq('grupo_id', grupoId)
          .eq('usuario_id', userId)
          .single();

      return response['es_admin'] as bool;
    } catch (e) {
      return false;
    }
  }

  /// Salir de un grupo
  ///
  /// [grupoId] - ID del grupo
  Future<void> salirDeGrupo(String grupoId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase
          .from('miembros_grupo')
          .delete()
          .eq('grupo_id', grupoId)
          .eq('usuario_id', userId);
    } catch (e) {
      throw Exception('Error al salir del grupo: ${e.toString()}');
    }
  }

  /// Eliminar un miembro del grupo (solo admins)
  ///
  /// [grupoId] - ID del grupo
  /// [usuarioId] - ID del usuario a eliminar
  Future<void> eliminarMiembro(String grupoId, String usuarioId) async {
    try {
      await _supabase
          .from('miembros_grupo')
          .delete()
          .eq('grupo_id', grupoId)
          .eq('usuario_id', usuarioId);
    } catch (e) {
      throw Exception('Error al eliminar miembro: ${e.toString()}');
    }
  }

  // ========================================
  // MÉTODOS DE SESIONES
  // ========================================

  /// Inicia una nueva sesión de ruta activa
  ///
  /// [grupoId] - ID del grupo
  /// [nombreSesion] - Nombre de la sesión
  /// [descripcion] - Descripción (opcional)
  /// [rutaId] - ID de ruta planificada (opcional, null para ruta en vivo)
  ///
  /// Retorna:
  /// - SesionRutaActivaModel de la sesión creada
  Future<SesionRutaActivaModel> iniciarSesion({
    required String grupoId,
    required String nombreSesion,
    String? descripcion,
    String? rutaId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase.from('sesiones_ruta_activa').insert({
        'grupo_id': grupoId,
        'ruta_id': rutaId,
        'nombre_sesion': nombreSesion,
        'descripcion': descripcion,
        'estado': 'activa',
        'iniciada_por': userId,
      }).select().single();

      return SesionRutaActivaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }

  /// Obtiene las sesiones activas de un grupo
  ///
  /// [grupoId] - ID del grupo
  ///
  /// Retorna:
  /// - Lista de sesiones activas
  Future<List<SesionRutaActivaModel>> obtenerSesionesActivas(
    String grupoId,
  ) async {
    try {
      final response = await _supabase
          .from('sesiones_ruta_activa')
          .select()
          .eq('grupo_id', grupoId)
          .eq('estado', 'activa')
          .order('fecha_inicio', ascending: false);

      return (response as List)
          .map((json) => SesionRutaActivaModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtiene una sesión por ID
  ///
  /// [sesionId] - ID de la sesión
  ///
  /// Retorna:
  /// - SesionRutaActivaModel de la sesión
  Future<SesionRutaActivaModel?> obtenerSesion(String sesionId) async {
    try {
      final response = await _supabase
          .from('sesiones_ruta_activa')
          .select()
          .eq('id', sesionId)
          .single();

      return SesionRutaActivaModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Actualiza el estado de una sesión
  ///
  /// [sesionId] - ID de la sesión
  /// [estado] - Nuevo estado
  Future<void> actualizarEstadoSesion({
    required String sesionId,
    required EstadoSesion estado,
  }) async {
    try {
      final updates = <String, dynamic>{
        'estado': estado.toStringValue(),
      };

      // Si se finaliza, agregar fecha de fin
      if (estado == EstadoSesion.finalizada) {
        updates['fecha_fin'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('sesiones_ruta_activa')
          .update(updates)
          .eq('id', sesionId);
    } catch (e) {
      throw Exception('Error al actualizar sesión: ${e.toString()}');
    }
  }

  /// Finaliza una sesión
  ///
  /// [sesionId] - ID de la sesión
  Future<void> finalizarSesion(String sesionId) async {
    await actualizarEstadoSesion(
      sesionId: sesionId,
      estado: EstadoSesion.finalizada,
    );
  }

  // ========================================
  // MÉTODOS DE UBICACIONES EN TIEMPO REAL
  // ========================================

  /// Actualiza la ubicación del usuario en una sesión
  ///
  /// [sesionId] - ID de la sesión
  /// [latitud] - Latitud
  /// [longitud] - Longitud
  /// [velocidad] - Velocidad en km/h (opcional)
  /// [direccion] - Dirección en grados (opcional)
  /// [altitud] - Altitud en metros (opcional)
  /// [precisionMetros] - Precisión en metros (opcional)
  Future<void> actualizarUbicacion({
    required String sesionId,
    required double latitud,
    required double longitud,
    double? velocidad,
    double? direccion,
    double? altitud,
    double? precisionMetros,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Insertar nueva ubicación
      await _supabase.from('ubicaciones_tiempo_real').insert({
        'sesion_id': sesionId,
        'usuario_id': userId,
        'latitud': latitud,
        'longitud': longitud,
        'velocidad': velocidad,
        'direccion': direccion,
        'altitud': altitud,
        'precision_metros': precisionMetros,
      });
    } catch (e) {
      throw Exception('Error al actualizar ubicación: ${e.toString()}');
    }
  }

  /// Obtiene las ubicaciones actuales de todos los miembros en una sesión
  ///
  /// [sesionId] - ID de la sesión
  ///
  /// Retorna:
  /// - Lista de ubicaciones actuales con información de usuario
  Future<List<UbicacionTiempoRealModel>> obtenerUbicacionesActuales(
    String sesionId,
  ) async {
    try {
      // Usar la vista que ya trae solo las ubicaciones más recientes
      final response = await _supabase
          .from('vista_ubicaciones_sesion_actual')
          .select()
          .eq('sesion_id', sesionId);

      return (response as List)
          .map((json) => UbicacionTiempoRealModel.fromJson(json))
          .toList();
    } catch (e) {
      // Si falla la vista, intentar con query manual
      try {
        return await _obtenerUbicacionesActualesManual(sesionId);
      } catch (e2) {
        return [];
      }
    }
  }

  /// Método auxiliar para obtener ubicaciones cuando la vista no está disponible
  Future<List<UbicacionTiempoRealModel>> _obtenerUbicacionesActualesManual(
    String sesionId,
  ) async {
    final response = await _supabase
        .from('ubicaciones_tiempo_real')
        .select()
        .eq('sesion_id', sesionId)
        .order('ultima_actualizacion', ascending: false);

    // Agrupar por usuario y tomar solo la más reciente de cada uno
    final Map<String, Map<String, dynamic>> ubicacionesPorUsuario = {};

    for (final item in response as List) {
      final usuarioId = item['usuario_id'] as String;
      if (!ubicacionesPorUsuario.containsKey(usuarioId)) {
        ubicacionesPorUsuario[usuarioId] = item;
      }
    }

    return ubicacionesPorUsuario.values
        .map((json) => UbicacionTiempoRealModel.fromJson(json))
        .toList();
  }

  /// Suscribirse a cambios de ubicaciones en tiempo real
  ///
  /// [sesionId] - ID de la sesión
  /// [onData] - Callback cuando hay nuevas ubicaciones
  ///
  /// Retorna:
  /// - Stream de ubicaciones
  Stream<List<UbicacionTiempoRealModel>> suscribirseAUbicaciones(
    String sesionId,
  ) {
    return _supabase
        .from('ubicaciones_tiempo_real')
        .stream(primaryKey: ['id'])
        .eq('sesion_id', sesionId)
        .order('ultima_actualizacion', ascending: false)
        .map((data) {
          // Agrupar por usuario y tomar solo la más reciente
          final Map<String, Map<String, dynamic>> ubicacionesPorUsuario = {};

          for (final item in data) {
            final usuarioId = item['usuario_id'] as String;
            if (!ubicacionesPorUsuario.containsKey(usuarioId)) {
              ubicacionesPorUsuario[usuarioId] = item;
            }
          }

          return ubicacionesPorUsuario.values
              .map((json) => UbicacionTiempoRealModel.fromJson(json))
              .toList();
        });
  }

  // ========================================
  // MÉTODOS AUXILIARES
  // ========================================

  /// Genera un código de invitación único
  Future<String> _generarCodigoUnico() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    int intentos = 0;
    const maxIntentos = 10;

    while (intentos < maxIntentos) {
      // Generar código de 6 caracteres
      final codigo = List.generate(
        6,
        (index) => chars[random.nextInt(chars.length)],
      ).join();

      // Verificar si ya existe
      final existe = await _codigoExiste(codigo);
      if (!existe) {
        return codigo;
      }

      intentos++;
    }

    throw Exception('No se pudo generar un código único');
  }

  /// Verifica si un código ya existe
  Future<bool> _codigoExiste(String codigo) async {
    try {
      final response = await _supabase
          .from('grupos_ruta')
          .select('id')
          .eq('codigo_invitacion', codigo);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
