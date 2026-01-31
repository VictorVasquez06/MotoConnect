/// GruposBloc - Gestión de estado de grupos de rutas
///
/// Implementa la lógica de negocio para grupos usando BLoC pattern.
/// Depende de IGrupoRepository para abstracción de datos.
/// Soporta ubicaciones en tiempo real mediante streams.
library;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/i_grupo_repository.dart';
import '../../../data/models/grupo_ruta_model.dart';
import '../../../data/models/ubicacion_tiempo_real_model.dart';
import 'grupos_event.dart';
import 'grupos_state.dart';

class GruposBloc extends Bloc<GruposEvent, GruposState> {
  final IGrupoRepository grupoRepository;

  /// Suscripción al stream de ubicaciones en tiempo real
  StreamSubscription<List<UbicacionTiempoRealModel>>? _locationSubscription;

  GruposBloc({required this.grupoRepository}) : super(const GruposInitial()) {
    on<GruposFetchRequested>(_onFetchRequested);
    on<GruposCreateRequested>(_onCreateRequested);
    on<GruposJoinRequested>(_onJoinRequested);
    on<GruposLoadDetail>(_onLoadDetail);
    on<GruposLoadMembers>(_onLoadMembers);
    on<GruposStartSession>(_onStartSession);
    on<GruposUpdateLocation>(_onUpdateLocation);
    on<GruposSubscribeToLocations>(_onSubscribeToLocations);
    on<GruposUnsubscribeFromLocations>(_onUnsubscribeFromLocations);
    on<GruposDeleteRequested>(_onDeleteRequested);
    on<GruposLeaveRequested>(_onLeaveRequested);
    on<GruposRefreshRequested>(_onRefreshRequested);
    on<GruposLocationsUpdated>(_onLocationsUpdated);
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }

  /// Carga la lista de grupos del usuario
  Future<void> _onFetchRequested(
    GruposFetchRequested event,
    Emitter<GruposState> emit,
  ) async {
    emit(const GruposLoading());
    try {
      final grupos = await grupoRepository.obtenerMisGrupos();
      emit(GruposLoaded(grupos: grupos));
    } catch (e) {
      emit(GruposError(message: _parseErrorMessage(e)));
    }
  }

  /// Crea un nuevo grupo
  Future<void> _onCreateRequested(
    GruposCreateRequested event,
    Emitter<GruposState> emit,
  ) async {
    final currentGrupos = _getCurrentGrupos(state);
    emit(const GruposLoading());

    try {
      final nuevoGrupo = await grupoRepository.crearGrupo(
        nombre: event.nombre,
        descripcion: event.descripcion,
      );

      final updatedGrupos = [nuevoGrupo, ...currentGrupos];
      emit(
        GruposOperationSuccess(
          message: 'Grupo "${nuevoGrupo.nombre}" creado exitosamente',
          grupos: updatedGrupos,
          createdGrupo: nuevoGrupo,
        ),
      );
    } catch (e) {
      emit(
        GruposError(
          message: _parseErrorMessage(e),
          previousGrupos: currentGrupos,
        ),
      );
    }
  }

  /// Unirse a un grupo mediante código
  Future<void> _onJoinRequested(
    GruposJoinRequested event,
    Emitter<GruposState> emit,
  ) async {
    final currentGrupos = _getCurrentGrupos(state);
    emit(const GruposLoading());

    try {
      final grupo = await grupoRepository.unirseAGrupo(event.codigo);
      final updatedGrupos = [grupo, ...currentGrupos];
      emit(
        GruposOperationSuccess(
          message: 'Te has unido al grupo "${grupo.nombre}"',
          grupos: updatedGrupos,
          createdGrupo: grupo,
        ),
      );
    } catch (e) {
      emit(
        GruposError(
          message: _parseErrorMessage(e),
          previousGrupos: currentGrupos,
        ),
      );
    }
  }

  /// Carga el detalle de un grupo
  Future<void> _onLoadDetail(
    GruposLoadDetail event,
    Emitter<GruposState> emit,
  ) async {
    final currentGrupos = _getCurrentGrupos(state);
    emit(const GruposLoading());

    try {
      final grupo = await grupoRepository.obtenerGrupo(event.grupoId);
      if (grupo == null) {
        emit(
          GruposError(
            message: 'Grupo no encontrado',
            previousGrupos: currentGrupos,
          ),
        );
        return;
      }

      final miembros = await grupoRepository.obtenerMiembrosGrupo(
        event.grupoId,
      );
      final sesiones = await grupoRepository.obtenerSesionesActivas(
        event.grupoId,
      );
      final isAdmin = await grupoRepository.esAdminDeGrupo(event.grupoId);

      emit(
        GruposDetailLoaded(
          grupos: currentGrupos,
          selectedGrupo: grupo,
          miembros: miembros,
          sesionesActivas: sesiones,
          isAdmin: isAdmin,
        ),
      );
    } catch (e) {
      emit(
        GruposError(
          message: _parseErrorMessage(e),
          previousGrupos: currentGrupos,
        ),
      );
    }
  }

  /// Carga los miembros de un grupo
  Future<void> _onLoadMembers(
    GruposLoadMembers event,
    Emitter<GruposState> emit,
  ) async {
    final currentState = state;
    if (currentState is GruposDetailLoaded) {
      try {
        final miembros = await grupoRepository.obtenerMiembrosGrupo(
          event.grupoId,
        );
        emit(currentState.copyWith(miembros: miembros));
      } catch (e) {
        // Mantener estado actual en caso de error
      }
    }
  }

  /// Inicia una sesión de ruta
  Future<void> _onStartSession(
    GruposStartSession event,
    Emitter<GruposState> emit,
  ) async {
    final currentGrupos = _getCurrentGrupos(state);

    try {
      final sesion = await grupoRepository.iniciarSesion(
        grupoId: event.grupoId,
        nombreSesion: event.nombreSesion,
        descripcion: event.descripcion,
        rutaId: event.rutaId,
      );

      emit(
        GruposOperationSuccess(
          message: 'Sesión "${sesion.nombreSesion}" iniciada',
          grupos: currentGrupos,
        ),
      );

      // Recargar detalle del grupo
      add(GruposLoadDetail(grupoId: event.grupoId));
    } catch (e) {
      emit(
        GruposError(
          message: _parseErrorMessage(e),
          previousGrupos: currentGrupos,
        ),
      );
    }
  }

  /// Actualiza la ubicación del usuario
  Future<void> _onUpdateLocation(
    GruposUpdateLocation event,
    Emitter<GruposState> emit,
  ) async {
    try {
      await grupoRepository.actualizarUbicacion(
        sesionId: event.sesionId,
        latitud: event.latitud,
        longitud: event.longitud,
        velocidad: event.velocidad,
        direccion: event.direccion,
      );
    } catch (e) {
      // Loggear error pero no emitir estado de error
      // para no interrumpir la experiencia del usuario
    }
  }

  /// Suscribirse a ubicaciones en tiempo real
  Future<void> _onSubscribeToLocations(
    GruposSubscribeToLocations event,
    Emitter<GruposState> emit,
  ) async {
    await _locationSubscription?.cancel();

    _locationSubscription = grupoRepository
        .suscribirseAUbicaciones(event.sesionId)
        .listen((ubicaciones) {
          add(GruposLocationsUpdated(ubicaciones: ubicaciones));
        });
  }

  /// Cancelar suscripción de ubicaciones
  Future<void> _onUnsubscribeFromLocations(
    GruposUnsubscribeFromLocations event,
    Emitter<GruposState> emit,
  ) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Manejar actualización de ubicaciones
  void _onLocationsUpdated(
    GruposLocationsUpdated event,
    Emitter<GruposState> emit,
  ) {
    final currentState = state;
    if (currentState is GruposMapaActivo) {
      emit(
        currentState.copyWith(
          ubicaciones: event.ubicaciones.cast<UbicacionTiempoRealModel>(),
        ),
      );
    }
  }

  /// Eliminar un grupo
  Future<void> _onDeleteRequested(
    GruposDeleteRequested event,
    Emitter<GruposState> emit,
  ) async {
    final currentGrupos = _getCurrentGrupos(state);
    emit(const GruposLoading());

    try {
      await grupoRepository.eliminarGrupo(event.grupoId);
      final updatedGrupos =
          currentGrupos.where((g) => g.id != event.grupoId).toList();
      emit(
        GruposOperationSuccess(
          message: 'Grupo eliminado exitosamente',
          grupos: updatedGrupos,
        ),
      );
    } catch (e) {
      emit(
        GruposError(
          message: _parseErrorMessage(e),
          previousGrupos: currentGrupos,
        ),
      );
    }
  }

  /// Salir de un grupo
  Future<void> _onLeaveRequested(
    GruposLeaveRequested event,
    Emitter<GruposState> emit,
  ) async {
    final currentGrupos = _getCurrentGrupos(state);
    emit(const GruposLoading());

    try {
      await grupoRepository.salirDeGrupo(event.grupoId);
      final updatedGrupos =
          currentGrupos.where((g) => g.id != event.grupoId).toList();
      emit(
        GruposOperationSuccess(
          message: 'Has salido del grupo',
          grupos: updatedGrupos,
        ),
      );
    } catch (e) {
      emit(
        GruposError(
          message: _parseErrorMessage(e),
          previousGrupos: currentGrupos,
        ),
      );
    }
  }

  /// Refrescar lista de grupos
  Future<void> _onRefreshRequested(
    GruposRefreshRequested event,
    Emitter<GruposState> emit,
  ) async {
    final currentState = state;
    if (currentState is GruposLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    try {
      final grupos = await grupoRepository.obtenerMisGrupos();
      emit(GruposLoaded(grupos: grupos));
    } catch (e) {
      final previousGrupos =
          currentState is GruposLoaded ? currentState.grupos : null;
      emit(
        GruposError(
          message: _parseErrorMessage(e),
          previousGrupos: previousGrupos,
        ),
      );
    }
  }

  /// Helper para obtener los grupos actuales del estado
  List<GrupoRutaModel> _getCurrentGrupos(GruposState state) {
    if (state is GruposLoaded) return state.grupos;
    if (state is GruposDetailLoaded) return state.grupos;
    if (state is GruposMapaActivo) return state.grupos;
    if (state is GruposOperationSuccess) return state.grupos;
    if (state is GruposError) return state.previousGrupos ?? [];
    return [];
  }

  /// Parsea mensajes de error para mostrar al usuario
  String _parseErrorMessage(dynamic error) {
    final message = error.toString();
    if (message.contains('Network')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (message.contains('not found') ||
        message.contains('no encontrado')) {
      return 'Grupo no encontrado';
    } else if (message.contains('ya eres miembro')) {
      return 'Ya eres miembro de este grupo';
    } else if (message.contains('código inválido')) {
      return 'Código de invitación inválido';
    }
    return 'Error: ${message.length > 100 ? message.substring(0, 100) : message}';
  }
}
