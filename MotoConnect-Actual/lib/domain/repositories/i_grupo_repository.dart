/// Interface de Repositorio de Grupos de Rutas
///
/// Define el contrato para las operaciones de grupos.
/// Permite testing con mocks y cambio de implementación sin afectar la lógica de negocio.
library;

import '../../data/models/grupo_ruta_model.dart';
import '../../data/models/miembro_grupo_model.dart';
import '../../data/models/sesion_ruta_activa_model.dart';
import '../../data/models/ubicacion_tiempo_real_model.dart';

abstract class IGrupoRepository {
  // ========================================
  // MÉTODOS DE GRUPOS
  // ========================================

  /// Crea un nuevo grupo
  Future<GrupoRutaModel> crearGrupo({
    required String nombre,
    String? descripcion,
  });

  /// Obtiene los grupos del usuario actual
  Future<List<GrupoRutaModel>> obtenerMisGrupos();

  /// Obtiene un grupo por ID
  Future<GrupoRutaModel?> obtenerGrupo(String grupoId);

  /// Busca un grupo por código de invitación
  Future<GrupoRutaModel?> buscarGrupoPorCodigo(String codigo);

  /// Actualiza un grupo
  Future<void> actualizarGrupo({
    required String grupoId,
    String? nombre,
    String? descripcion,
    bool? activo,
  });

  /// Elimina un grupo (solo admins)
  Future<void> eliminarGrupo(String grupoId);

  // ========================================
  // MÉTODOS DE MIEMBROS
  // ========================================

  /// Unirse a un grupo mediante código
  Future<GrupoRutaModel> unirseAGrupo(String codigo);

  /// Obtiene los miembros de un grupo
  Future<List<MiembroGrupoModel>> obtenerMiembrosGrupo(String grupoId);

  /// Verifica si el usuario actual es miembro de un grupo
  Future<bool> esMiembroDeGrupo(String grupoId);

  /// Verifica si el usuario actual es admin de un grupo
  Future<bool> esAdminDeGrupo(String grupoId);

  /// Salir de un grupo
  Future<void> salirDeGrupo(String grupoId);

  /// Eliminar un miembro del grupo (solo admins)
  Future<void> eliminarMiembro(String grupoId, String usuarioId);

  // ========================================
  // MÉTODOS DE SESIONES
  // ========================================

  /// Inicia una nueva sesión de ruta activa
  Future<SesionRutaActivaModel> iniciarSesion({
    required String grupoId,
    required String nombreSesion,
    String? descripcion,
    String? rutaId,
  });

  /// Obtiene las sesiones activas de un grupo
  Future<List<SesionRutaActivaModel>> obtenerSesionesActivas(String grupoId);

  /// Obtiene una sesión por ID
  Future<SesionRutaActivaModel?> obtenerSesion(String sesionId);

  /// Actualiza el estado de una sesión
  Future<void> actualizarEstadoSesion({
    required String sesionId,
    required EstadoSesion estado,
  });

  /// Finaliza una sesión
  Future<void> finalizarSesion(String sesionId);

  // ========================================
  // MÉTODOS DE UBICACIONES EN TIEMPO REAL
  // ========================================

  /// Actualiza la ubicación del usuario en una sesión
  Future<void> actualizarUbicacion({
    required String sesionId,
    required double latitud,
    required double longitud,
    double? velocidad,
    double? direccion,
    double? altitud,
    double? precisionMetros,
  });

  /// Obtiene las ubicaciones actuales de todos los miembros en una sesión
  Future<List<UbicacionTiempoRealModel>> obtenerUbicacionesActuales(
    String sesionId,
  );

  /// Suscribirse a cambios de ubicaciones en tiempo real
  Stream<List<UbicacionTiempoRealModel>> suscribirseAUbicaciones(
    String sesionId,
  );
}
