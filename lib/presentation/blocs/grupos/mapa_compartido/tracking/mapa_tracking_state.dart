import 'package:equatable/equatable.dart';
import '../../../../../data/models/ubicacion_tiempo_real_model.dart';

/// Estado de conexión por participante — calculado en el BLoC,
/// leído por la Vista. Fuente única de verdad.
enum EstadoConexion {
  /// Ubicación recibida hace menos de 60 s → verde
  activo,

  /// Sin ubicación entre 60 s y 180 s → amarillo (retraso normal)
  sinActualizacion,

  /// Sin ubicación más de 180 s → gris/rojo (probable corte de red)
  sinConexion,

  /// El usuario pausó manualmente el tracking → naranja
  pausado,
}

class MapaTrackingState extends Equatable {
  final List<UbicacionTiempoRealModel> ubicaciones;
  final Map<String, DateTime> ultimaUbicacionPorUsuario;
  final bool conexionPerdida;
  final bool mostrarMensajeRestablecida;
  final bool trackingActivo;
  final Map<String, EstadoConexion> estadosPorParticipante;

  const MapaTrackingState({
    this.ubicaciones = const [],
    this.ultimaUbicacionPorUsuario = const {},
    this.conexionPerdida = false,
    this.mostrarMensajeRestablecida = false,
    this.trackingActivo = false,
    this.estadosPorParticipante = const {},
  });

  MapaTrackingState copyWith({
    List<UbicacionTiempoRealModel>? ubicaciones,
    Map<String, DateTime>? ultimaUbicacionPorUsuario,
    bool? conexionPerdida,
    bool? mostrarMensajeRestablecida,
    bool? trackingActivo,
    Map<String, EstadoConexion>? estadosPorParticipante,
  }) {
    return MapaTrackingState(
      ubicaciones: ubicaciones ?? this.ubicaciones,
      ultimaUbicacionPorUsuario: ultimaUbicacionPorUsuario ?? this.ultimaUbicacionPorUsuario,
      conexionPerdida: conexionPerdida ?? this.conexionPerdida,
      mostrarMensajeRestablecida: mostrarMensajeRestablecida ?? this.mostrarMensajeRestablecida,
      trackingActivo: trackingActivo ?? this.trackingActivo,
      estadosPorParticipante: estadosPorParticipante ?? this.estadosPorParticipante,
    );
  }

  @override
  List<Object> get props => [
        ubicaciones,
        ultimaUbicacionPorUsuario,
        conexionPerdida,
        mostrarMensajeRestablecida,
        trackingActivo,
        estadosPorParticipante,
      ];
}
