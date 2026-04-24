import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../data/models/participante_sesion_model.dart';
import '../../../../../data/repositories/grupo_repository.dart';
import '../../../../../services/location_tracking_service.dart';
import 'mapa_tracking_event.dart';
import 'mapa_tracking_state.dart';

class MapaTrackingBloc extends Bloc<MapaTrackingEvent, MapaTrackingState> {
  final GrupoRepository _grupoRepository;
  final LocationTrackingService _trackingService;

  StreamSubscription? _ubicacionesSubscription;
  StreamSubscription? _conectadoSubscription;

  /// Participantes sincronizados desde MapaSesionBloc vía event-bridge.
  Map<String, ParticipanteSesionModel> _participantesMap = {};

  /// Timer interno que dispara recálculo periódico de staleness.
  Timer? _recalcTimer;

  late String _sesionId;

  MapaTrackingBloc({
    required GrupoRepository grupoRepository,
    required LocationTrackingService trackingService,
  })  : _grupoRepository = grupoRepository,
        _trackingService = trackingService,
        super(const MapaTrackingState()) {
    on<MapaTrackingIniciar>(_onIniciar);
    on<MapaTrackingUbicacionesActualizadas>(_onUbicacionesActualizadas);
    on<MapaTrackingConexionActualizada>(_onConexionActualizada);
    on<MapaTrackingDismissMensajeConexion>(_onDismissMensajeConexion);
    on<MapaTrackingParticipantesSincronizados>(_onParticipantesSincronizados);
    on<MapaTrackingRecalcularEstados>(_onRecalcularEstados);
  }

  void _onIniciar(
    MapaTrackingIniciar event,
    Emitter<MapaTrackingState> emit,
  ) {
    _sesionId = event.sesionId;

    _ubicacionesSubscription?.cancel();
    _ubicacionesSubscription = _grupoRepository
        .suscribirseAUbicaciones(_sesionId)
        .listen((ubicaciones) {
      add(MapaTrackingUbicacionesActualizadas(ubicaciones));
    });

    _conectadoSubscription?.cancel();
    _conectadoSubscription = _trackingService.conectadoStream.listen((conectado) {
      add(MapaTrackingConexionActualizada(conectado));
    });

    // Timer periódico para recalcular staleness cada 20 s
    _recalcTimer?.cancel();
    _recalcTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      add(MapaTrackingRecalcularEstados());
    });

    emit(state.copyWith(trackingActivo: true));
  }

  void _onUbicacionesActualizadas(
    MapaTrackingUbicacionesActualizadas event,
    Emitter<MapaTrackingState> emit,
  ) {
    final Map<String, DateTime> nuevasUltimas = Map.from(state.ultimaUbicacionPorUsuario);

    // FIX CRÍTICO: Usar el timestamp del SERVIDOR (por fila) en vez de
    // DateTime.now() para todos. Así cada usuario solo avanza su timestamp
    // cuando ESE usuario realmente sube una ubicación.
    for (var u in event.ubicaciones) {
      nuevasUltimas[u.usuarioId] = u.ultimaActualizacion;
    }

    final estados = _calcularEstados(
      timestamps: nuevasUltimas,
      conexionPerdida: state.conexionPerdida,
    );

    emit(state.copyWith(
      ubicaciones: event.ubicaciones,
      ultimaUbicacionPorUsuario: nuevasUltimas,
      estadosPorParticipante: estados,
    ));
  }

  void _onConexionActualizada(
    MapaTrackingConexionActualizada event,
    Emitter<MapaTrackingState> emit,
  ) {
    final nuevaConexionPerdida = !event.conectado;
    final estados = _calcularEstados(
      timestamps: state.ultimaUbicacionPorUsuario,
      conexionPerdida: nuevaConexionPerdida,
    );
    emit(state.copyWith(
      conexionPerdida: nuevaConexionPerdida,
      mostrarMensajeRestablecida: event.conectado ? true : state.mostrarMensajeRestablecida,
      estadosPorParticipante: estados,
    ));
  }

  void _onDismissMensajeConexion(
    MapaTrackingDismissMensajeConexion event,
    Emitter<MapaTrackingState> emit,
  ) {
    emit(state.copyWith(mostrarMensajeRestablecida: false));
  }

  void _onParticipantesSincronizados(
    MapaTrackingParticipantesSincronizados event,
    Emitter<MapaTrackingState> emit,
  ) {
    _participantesMap = event.participantesMap;
    final estados = _calcularEstados(
      timestamps: state.ultimaUbicacionPorUsuario,
      conexionPerdida: state.conexionPerdida,
    );
    emit(state.copyWith(estadosPorParticipante: estados));
  }

  void _onRecalcularEstados(
    MapaTrackingRecalcularEstados event,
    Emitter<MapaTrackingState> emit,
  ) {
    final estados = _calcularEstados(
      timestamps: state.ultimaUbicacionPorUsuario,
      conexionPerdida: state.conexionPerdida,
    );
    // Solo emitir si algo cambió para evitar rebuilds innecesarios
    if (!const DeepCollectionEquality().equals(
      estados,
      state.estadosPorParticipante,
    )) {
      emit(state.copyWith(estadosPorParticipante: estados));
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // Cálculo centralizado de estado de conexión por participante.
  //
  // Prioridad:
  //   1. Pausado (trackingActivo == false)
  //   2. Sin conexión (flag conexionPerdida escrito en BD por el dispositivo)
  //   3. Nuestra propia conexión perdida → retornar activo (stream congelado,
  //      los timestamps serían stale aunque los otros sigan activos)
  //   4. Staleness basado en ultimaActualizacion del servidor:
  //        < 60 s   → activo
  //        60–179 s → sinActualizacion (quieto o retraso de red)
  //        >= 180 s → sinConexion (respaldo temporal: si el dispositivo no
  //                   pudo escribir el flag, el silencio prolongado lo delata)
  // ────────────────────────────────────────────────────────────────────────
  Map<String, EstadoConexion> _calcularEstados({
    required Map<String, DateTime> timestamps,
    required bool conexionPerdida,
  }) {
    final result = <String, EstadoConexion>{};
    for (final entry in _participantesMap.entries) {
      final p = entry.value;

      if (!p.trackingActivo) {
        result[p.usuarioId] = EstadoConexion.pausado;
        continue;
      }
      if (p.conexionPerdida) {
        result[p.usuarioId] = EstadoConexion.sinConexion;
        continue;
      }
      if (conexionPerdida) {
        result[p.usuarioId] = EstadoConexion.activo;
        continue;
      }

      final ultima = timestamps[p.usuarioId];
      if (ultima == null) {
        result[p.usuarioId] = EstadoConexion.activo;
        continue;
      }

      final elapsed = DateTime.now().difference(ultima).inSeconds;
      if (elapsed < 60) {
        result[p.usuarioId] = EstadoConexion.activo;
      } else if (elapsed < 180) {
        result[p.usuarioId] = EstadoConexion.sinActualizacion;
      } else {
        result[p.usuarioId] = EstadoConexion.sinConexion;
      }
    }
    return result;
  }

  @override
  Future<void> close() {
    _ubicacionesSubscription?.cancel();
    _conectadoSubscription?.cancel();
    _recalcTimer?.cancel();
    return super.close();
  }
}
