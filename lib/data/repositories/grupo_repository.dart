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

import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grupo_ruta_model.dart';
import '../models/miembro_grupo_model.dart';
import '../models/sesion_ruta_activa_model.dart';
import '../models/ubicacion_tiempo_real_model.dart';
import '../models/participante_sesion_model.dart';

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
    String? fotoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (nombre != null) updates['nombre'] = nombre;
      if (descripcion != null) updates['descripcion'] = descripcion;
      if (activo != null) updates['activo'] = activo;
      if (fotoUrl != null) updates['foto_url'] = fotoUrl;

      if (updates.isEmpty) {
        throw Exception('No se proporcionaron campos para actualizar');
      }

      await _supabase.from('grupos_ruta').update(updates).eq('id', grupoId);

      debugPrint('✅ Grupo actualizado: $updates');
    } catch (e) {
      debugPrint('❌ Error al actualizar grupo: $e');
      throw Exception('Error al actualizar grupo: ${e.toString()}');
    }
  }

  /// Sube una foto de grupo a Supabase Storage
  ///
  /// [grupoId] - ID del grupo
  /// [imagePath] - Ruta local de la imagen
  /// Retorna la URL pública de la imagen
  Future<String> subirFotoGrupo({
    required String grupoId,
    required String imagePath,
  }) async {
    try {
      debugPrint('📤 Subiendo foto de grupo: $grupoId');

      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final extension = path.extension(imagePath);
      final fileName = '${grupoId}_${DateTime.now().millisecondsSinceEpoch}$extension';

      debugPrint('   Archivo: $fileName (${bytes.length} bytes)');

      // Subir a bucket 'grupos'
      await _supabase.storage.from('grupos').uploadBinary(fileName, bytes);

      // Obtener URL pública
      final url = _supabase.storage.from('grupos').getPublicUrl(fileName);

      debugPrint('✅ Foto de grupo subida: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Error al subir foto de grupo: $e');
      throw Exception('Error al subir foto: ${e.toString()}');
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

      // VALIDACIÓN: Verificar si el usuario ya tiene una sesión activa
      final sesionExistente = await obtenerSesionActivaDelUsuario();
      if (sesionExistente != null) {
        throw Exception(
          'Ya tienes una sesión activa: "${sesionExistente.nombreSesion}". '
          'Por favor finalízala antes de crear una nueva.',
        );
      }

      // Crear sesión
      final response = await _supabase.from('sesiones_ruta_activa').insert({
        'grupo_id': grupoId,
        'ruta_id': rutaId,
        'nombre_sesion': nombreSesion,
        'descripcion': descripcion,
        'estado': 'activa',
        'iniciada_por': userId,
      }).select().single();

      final sesion = SesionRutaActivaModel.fromJson(response);

      // IMPORTANTE: Asegurar que el líder esté registrado como participante auto-aprobado
      // Usar upsert para evitar error de clave duplicada si ya existe
      // (puede existir por trigger de base de datos o lógica previa)
      await _supabase.from('participantes_sesion').upsert(
        {
          'sesion_id': sesion.id,
          'usuario_id': userId,
          'estado_aprobacion': 'aprobado',
          'fecha_aprobacion': DateTime.now().toIso8601String(),
          'aprobado_por': userId, // El líder se auto-aprueba
          'tracking_activo': true,
        },
        onConflict: 'sesion_id,usuario_id',
      );

      return sesion;
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

  /// Verifica si el usuario actual tiene sesiones activas como líder
  ///
  /// Retorna:
  /// - SesionRutaActivaModel si tiene una sesión activa, null si no tiene
  Future<SesionRutaActivaModel?> obtenerSesionActivaDelUsuario() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('sesiones_ruta_activa')
          .select()
          .eq('iniciada_por', userId)
          .eq('estado', 'activa')
          .maybeSingle();

      if (response == null) return null;

      return SesionRutaActivaModel.fromJson(response);
    } catch (e) {
      return null;
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

  /// Stream del estado de una sesión en tiempo real
  ///
  /// Emite cada vez que cambia el estado de la sesión (activa → finalizada)
  /// Retorna null si la sesión fue eliminada
  Stream<SesionRutaActivaModel?> streamEstadoSesion(String sesionId) {
    debugPrint('📡 Creando stream de estado para sesión: $sesionId');
    return _supabase
        .from('sesiones_ruta_activa')
        .stream(primaryKey: ['id'])
        .eq('id', sesionId)
        .map((data) {
          if (data.isEmpty) {
            debugPrint('⚠️ Stream de estado: sesión no encontrada o eliminada');
            return null;
          }
          final sesion = SesionRutaActivaModel.fromJson(data.first);
          debugPrint('📡 Stream de estado emitió: ${sesion.estado}');
          return sesion;
        });
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
  // MÉTODOS DE PARTICIPANTES DE SESIÓN
  // ========================================

  /// Solicitar unirse a una sesión
  Future<ParticipanteSesionModel> solicitarUnirseASesion({
    required String sesionId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    // Verificar si ya existe solicitud
    final existente = await _supabase
        .from('participantes_sesion')
        .select()
        .eq('sesion_id', sesionId)
        .eq('usuario_id', userId)
        .maybeSingle();

    if (existente != null) {
      return ParticipanteSesionModel.fromJson(existente);
    }

    // Crear nueva solicitud
    final response = await _supabase
        .from('participantes_sesion')
        .insert({
          'sesion_id': sesionId,
          'usuario_id': userId,
          'estado_aprobacion': 'pendiente',
        })
        .select()
        .single();

    return ParticipanteSesionModel.fromJson(response);
  }

  /// Obtener participantes de una sesión
  Future<List<ParticipanteSesionModel>> obtenerParticipantes(
    String sesionId,
  ) async {
    final response = await _supabase
        .from('vista_participantes_sesion')
        .select()
        .eq('sesion_id', sesionId)
        .order('fecha_solicitud');

    return (response as List)
        .map((json) => ParticipanteSesionModel.fromJson(json))
        .toList();
  }

  /// Obtener solo participantes aprobados
  Future<List<ParticipanteSesionModel>> obtenerParticipantesAprobados(
    String sesionId,
  ) async {
    final response = await _supabase
        .from('vista_participantes_sesion')
        .select()
        .eq('sesion_id', sesionId)
        .eq('estado_aprobacion', 'aprobado')
        .order('fecha_aprobacion');

    return (response as List)
        .map((json) => ParticipanteSesionModel.fromJson(json))
        .toList();
  }

  /// Obtener solicitudes pendientes
  Future<List<ParticipanteSesionModel>> obtenerSolicitudesPendientes(
    String sesionId,
  ) async {
    // Obtener participantes pendientes desde tabla base
    final participantesData = await _supabase
        .from('participantes_sesion')
        .select()
        .eq('sesion_id', sesionId)
        .eq('estado_aprobacion', 'pendiente')
        .order('fecha_solicitud');

    if ((participantesData as List).isEmpty) {
      return [];
    }

    // Obtener IDs únicos de usuarios
    final userIds = participantesData
        .map((p) => p['usuario_id'] as String)
        .toSet()
        .toList();

    // Fetch datos de usuarios en una sola query (batch)
    final usuarios = await _supabase
        .from('usuarios')
        .select('id, nombre, apodo, foto_perfil_url, color_mapa')
        .inFilter('id', userIds);

    debugPrint('🔍 DEBUG Solicitudes Pendientes:');
    debugPrint('   - Participantes pendientes: ${participantesData.length}');
    debugPrint('   - Usuarios obtenidos: ${(usuarios as List).length}');
    debugPrint('   - Datos usuarios: $usuarios');

    // Crear map para lookup O(1)
    final usuariosMap = <String, dynamic>{
      for (final u in usuarios) u['id']: u
    };

    // Combinar datos
    return participantesData.map((p) {
      final usuario = usuariosMap[p['usuario_id']] ?? {};
      debugPrint('   - Usuario ${p['usuario_id']}: nombre=${usuario['nombre']}, apodo=${usuario['apodo']}');
      return ParticipanteSesionModel.fromJson({
        ...p,
        'nombre': usuario['nombre'],
        'apodo': usuario['apodo'],
        'foto_perfil_url': usuario['foto_perfil_url'],
        'color_mapa': usuario['color_mapa'],
      });
    }).toList();
  }

  /// Aprobar participante
  Future<ParticipanteSesionModel> aprobarParticipante({
    required String participanteId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase
        .from('participantes_sesion')
        .update({
          'estado_aprobacion': 'aprobado',
          'fecha_aprobacion': DateTime.now().toIso8601String(),
          'aprobado_por': userId,
        })
        .eq('id', participanteId);

    // Obtener info completa del participante desde la vista
    final participante = await _supabase
        .from('vista_participantes_sesion')
        .select()
        .eq('id', participanteId)
        .single();

    return ParticipanteSesionModel.fromJson(participante);
  }

  /// Rechazar participante
  Future<void> rechazarParticipante({
    required String participanteId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase
        .from('participantes_sesion')
        .update({
          'estado_aprobacion': 'rechazado',
          'aprobado_por': userId,
        })
        .eq('id', participanteId);
  }

  /// Stream de participantes (tiempo real)
  ///
  /// OPTIMIZACIÓN: Escucha la tabla base 'participantes_sesion' en lugar de VIEW
  /// para recibir notificaciones en tiempo real confiables.
  /// Enriquece datos con información de usuarios mediante query adicional.
  Stream<List<ParticipanteSesionModel>> streamParticipantes(
    String sesionId,
  ) {
    return _supabase
        .from('participantes_sesion') // ← Tabla base, NO vista
        .stream(primaryKey: ['id'])
        .eq('sesion_id', sesionId)
        .order('fecha_solicitud')
        .asyncMap((participantesData) async {
      // Manejar lista vacía
      if (participantesData.isEmpty) {
        return <ParticipanteSesionModel>[];
      }

      // Obtener IDs únicos de usuarios para fetch eficiente
      final userIds = (participantesData as List)
          .map((p) => p['usuario_id'] as String)
          .toSet()
          .toList();

      // Fetch datos de usuarios en una sola query (batch)
      final usuarios = await _supabase
          .from('usuarios')
          .select('id, nombre, apodo, foto_perfil_url, color_mapa')
          .inFilter('id', userIds);

      debugPrint('🔍 DEBUG Stream Participantes:');
      debugPrint('   - Participantes en sesión: ${participantesData.length}');
      debugPrint('   - Usuarios obtenidos: ${(usuarios as List).length}');
      if ((usuarios as List).isNotEmpty) {
        debugPrint('   - Primer usuario de ejemplo: ${usuarios[0]}');
      }

      // Crear map para lookup O(1)
      final usuariosMap = <String, dynamic>{
        for (final u in usuarios) u['id']: u
      };

      // Combinar datos de participantes con datos de usuarios
      return participantesData.map((p) {
        final usuario = usuariosMap[p['usuario_id']] ?? {};
        debugPrint('   - Mapeando usuario ${p['usuario_id']}: nombre=${usuario['nombre']}, apodo=${usuario['apodo']}');
        return ParticipanteSesionModel.fromJson({
          ...p,
          'nombre': usuario['nombre'],  // ✅ CORREGIDO: era 'nombre_usuario'
          'apodo': usuario['apodo'],    // ✅ CORREGIDO: era 'apodo_usuario'
          'foto_perfil_url': usuario['foto_perfil_url'],
          'color_mapa': usuario['color_mapa'],
        });
      }).toList();
    });
  }

  /// Verificar si usuario está aprobado en sesión
  Future<bool> estaAprobadoEnSesion({
    required String sesionId,
    String? usuarioId,
  }) async {
    final userId = usuarioId ?? _supabase.auth.currentUser?.id;

    if (userId == null) return false;

    final response = await _supabase
        .from('participantes_sesion')
        .select('estado_aprobacion')
        .eq('sesion_id', sesionId)
        .eq('usuario_id', userId)
        .maybeSingle();

    if (response == null) return false;

    return response['estado_aprobacion'] == 'aprobado';
  }

  /// Verificar si usuario es líder de la sesión
  Future<bool> esLiderDeSesion({
    required String sesionId,
    String? usuarioId,
  }) async {
    final userId = usuarioId ?? _supabase.auth.currentUser?.id;

    if (userId == null) return false;

    final response = await _supabase
        .from('sesiones_ruta_activa')
        .select('iniciada_por')
        .eq('id', sesionId)
        .single();

    return response['iniciada_por'] == userId;
  }

  /// Pausar/reanudar tracking de participante
  Future<void> cambiarEstadoTracking({
    required String sesionId,
    required bool activo,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    await _supabase
        .from('participantes_sesion')
        .update({
          'tracking_activo': activo,
        })
        .eq('sesion_id', sesionId)
        .eq('usuario_id', userId);
  }

  // ========================================
  // MÉTODOS DE RUTAS COMPARTIDAS EN SESIÓN
  // ========================================

  /// Compartir ruta con la sesión (solo líder)
  Future<void> compartirRuta({
    required String sesionId,
    required double destinoLat,
    required double destinoLng,
    String? destinoNombre,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    // Eliminar ruta anterior si existe (solo una ruta activa por sesión)
    await _supabase
        .from('rutas_sesion')
        .delete()
        .eq('sesion_id', sesionId);

    // Insertar nueva ruta
    await _supabase.from('rutas_sesion').insert({
      'sesion_id': sesionId,
      'destino_lat': destinoLat,
      'destino_lng': destinoLng,
      'destino_nombre': destinoNombre,
      'compartida_por': userId,
    });
  }

  /// Obtener ruta compartida de una sesión
  Future<Map<String, dynamic>?> obtenerRutaCompartida(String sesionId) async {
    try {
      final response = await _supabase
          .from('rutas_sesion')
          .select()
          .eq('sesion_id', sesionId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Stream de ruta compartida (tiempo real)
  Stream<Map<String, dynamic>?> streamRutaCompartida(String sesionId) {
    debugPrint('📡 Creando stream de ruta compartida para sesión: $sesionId');

    // IMPORTANTE: No usar .eq() en el stream porque no emite cuando se elimina
    // el último registro. En su lugar, filtramos manualmente después.
    return _supabase
        .from('rutas_sesion')
        .stream(primaryKey: ['id'])
        .map((allData) {
          // Filtrar manualmente las rutas de esta sesión
          final rutasSesion = allData.where((ruta) =>
            ruta['sesion_id'] == sesionId
          ).toList();

          if (rutasSesion.isEmpty) {
            debugPrint('📡 Stream: No hay ruta para sesión $sesionId (emitiendo null)');
            return null;
          }

          debugPrint('📡 Stream: Ruta encontrada para sesión $sesionId');
          return rutasSesion.first as Map<String, dynamic>;
        });
  }

  /// Eliminar ruta compartida
  Future<void> eliminarRutaCompartida(String sesionId) async {
    debugPrint('🗑️ Eliminando ruta compartida de sesión: $sesionId');
    await _supabase
        .from('rutas_sesion')
        .delete()
        .eq('sesion_id', sesionId);
    debugPrint('✅ DELETE ejecutado en rutas_sesion');
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
