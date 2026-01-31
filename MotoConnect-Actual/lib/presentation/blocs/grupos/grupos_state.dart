/// Estados del GruposBloc
///
/// Define todos los posibles estados de la gestión de grupos.
library;

import 'package:equatable/equatable.dart';
import '../../../data/models/grupo_ruta_model.dart';
import '../../../data/models/miembro_grupo_model.dart';
import '../../../data/models/sesion_ruta_activa_model.dart';
import '../../../data/models/ubicacion_tiempo_real_model.dart';

/// Clase base abstracta para todos los estados de grupos
abstract class GruposState extends Equatable {
  const GruposState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cargar grupos
class GruposInitial extends GruposState {
  const GruposInitial();
}

/// Estado de carga durante operaciones
class GruposLoading extends GruposState {
  const GruposLoading();
}

/// Estado con grupos cargados exitosamente
class GruposLoaded extends GruposState {
  final List<GrupoRutaModel> grupos;
  final bool isRefreshing;

  const GruposLoaded({required this.grupos, this.isRefreshing = false});

  @override
  List<Object?> get props => [grupos, isRefreshing];

  GruposLoaded copyWith({List<GrupoRutaModel>? grupos, bool? isRefreshing}) {
    return GruposLoaded(
      grupos: grupos ?? this.grupos,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Estado con el detalle de un grupo cargado
class GruposDetailLoaded extends GruposState {
  final List<GrupoRutaModel> grupos;
  final GrupoRutaModel selectedGrupo;
  final List<MiembroGrupoModel> miembros;
  final List<SesionRutaActivaModel> sesionesActivas;
  final bool isAdmin;

  const GruposDetailLoaded({
    required this.grupos,
    required this.selectedGrupo,
    required this.miembros,
    required this.sesionesActivas,
    this.isAdmin = false,
  });

  @override
  List<Object?> get props => [
    grupos,
    selectedGrupo,
    miembros,
    sesionesActivas,
    isAdmin,
  ];

  GruposDetailLoaded copyWith({
    List<GrupoRutaModel>? grupos,
    GrupoRutaModel? selectedGrupo,
    List<MiembroGrupoModel>? miembros,
    List<SesionRutaActivaModel>? sesionesActivas,
    bool? isAdmin,
  }) {
    return GruposDetailLoaded(
      grupos: grupos ?? this.grupos,
      selectedGrupo: selectedGrupo ?? this.selectedGrupo,
      miembros: miembros ?? this.miembros,
      sesionesActivas: sesionesActivas ?? this.sesionesActivas,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

/// Estado para el mapa compartido con ubicaciones en tiempo real
class GruposMapaActivo extends GruposState {
  final List<GrupoRutaModel> grupos;
  final SesionRutaActivaModel sesion;
  final List<UbicacionTiempoRealModel> ubicaciones;

  const GruposMapaActivo({
    required this.grupos,
    required this.sesion,
    required this.ubicaciones,
  });

  @override
  List<Object?> get props => [grupos, sesion, ubicaciones];

  GruposMapaActivo copyWith({
    List<GrupoRutaModel>? grupos,
    SesionRutaActivaModel? sesion,
    List<UbicacionTiempoRealModel>? ubicaciones,
  }) {
    return GruposMapaActivo(
      grupos: grupos ?? this.grupos,
      sesion: sesion ?? this.sesion,
      ubicaciones: ubicaciones ?? this.ubicaciones,
    );
  }
}

/// Estado de operación exitosa
class GruposOperationSuccess extends GruposState {
  final String message;
  final List<GrupoRutaModel> grupos;
  final GrupoRutaModel? createdGrupo;

  const GruposOperationSuccess({
    required this.message,
    required this.grupos,
    this.createdGrupo,
  });

  @override
  List<Object?> get props => [message, grupos, createdGrupo];
}

/// Estado de error en operaciones de grupos
class GruposError extends GruposState {
  final String message;
  final List<GrupoRutaModel>? previousGrupos;

  const GruposError({required this.message, this.previousGrupos});

  @override
  List<Object?> get props => [message, previousGrupos];
}
