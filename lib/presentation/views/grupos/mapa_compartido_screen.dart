import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/sesion_ruta_activa_model.dart';
import '../../../data/models/grupo_ruta_model.dart';
import '../../../data/models/ubicacion_tiempo_real_model.dart';
import '../../../data/models/navigation_progress.dart';
import '../../../data/models/participante_sesion_model.dart';
import '../../../data/models/navigation_step.dart';
import '../../../data/repositories/grupo_repository.dart';
import '../../../data/repositories/navigation_repository.dart';
import '../../../data/services/navigation/google_directions_service.dart';
import '../../../services/location_tracking_service.dart';
import '../../../services/marker_state_manager.dart';
import '../../../services/navigation_voice_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../utils/map_colors.dart';
import '../../widgets/grupos/solicitudes_pendientes_dialog.dart';
import '../../widgets/location_search_field.dart';
import 'package:geolocator/geolocator.dart';

/// Pantalla de mapa compartido con ubicaciones en tiempo real
///
/// Muestra la ubicación de todos los miembros del grupo en un mapa
class MapaCompartidoScreen extends StatefulWidget {
  final SesionRutaActivaModel sesion;
  final GrupoRutaModel grupo;

  const MapaCompartidoScreen({
    super.key,
    required this.sesion,
    required this.grupo,
  });

  @override
  State<MapaCompartidoScreen> createState() => _MapaCompartidoScreenState();
}

class _MapaCompartidoScreenState extends State<MapaCompartidoScreen> {
  GoogleMapController? _mapController;
  final GrupoRepository _grupoRepository = GrupoRepository();
  final NavigationRepository _navigationRepository = NavigationRepository();
  final LocationTrackingService _trackingService = LocationTrackingService();
  late final GoogleDirectionsService _directionsService;

  Map<String, Marker> _markers = {};
  Map<String, NavigationProgress> _navigationProgress = {};

  // Gestor de estados de marcadores con retry y cache TTL
  late final MarkerStateManager _markerManager;

  // Map de participantes para lookup O(1) eficiente
  Map<String, ParticipanteSesionModel> _participantesMap = {};

  StreamSubscription? _ubicacionesSubscription;
  StreamSubscription? _navigationProgressSubscription;
  StreamSubscription? _participantesSubscription;
  StreamSubscription? _rutaCompartidaSubscription;
  StreamSubscription? _estadoSesionSubscription;
  bool _trackingActivo = false;
  String? _miUsuarioId;

  // Ruta compartida
  Map<String, dynamic>? _rutaCompartida;
  Polyline? _polylineCompartida;
  List<NavigationStep>? _navigationSteps; // Steps de navegación por voz
  int? _currentStepIndex; // Índice del paso actual
  StreamSubscription<Position>? _navigationLocationSubscription; // Para tracking durante navegación
  late final NavigationVoiceService _voiceService; // Servicio de voz

  // Nuevos campos para sistema de aprobación
  List<ParticipanteSesionModel> _participantes = [];
  bool _esLider = false;
  bool _estaAprobado = false;
  bool _trackingPausadoPorUsuario = false;
  bool _esAdminGrupo = false;
  bool _isInitializing = true;
  String _initializingMessage = 'Inicializando sesión...';
  double _initializingProgress = 0.0;

  // Cache para resolver race conditions
  List<ParticipanteSesionModel> _participantesCache = [];
  bool _participantesReady = false;
  List<UbicacionTiempoRealModel> _ubicacionesCache = [];
  bool _ubicacionesReady = false;

  @override
  void initState() {
    super.initState();

    // Inicializar gestor de marcadores
    _markerManager = MarkerStateManager();

    // OPTIMIZACIÓN: Setear _esLider y _estaAprobado INMEDIATAMENTE
    // usando datos locales para evitar flash de pantalla de espera
    final supabase = Supabase.instance.client;
    _miUsuarioId = supabase.auth.currentUser?.id;
    _esLider = widget.sesion.iniciadaPor == _miUsuarioId;

    // Si es líder, está auto-aprobado
    if (_esLider) {
      _estaAprobado = true;
    }

    _directionsService = GoogleDirectionsService(
      apiKey: ApiConstants.googleMapsApiKey,
    );

    // Inicializar servicio de voz para navegación
    _voiceService = NavigationVoiceService();

    // Esperar a que el primer frame se renderice antes de inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializar();
    });
  }

  @override
  void dispose() {
    _ubicacionesSubscription?.cancel();
    _navigationProgressSubscription?.cancel();
    _participantesSubscription?.cancel();
    _rutaCompartidaSubscription?.cancel();
    _estadoSesionSubscription?.cancel();
    _navigationLocationSubscription?.cancel(); // Cancelar tracking de navegación
    if (_trackingActivo) {
      _trackingService.detenerTracking();
    }
    _trackingService.dispose();
    _mapController?.dispose();
    _markerManager.dispose();
    _voiceService.dispose(); // Limpiar servicio de voz
    super.dispose();
  }

  /// Inicialización SECUENCIAL para evitar race conditions
  ///
  /// Orden crítico:
  /// 1. Verificar permisos
  /// 2. Cargar participantes (con await)
  /// 3. Pre-generar marcadores (con await)
  /// 4. Suscribirse a streams
  /// 5. Iniciar tracking si está aprobado
  Future<void> _inicializar() async {
    try {
      // 1. Verificar permisos (20%)
      if (mounted) {
        setState(() {
          _initializingMessage = 'Verificando permisos...';
          _initializingProgress = 0.2;
        });
      }
      await _verificarPermisos();

      // 2. CRÍTICO: Cargar participantes PRIMERO (40%)
      if (mounted) {
        setState(() {
          _initializingMessage = 'Cargando participantes...';
          _initializingProgress = 0.4;
        });
      }
      await _cargarParticipantesInicial();

      // 3. Pre-generar marcadores con AWAIT (70%)
      // OPTIMIZACIÓN: Solo en modo release para evitar bloqueo del hilo principal
      if (!kDebugMode) {
        if (mounted) {
          setState(() {
            _initializingMessage =
                'Preparando marcadores (${_participantesCache.length} participantes)...';
            _initializingProgress = 0.7;
          });
        }
        await _preGenerarMarcadores(_participantesCache);
        debugPrint('✅ Pre-generación de marcadores completa (modo release)');
      } else {
        debugPrint('⚡ Pre-generación omitida en modo debug para mejor performance');
        debugPrint('   Los marcadores se generarán bajo demanda cuando se actualicen ubicaciones');
      }

      // 4. Suscribirse a streams (90%)
      if (mounted) {
        setState(() {
          _initializingMessage = 'Conectando en tiempo real...';
          _initializingProgress = 0.9;
        });
      }
      _suscribirseAParticipantes();
      _suscribirseAUbicaciones();
      _suscribirseAProgresoNavegacion();
      _suscribirseARutaCompartida();
      _suscribirseAEstadoSesion();

      // 5. Timer para limpieza periódica de cache y diagnóstico
      Timer.periodic(const Duration(hours: 1), (_) {
        if (mounted) {
          final removed = _markerManager.evictStale();
          if (removed > 0) {
            debugPrint('🧹 Limpieza periódica: $removed marcadores removidos');
          }

          // Diagnóstico detallado cada hora
          _markerManager.printDiagnostics();
        }
      });

      // 6. Marcar como inicializado
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }

      // 7. Iniciar tracking si está aprobado
      if (_estaAprobado) {
        _iniciarTracking().catchError((e) {
          debugPrint('Error al iniciar tracking: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al iniciar ubicación: ${e.toString()}'),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'Reintentar',
                  onPressed: () => _iniciarTracking(),
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error en inicialización: $e');

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _suscribirseAProgresoNavegacion() {
    _navigationProgressSubscription = _navigationRepository
        .streamGroupNavigationProgress(widget.sesion.id)
        .listen((progresos) {
      final progressMap = <String, NavigationProgress>{};
      for (final progreso in progresos) {
        progressMap[progreso.userId] = progreso;
      }

      setState(() {
        _navigationProgress = progressMap;
      });
    });
  }

  void _suscribirseAUbicaciones() {
    _ubicacionesSubscription = _grupoRepository
        .suscribirseAUbicaciones(widget.sesion.id)
        .listen((ubicaciones) async {
      // Cachear ubicaciones
      _ubicacionesCache = ubicaciones;
      _ubicacionesReady = true;

      // Solo actualizar si participantes están listos
      // Esto evita la race condition donde ubicaciones llegan primero
      if (_participantesReady) {
        try {
          await _actualizarMarcadores(ubicaciones);
        } catch (e) {
          debugPrint('❌ Error al actualizar marcadores: $e');
        }
      } else {
        debugPrint('⏳ Ubicaciones recibidas pero participantes no listos, esperando...');
      }
    });
  }

  void _suscribirseARutaCompartida() {
    debugPrint('📡 Suscribiendo a stream de ruta compartida para sesión: ${widget.sesion.id}');

    _rutaCompartidaSubscription = _grupoRepository
        .streamRutaCompartida(widget.sesion.id)
        .listen(
      (ruta) async {
        debugPrint('📡 Stream de ruta compartida emitió: ${ruta != null ? "nueva ruta" : "null (cancelada)"}');

        if (ruta != null) {
          debugPrint('   📍 Destino: ${ruta['destino_nombre'] ?? 'Sin nombre'}');
          debugPrint('   📍 Lat: ${ruta['destino_lat']}, Lng: ${ruta['destino_lng']}');
        }

        setState(() {
          _rutaCompartida = ruta;
        });

        // Si hay ruta compartida, calcular polyline desde mi ubicación (con retry)
        if (ruta != null && _estaAprobado) {
          debugPrint('🗺️ Calculando polyline hacia destino con retry...');
          await _calcularPolylineHaciaDestinoConRetry(
            ruta['destino_lat'] as double,
            ruta['destino_lng'] as double,
          );
        } else {
          // Limpiar ruta cuando se cancela
          debugPrint('🧹 Limpiando polyline (stream emitió null)');

          // Detener navegación por voz si estaba activa
          if (_navigationSteps != null) {
            _detenerNavegacionPorVoz();
          }

          if (mounted) {
            setState(() {
              _polylineCompartida = null;
              if (_markers.containsKey('destino_compartido')) {
                _markers.remove('destino_compartido');
                debugPrint('✅ Marcador de destino removido');
              }
            });
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Error en stream de ruta compartida: $error');
      },
      onDone: () {
        debugPrint('✅ Stream de ruta compartida completado');
      },
    );
  }

  void _suscribirseAEstadoSesion() {
    // Optimización: Solo el líder de la sesión no necesita escucharse a sí mismo
    // El admin del grupo SÍ necesita ver el dialog cuando él finaliza la sesión de otro
    if (_esLider) {
      debugPrint('👑 Líder de sesión: No suscribirse a estado de sesión (es quien finaliza)');
      return;
    }

    debugPrint('📡 Suscribiendo a stream de estado de sesión: ${widget.sesion.id}');

    _estadoSesionSubscription = _grupoRepository
        .streamEstadoSesion(widget.sesion.id)
        .listen(
      (sesion) {
        if (sesion == null) {
          debugPrint('⚠️ Sesión eliminada de la base de datos');
          return;
        }

        debugPrint('🔔 Estado de sesión: ${sesion.estado}');

        if (sesion.estado == EstadoSesion.finalizada) {
          debugPrint('🛑 Sesión finalizada por el líder');

          // Detener tracking local
          if (_trackingActivo) {
            _trackingService.detenerTracking();
            _trackingActivo = false;
          }

          // Mostrar dialog
          if (mounted) {
            _mostrarDialogSesionFinalizada();
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Error en stream de estado de sesión: $error');
      },
    );
  }

  Future<void> _verificarPermisos() async {
    // Nota: _esLider ya fue seteado en initState() usando datos locales
    // Esto es más rápido y evita timing issues con la base de datos

    // Ejecutar las 2 queries restantes EN PARALELO
    final results = await Future.wait([
      _grupoRepository.esAdminDeGrupo(widget.grupo.id),
      // Si es líder, ya está auto-aprobado. Si no, verificar en BD
      _esLider
          ? Future.value(true)
          : _grupoRepository.estaAprobadoEnSesion(sesionId: widget.sesion.id),
    ]);

    _esAdminGrupo = results[0];
    _estaAprobado = results[1];

    setState(() {});

    // Si no está aprobado y no es líder, solicitar unirse
    if (!_estaAprobado && !_esLider) {
      // Ejecutar en segundo plano sin bloquear
      _solicitarUnirse().catchError((e) {
        debugPrint('Error al solicitar unirse: $e');
      });
    }
  }

  Future<void> _solicitarUnirse() async {
    try {
      await _grupoRepository.solicitarUnirseASesion(
        sesionId: widget.sesion.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solicitud enviada. Esperando aprobación del líder...',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al solicitar unirse: $e');
    }
  }

  /// Carga participantes iniciales de forma síncrona
  ///
  /// CRÍTICO: Este método se ejecuta ANTES de suscribirse a streams
  /// para evitar race condition donde ubicaciones llegan antes que participantes.
  Future<void> _cargarParticipantesInicial() async {
    debugPrint('📥 Cargando participantes iniciales...');

    try {
      final participantes = await _grupoRepository.obtenerParticipantes(
        widget.sesion.id,
      );

      if (mounted) {
        setState(() {
          _participantesCache = participantes;
          _participantes = participantes;
          _participantesMap = {
            for (final p in participantes) p.usuarioId: p
          };
          _participantesReady = true;
        });
      }

      debugPrint('✅ ${participantes.length} participantes cargados');
    } catch (e) {
      debugPrint('❌ Error al cargar participantes iniciales: $e');
      // No lanzar error, continuar con lista vacía
      // El stream actualizará cuando se conecte
      if (mounted) {
        setState(() {
          _participantesReady = true; // Marcar como listo aunque esté vacío
        });
      }
    }
  }

  void _suscribirseAParticipantes() {
    debugPrint('📡 Suscribiendo a stream de participantes para sesión: ${widget.sesion.id}');

    _participantesSubscription = _grupoRepository
        .streamParticipantes(widget.sesion.id)
        .listen(
      (participantes) async {
      debugPrint('🔔 Stream de participantes emitió: ${participantes.length} participantes');

      // Contar solicitudes pendientes
      final pendientes = participantes.where((p) => p.estaPendiente).length;
      final aprobados = participantes.where((p) => p.estaAprobado).length;
      debugPrint('   📋 Pendientes: $pendientes, Aprobados: $aprobados');

      // Detectar cambios de foto y invalidar cache
      for (final participante in participantes) {
        final cached = _participantesMap[participante.usuarioId];

        // Si URL de foto cambió, invalidar cache de ese usuario
        if (cached != null &&
            cached.fotoPerfilUrl != participante.fotoPerfilUrl) {
          debugPrint(
              '🔄 Foto cambiada para ${participante.nombreMostrar}: ${cached.fotoPerfilUrl} → ${participante.fotoPerfilUrl}');
          _markerManager.invalidateUser(participante.usuarioId);
        }

        // Detectar cambios de tracking
        if (cached != null &&
            cached.trackingActivo != participante.trackingActivo) {
          debugPrint(
              '⏸️ Tracking cambiado para ${participante.nombreMostrar}: ${cached.trackingActivo} → ${participante.trackingActivo}');
        }
      }

      setState(() {
        _participantes = participantes;
        _participantesCache = participantes;
        // OPTIMIZACIÓN: Crear map para lookup O(1) en _actualizarMarcadores
        _participantesMap = {
          for (final p in participantes) p.usuarioId: p
        };
      });

      // PRE-GENERAR MARCADORES: Cargar fotos y crear marcadores inmediatamente
      // Esto asegura que las fotos estén en cache antes de que lleguen ubicaciones
      // Nota: No usar await aquí para no bloquear el stream
      _preGenerarMarcadores(participantes);

      // Buscar mi participante en esta sesión específica
      // IMPORTANTE: No usar orElse que retorna otro participante
      // Si el usuario no está en la lista, significa que no ha solicitado unirse
      ParticipanteSesionModel? miParticipante;
      try {
        miParticipante = participantes.firstWhere(
          (p) => p.usuarioId == _miUsuarioId,
        );
      } catch (e) {
        // Usuario no está en lista de participantes de esta sesión
        miParticipante = null;
      }

      // Solo procesar si el usuario ESTÁ en la lista de participantes
      if (miParticipante != null) {
        // Capturar en variable local para evitar problema de null-safety en async
        final participante = miParticipante;

        // Actualizar estado de pausa
        if (_trackingPausadoPorUsuario != !participante.trackingActivo) {
          setState(() {
            _trackingPausadoPorUsuario = !participante.trackingActivo;
          });
        }

        // Si era no aprobado y ahora está aprobado, iniciar tracking
        if (!_estaAprobado && participante.estaAprobado) {
          _estaAprobado = true;
          _iniciarTracking();

          // Solo mostrar mensaje de aprobación si NO es el líder
          // El líder no necesita "ser aprobado", él crea la sesión
          if (mounted && !_esLider) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Has sido aprobado! Compartiendo ubicación...'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }

      // Si hay ubicaciones en cache esperando, actualizarlas ahora
      // Esto maneja el caso donde ubicaciones llegaron mientras participantes cargaban
      if (_ubicacionesCache.isNotEmpty && _ubicacionesReady) {
        debugPrint('🔄 Actualizando marcadores con ubicaciones en cache...');
        await _actualizarMarcadores(_ubicacionesCache);
      }
    },
      onError: (error) {
        debugPrint('❌ Error en stream de participantes: $error');
      },
      onDone: () {
        debugPrint('✅ Stream de participantes completado');
      },
    );
  }

  Future<void> _iniciarTracking() async {
    try {
      // Verificar y solicitar permisos (sin obtener ubicación)
      if (!await _trackingService.tienePermisos()) {
        // Mostrar mensaje de que se están solicitando permisos
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor acepta los permisos de ubicación'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        await _trackingService.solicitarPermisos();
      }

      // Iniciar tracking (esto obtendrá ubicación en background)
      await _trackingService.iniciarTracking(
        sesionId: widget.sesion.id,
        config: TrackingConfig.estandar,
      );

      if (mounted) {
        setState(() {
          _trackingActivo = true;
        });

        // OPTIMIZACIÓN: Usar última ubicación conocida para centrar INMEDIATAMENTE
        // En lugar de esperar 10-30s por GPS frío
        final ultimaUbicacion = await _trackingService.obtenerUltimaUbicacionConocida();
        if (ultimaUbicacion != null) {
          _centrarMapa(LatLng(ultimaUbicacion.latitude, ultimaUbicacion.longitude));
        }
        // Si no hay última ubicación, el stream actualizará cuando haya nueva posición
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar tracking: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Actualiza los marcadores en el mapa con fotos de perfil personalizadas
  ///
  /// OPTIMIZACIÓN: Usa cache para evitar regenerar marcadores en cada update.
  /// Usa _participantesMap para lookup O(1) en lugar de firstWhere O(n).
  /// MERGE PATTERN: Preserva marcadores adicionales (destino, etc.)
  Future<void> _actualizarMarcadores(
    List<UbicacionTiempoRealModel> ubicaciones,
  ) async {
    debugPrint('🗺️ Actualizando ${ubicaciones.length} marcadores...');

    // SAFEGUARD: Si participantes no están listos, esperar
    if (!_participantesReady && ubicaciones.isNotEmpty) {
      debugPrint('⚠️ Participantes aún no listos, esperando...');
      return;
    }

    final nuevosMarkers = <String, Marker>{};

    for (final ubicacion in ubicaciones) {
      final markerId = MarkerId(ubicacion.usuarioId);

      // OPTIMIZACIÓN: Lookup O(1) en lugar de firstWhere O(n)
      final participante = _participantesMap[ubicacion.usuarioId];

      // Si no hay participante, saltar (no debería pasar normalmente)
      if (participante == null) {
        debugPrint('⚠️ Participante no encontrado para ${ubicacion.usuarioId}');
        continue;
      }

      final estaPausado = !participante.trackingActivo;

      // Obtener o crear marcador con retry automático
      final icon = await _markerManager.getOrCreateMarker(
        userId: ubicacion.usuarioId,
        photoUrl: participante.fotoPerfilUrl,
        displayName: participante.nombreMostrar,
        colorMap: participante.colorMapa ?? 0,
        isPaused: estaPausado,
      );

      // Obtener progreso de navegación si existe
      final progreso = _navigationProgress[ubicacion.usuarioId];

      final marker = Marker(
        markerId: markerId,
        position: ubicacion.posicion,
        icon: icon,
        infoWindow: InfoWindow(
          title: participante.nombreMostrar +
              (estaPausado ? ' (Pausado)' : ''),
          snippet: _buildSnippet(ubicacion, progreso),
        ),
        rotation: ubicacion.direccion ?? 0,
      );

      nuevosMarkers[ubicacion.usuarioId] = marker;
      debugPrint('📍 Marcador agregado al mapa: ${participante.nombreMostrar} en ${ubicacion.posicion}');
    }

    debugPrint('✅ ${nuevosMarkers.length} marcadores creados, actualizando mapa...');

    // MERGE PATTERN: Preservar marcadores adicionales (destino, etc.)
    if (mounted) {
      setState(() {
        // Optimización: Crear set de IDs de ubicación para lookup O(1)
        final ubicacionIds = ubicaciones.map((u) => u.usuarioId).toSet();

        // Preservar solo marcadores que NO son de ubicaciones de participantes
        // (como destino_compartido, waypoints, etc.)
        final marcadoresNoUbicacion = <String, Marker>{};
        for (final entry in _markers.entries) {
          if (!ubicacionIds.contains(entry.key)) {
            marcadoresNoUbicacion[entry.key] = entry.value;
          }
        }

        _markers = {
          // 1. Marcadores existentes que NO son de ubicación
          ...marcadoresNoUbicacion,

          // 2. Nuevos marcadores de ubicación (sobrescriben si existen)
          ...nuevosMarkers,
        };
      });
    }
  }

  /// Pre-genera marcadores para todos los participantes
  ///
  /// Esto carga las fotos de perfil y crea los marcadores inmediatamente
  /// cuando se cargan los participantes, asegurando que estén en cache
  /// antes de que lleguen las ubicaciones.
  ///
  /// Usa límite de concurrencia para no saturar la red.
  Future<void> _preGenerarMarcadores(
    List<ParticipanteSesionModel> participantes,
  ) async {
    debugPrint('🎨 Pre-generando marcadores para ${participantes.length} participantes...');

    // Paralelizar generación con límite de concurrencia
    const maxConcurrent = 5;

    for (var i = 0; i < participantes.length; i += maxConcurrent) {
      final batch = participantes.skip(i).take(maxConcurrent);
      final futures = <Future>[];

      for (final participante in batch) {
        // Generar versión activa y pausada
        for (final estaPausado in [false, true]) {
          futures.add(
            _markerManager
                .getOrCreateMarker(
              userId: participante.usuarioId,
              photoUrl: participante.fotoPerfilUrl,
              displayName: participante.nombreMostrar,
              colorMap: participante.colorMapa ?? 0,
              isPaused: estaPausado,
            )
                .catchError((e) {
              debugPrint(
                  '❌ Error pre-generando marcador: ${participante.nombreMostrar} - $e');
              // Retornar fallback marker
              return BitmapDescriptor.defaultMarkerWithHue(
                MapColors.hues[(participante.colorMapa ?? 0) %
                    MapColors.hues.length],
              );
            }),
          );
        }
      }

      // AWAIT batch antes de continuar
      await Future.wait(futures);
    }

    final stats = _markerManager.getStats();
    debugPrint('✅ Pre-generación completa. Stats: $stats');
  }

  String _buildSnippet(
    UbicacionTiempoRealModel ubicacion,
    NavigationProgress? progreso,
  ) {
    final parts = <String>[];

    if (ubicacion.velocidad != null && ubicacion.velocidad! > 0) {
      parts.add('${ubicacion.velocidad!.toStringAsFixed(1)} km/h');
    }

    // Agregar info de navegación si está navegando
    if (progreso != null) {
      parts.add('Paso ${progreso.currentStepIndex + 1}');
      if (progreso.etaSeconds != null) {
        parts.add('ETA: ${progreso.etaText}');
      }
    }

    parts.add(ubicacion.tiempoTranscurrido);

    return parts.join(' • ');
  }

  void _centrarMapa(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.sesion.nombreSesion),
            Text(
              widget.grupo.nombre,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (_trackingActivo)
            const Icon(Icons.circle, color: Colors.green, size: 12),
          // Botón de solicitudes pendientes (solo líder)
          if (_esLider)
            _buildBotonSolicitudes(),
          // Botón de iniciar ruta (solo líder, solo si no hay ruta activa)
          if (_esLider && _rutaCompartida == null)
            IconButton(
              icon: const Icon(Icons.route),
              onPressed: _mostrarIniciarRuta,
              tooltip: 'Iniciar ruta',
            ),
          // Botón de cancelar ruta (solo líder, solo si hay ruta activa)
          if (_esLider && _rutaCompartida != null)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              onPressed: _confirmarCancelarRuta,
              tooltip: 'Cancelar ruta',
            ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pausar_ubicacion',
                child: Row(
                  children: [
                    Icon(_trackingPausadoPorUsuario ? Icons.play_arrow : Icons.pause_circle_outline),
                    const SizedBox(width: 8),
                    Text(_trackingPausadoPorUsuario ? 'Reanudar ubicación' : 'Pausar ubicación'),
                  ],
                ),
              ),
              // Opción de finalizar solo para líder o admin
              if (_esLider || _esAdminGrupo)
                const PopupMenuItem(
                  value: 'finalizar',
                  child: Row(
                    children: [
                      Icon(Icons.stop, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Finalizar sesión', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // OPTIMIZACIÓN: Siempre mostrar GoogleMap (no ternario que causa flash)
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 15,
            ),
            markers: Set<Marker>.of(_markers.values),
            polylines: _polylineCompartida != null
                ? {_polylineCompartida!}
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          // Overlay de carga durante inicialización
          if (_isInitializing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _initializingProgress,
                        strokeWidth: 6,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.teal),
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _initializingMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_initializingProgress * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Overlay de espera de aprobación (solo para participantes NO aprobados)
          if (!_estaAprobado && !_esLider && !_isInitializing)
            _buildPantallaEspera(),
        ],
      ),
      floatingActionButton: (_estaAprobado || _esLider)
          ? _buildBotonParticipantes()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _onMenuSelected(String value) async {
    switch (value) {
      case 'pausar_ubicacion':
        await _togglePausarUbicacion();
        break;

      case 'finalizar':
        await _finalizarSesion();
        break;
    }
  }

  Future<void> _togglePausarUbicacion() async {
    try {
      final nuevoEstado = !_trackingPausadoPorUsuario;

      // Actualizar en base de datos
      await _grupoRepository.cambiarEstadoTracking(
        sesionId: widget.sesion.id,
        activo: !nuevoEstado,
      );

      // Pausar o reanudar tracking local
      if (nuevoEstado) {
        _trackingService.pausarTracking();
      } else {
        _trackingService.reanudarTracking();
      }

      setState(() {
        _trackingPausadoPorUsuario = nuevoEstado;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoEstado
                  ? 'Ubicación pausada. Otros no verán tu posición.'
                  : 'Ubicación reanudada. Compartiendo posición...',
            ),
            backgroundColor: nuevoEstado ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _finalizarSesion() async {
    // Validar permisos: solo líder o admin del grupo pueden finalizar
    if (!_esLider && !_esAdminGrupo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solo el líder de la sesión o administradores del grupo pueden finalizar la sesión.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Sesión'),
        content: const Text(
          '¿Estás seguro de que deseas finalizar esta sesión? '
          'Esto detendrá el tracking para todos los participantes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );

    if (confirmacion == true && mounted) {
      try {
        await _grupoRepository.finalizarSesion(widget.sesion.id);
        await _trackingService.detenerTracking();

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al finalizar sesión: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildBotonSolicitudes() {
    final pendientes = _participantes
        .where((p) => p.estaPendiente)
        .length;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.person_add),
          onPressed: _mostrarSolicitudesPendientes,
        ),
        if (pendientes > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$pendientes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _mostrarSolicitudesPendientes() {
    // Validar que solo el líder puede aprobar/rechazar
    if (!_esLider) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo el líder de la sesión puede aprobar participantes.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final pendientes = _participantes
        .where((p) => p.estaPendiente)
        .toList();

    showDialog(
      context: context,
      builder: (context) => SolicitudesPendientesDialog(
        solicitudes: pendientes,
        onAprobar: (participanteId) async {
          // Doble validación por seguridad
          if (!_esLider) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Solo el líder puede aprobar participantes.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          try {
            await _grupoRepository.aprobarParticipante(
              participanteId: participanteId,
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al aprobar: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onRechazar: (participanteId) async {
          // Doble validación por seguridad
          if (!_esLider) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Solo el líder puede rechazar participantes.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          try {
            await _grupoRepository.rechazarParticipante(
              participanteId: participanteId,
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al rechazar: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildPantallaEspera() {
    // Obtener todos los participantes pendientes (incluyendo el usuario actual)
    final participantesPendientes = _participantes
        .where((p) => p.estaPendiente)
        .toList();

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 32,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sala de Espera',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Esperando aprobación del líder',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mensaje informativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tu solicitud ha sido enviada. El líder recibirá una notificación para aprobarte.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Título de lista
              Row(
                children: [
                  Text(
                    'Personas en espera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${participantesPendientes.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lista de participantes pendientes
              Expanded(
                child: participantesPendientes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Cargando participantes...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: participantesPendientes.length,
                        itemBuilder: (context, index) {
                          final participante = participantesPendientes[index];
                          final esTu = participante.usuarioId == _miUsuarioId;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: esTu
                                  ? BorderSide(
                                      color: Colors.teal,
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.teal,
                                    backgroundImage:
                                        participante.fotoPerfilUrl != null
                                            ? NetworkImage(
                                                participante.fotoPerfilUrl!)
                                            : null,
                                    child: participante.fotoPerfilUrl == null
                                        ? Text(
                                            participante.nombreMostrar[0]
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          )
                                        : null,
                                  ),
                                  // Indicador de "tú"
                                  if (esTu)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      participante.nombreMostrar,
                                      style: TextStyle(
                                        fontWeight: esTu
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (esTu)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.teal,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Tú',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                _formatFechaSolicitud(
                                    participante.fechaSolicitud),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    esTu ? Colors.teal : Colors.orange,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Botón de salir
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Salir de la sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFechaSolicitud(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    } else {
      return 'Hace ${diferencia.inDays} días';
    }
  }

  // ========================================
  // BOTÓN Y PANEL DE PARTICIPANTES
  // ========================================

  Widget _buildBotonParticipantes() {
    final participantesAprobados = _participantes
        .where((p) => p.estaAprobado)
        .length;

    return FloatingActionButton.extended(
      onPressed: _mostrarPanelParticipantes,
      icon: const Icon(Icons.people),
      label: Text('$participantesAprobados'),
      backgroundColor: Colors.teal,
    );
  }

  void _mostrarPanelParticipantes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle del drag
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Título
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Participantes (${_participantes.where((p) => p.estaAprobado).length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Lista de participantes
                Expanded(
                  child: _buildListaParticipantes(scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListaParticipantes(ScrollController scrollController) {
    final participantesAprobados = _participantes
        .where((p) => p.estaAprobado)
        .toList();

    if (participantesAprobados.isEmpty) {
      return const Center(
        child: Text('No hay participantes aprobados'),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: participantesAprobados.length,
      itemBuilder: (context, index) {
        final participante = participantesAprobados[index];
        return _buildParticipanteItem(participante);
      },
    );
  }

  Widget _buildParticipanteItem(ParticipanteSesionModel participante) {
    final esMiUsuario = participante.usuarioId == _miUsuarioId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          backgroundImage: participante.fotoPerfilUrl != null
              ? NetworkImage(participante.fotoPerfilUrl!)
              : null,
          child: participante.fotoPerfilUrl == null
              ? Text(
                  participante.nombreMostrar[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: _MarqueeText(
                text: participante.nombreMostrar,
                style: TextStyle(
                  fontWeight: esMiUsuario ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (esMiUsuario) ...[
              const SizedBox(width: 4),
              const Text(
                '(Tú)',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            // Estado de tracking
            if (!participante.trackingActivo) ...[
              const Icon(
                Icons.pause_circle_outline,
                size: 14,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              const Text(
                'Pausado',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.circle,
                size: 10,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              const Text(
                'Activo',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ],
        ),
        trailing: participante.usuarioId == widget.sesion.iniciadaPor
            ? const Chip(
                label: Text(
                  'Líder',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 4),
              )
            : null,
      ),
    );
  }

  // ========================================
  // MÉTODOS DE RUTA COMPARTIDA
  // ========================================

  Future<void> _calcularPolylineHaciaDestino(
    double destinoLat,
    double destinoLng,
  ) async {
    try {
      debugPrint('🗺️ Iniciando cálculo de polyline hacia destino');

      // Obtener ubicación actual
      debugPrint('📍 Obteniendo ubicación actual...');
      final position = await _trackingService.obtenerUbicacionActual();
      final origen = LatLng(position.latitude, position.longitude);
      final destino = LatLng(destinoLat, destinoLng);

      debugPrint('   Origen: (${position.latitude}, ${position.longitude})');
      debugPrint('   Destino: ($destinoLat, $destinoLng)');

      // Calcular ruta usando GoogleDirectionsService
      debugPrint('🔍 Consultando Google Directions API...');
      final directions = await _directionsService.getDirections(
        origin: origen,
        destination: destino,
      );

      if (directions.routes.isNotEmpty) {
        final route = directions.routes.first;
        debugPrint('✅ Ruta encontrada con ${route.polylineEncoded.length} caracteres de polyline');

        // Decodificar polyline
        final polylinePoints = _directionsService.decodePolyline(
          route.polylineEncoded,
        );
        debugPrint('   ${polylinePoints.length} puntos decodificados');

        // Extraer steps de navegación para instrucciones de voz
        final steps = <NavigationStep>[];
        if (route.legs.isNotEmpty) {
          final leg = route.legs.first;
          debugPrint('   ${leg.steps.length} pasos de navegación encontrados');

          for (final directionStep in leg.steps) {
            final stepPolylinePoints = _directionsService.decodePolyline(
              directionStep.polylineEncoded,
            );
            final navStep = directionStep.toNavigationStep(stepPolylinePoints);
            steps.add(navStep);
          }

          debugPrint('✅ ${steps.length} pasos de navegación procesados');
        }

        // Crear polyline
        final polyline = Polyline(
          polylineId: const PolylineId('ruta_compartida'),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        );

        // Agregar marcador de destino
        final destinoMarker = Marker(
          markerId: const MarkerId('destino_compartido'),
          position: destino,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: _rutaCompartida?['destino_nombre'] as String? ?? 'Destino',
            snippet: 'Toca para navegar',
          ),
          onTap: _iniciarNavegacionHaciaDestino,
        );

        setState(() {
          _polylineCompartida = polyline;
          _markers['destino_compartido'] = destinoMarker;
          _navigationSteps = steps; // Guardar steps para navegación por voz
          _currentStepIndex = null; // Resetear índice
        });

        // Inicializar navegación por voz si hay pasos
        if (steps.isNotEmpty && _estaAprobado) {
          _iniciarNavegacionPorVoz();
        }

        debugPrint('✅ Polyline, marcador y navegación por voz configurados');
      } else {
        debugPrint('⚠️ Google Directions no encontró rutas');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error al calcular polyline: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow; // Re-lanzar para que el retry lo capture
    }
  }

  /// Wrapper con retry automático para calcular polyline
  ///
  /// Reintenta hasta 3 veces con exponential backoff si falla
  Future<void> _calcularPolylineHaciaDestinoConRetry(
    double destinoLat,
    double destinoLng, {
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 2),
  }) async {
    int intento = 0;

    while (intento < maxRetries) {
      try {
        intento++;
        debugPrint('🔄 Intento $intento/$maxRetries de calcular polyline');

        await _calcularPolylineHaciaDestino(destinoLat, destinoLng);
        debugPrint('✅ Polyline calculada exitosamente');
        return; // Éxito, salir

      } catch (e) {
        debugPrint('❌ Error en intento $intento: $e');

        if (intento >= maxRetries) {
          // Falló después de todos los intentos
          debugPrint('🚫 Máximo de reintentos alcanzado ($maxRetries)');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('No se pudo calcular ruta al destino'),
                action: SnackBarAction(
                  label: 'Reintentar',
                  onPressed: () => _calcularPolylineHaciaDestinoConRetry(
                    destinoLat,
                    destinoLng,
                  ),
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return; // Salir después de mostrar error
        }

        // Exponential backoff: 2s, 4s, 8s
        final delay = baseDelay * (1 << (intento - 1)); // Bitshift para potencia de 2
        debugPrint('⏳ Esperando ${delay.inSeconds}s antes del siguiente intento');
        await Future.delayed(delay);
      }
    }
  }

  void _mostrarIniciarRuta() async {
    // Validar permisos
    if (!_esLider) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo el líder puede compartir rutas.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _IniciarRutaDialog(),
    );

    if (resultado != null && mounted) {
      try {
        await _grupoRepository.compartirRuta(
          sesionId: widget.sesion.id,
          destinoLat: resultado['lat'] as double,
          destinoLng: resultado['lng'] as double,
          destinoNombre: resultado['nombre'] as String?,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ruta compartida: ${resultado['nombre'] ?? 'Destino'}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al compartir ruta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _confirmarCancelarRuta() async {
    // Validar permisos
    if (!_esLider) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo el líder puede cancelar rutas.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Cancelar Ruta'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres cancelar la ruta?\n\n'
          'Esto eliminará el destino para todos los participantes de la sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await _cancelarRuta();
    }
  }

  void _mostrarDialogSesionFinalizada() {
    // Determinar mensaje según rol
    String mensaje;
    if (_esLider) {
      // El usuario es el líder de la sesión (quien la inició)
      mensaje = 'Has finalizado "${widget.sesion.nombreSesion}".';
    } else if (_esAdminGrupo) {
      // El usuario es admin del grupo y finalizó la sesión de otro
      mensaje = 'Has finalizado la sesión "${widget.sesion.nombreSesion}" como líder del grupo.';
    } else {
      // El usuario es participante normal
      mensaje = 'El líder del grupo ha finalizado "${widget.sesion.nombreSesion}".';
    }

    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Sesión Finalizada'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mensaje,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'El tracking de ubicación ha sido detenido.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Cerrar dialog
              Navigator.pop(context); // Volver a pantalla anterior (detalle o lista)
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Entendido'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelarRuta() async {
    try {
      debugPrint('🗑️ Iniciando cancelación de ruta...');

      // PASO 0: Detener navegación por voz si estaba activa
      if (_navigationSteps != null) {
        _detenerNavegacionPorVoz();
      }

      // PASO 1: Limpiar UI INMEDIATAMENTE (no esperar stream)
      if (mounted) {
        setState(() {
          _rutaCompartida = null;
          _polylineCompartida = null;
          _markers.remove('destino_compartido');
        });
        debugPrint('✅ UI limpiada localmente');
      }

      // PASO 2: Eliminar de base de datos (notifica a otros vía stream)
      await _grupoRepository.eliminarRutaCompartida(widget.sesion.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruta cancelada para todos los participantes'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error cancelando ruta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar ruta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Inicia la navegación por voz
  ///
  /// - Inicializa el servicio TTS
  /// - Anuncia la primera instrucción
  /// - Inicia el tracking de ubicación para detectar cambios de paso
  Future<void> _iniciarNavegacionPorVoz() async {
    if (_navigationSteps == null || _navigationSteps!.isEmpty) {
      debugPrint('⚠️ No hay pasos de navegación, no se puede iniciar voz');
      return;
    }

    try {
      debugPrint('🔊 Inicializando navegación por voz...');

      // 1. Inicializar servicio de voz
      await _voiceService.initialize();

      // 2. Anunciar primera instrucción
      if (_navigationSteps!.isNotEmpty) {
        final firstStep = _navigationSteps!.first;
        _currentStepIndex = 0;

        await _voiceService.announceInstruction(
          firstStep.instruction,
          firstStep.distanceText,
          stepIndex: 0,
        );

        debugPrint('✅ Primera instrucción anunciada: ${firstStep.instruction}');
      }

      // 3. Iniciar tracking de ubicación para detectar cambios de paso
      _navigationLocationSubscription = _trackingService
          .ubicacionStream
          .listen((position) => _onNavigationLocationUpdate(position));

      debugPrint('✅ Navegación por voz iniciada');
    } catch (e) {
      debugPrint('❌ Error al iniciar navegación por voz: $e');
    }
  }

  /// Callback cuando se actualiza la ubicación durante navegación
  void _onNavigationLocationUpdate(Position position) {
    if (_navigationSteps == null ||
        _navigationSteps!.isEmpty ||
        _currentStepIndex == null) {
      return;
    }

    final currentStep = _navigationSteps![_currentStepIndex!];

    // Calcular distancia al final del paso actual
    final distanceToStepEnd = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep.endLocation.latitude,
      currentStep.endLocation.longitude,
    );

    // Si estamos a menos de 30m del final del paso, avanzar al siguiente
    if (distanceToStepEnd < 30.0) {
      final nextStepIndex = _currentStepIndex! + 1;

      if (nextStepIndex < _navigationSteps!.length) {
        // Avanzar al siguiente paso
        _currentStepIndex = nextStepIndex;
        final nextStep = _navigationSteps![nextStepIndex];

        // Anunciar siguiente instrucción
        _voiceService.announceInstruction(
          nextStep.instruction,
          nextStep.distanceText,
          stepIndex: nextStepIndex,
        );

        debugPrint('➡️ Avanzando a paso $nextStepIndex: ${nextStep.instruction}');
      } else {
        // Llegamos al destino
        _voiceService.announceArrival();
        _detenerNavegacionPorVoz();
        debugPrint('🎯 Llegada al destino');
      }
    }
    // Alertas de proximidad a 200m y 100m
    else if (distanceToStepEnd <= 200 && distanceToStepEnd > 150) {
      _voiceService.announceProximityAlert(
        currentStep.instruction,
        200,
      );
    } else if (distanceToStepEnd <= 100 && distanceToStepEnd > 50) {
      _voiceService.announceProximityAlert(
        currentStep.instruction,
        100,
      );
    }
  }

  /// Detiene la navegación por voz
  void _detenerNavegacionPorVoz() {
    debugPrint('🔇 Deteniendo navegación por voz...');

    _navigationLocationSubscription?.cancel();
    _navigationLocationSubscription = null;

    _voiceService.stop();

    setState(() {
      _navigationSteps = null;
      _currentStepIndex = null;
    });

    debugPrint('✅ Navegación por voz detenida');
  }

  void _iniciarNavegacionHaciaDestino() {
    if (_rutaCompartida == null) return;

    // TODO: Implementar navegación hacia destino compartido
    // Esto debería abrir la pantalla de navegación con el destino
    // final destino = LatLng(
    //   _rutaCompartida!['destino_lat'] as double,
    //   _rutaCompartida!['destino_lng'] as double,
    // );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Navegación hacia ${_rutaCompartida!['destino_nombre'] ?? 'destino'}',
        ),
      ),
    );
  }
}

// ========================================
// DIÁLOGO INICIAR RUTA
// ========================================

class _IniciarRutaDialog extends StatefulWidget {
  const _IniciarRutaDialog({super.key});

  @override
  State<_IniciarRutaDialog> createState() => _IniciarRutaDialogState();
}

class _IniciarRutaDialogState extends State<_IniciarRutaDialog> {
  final _ubicacionController = TextEditingController();
  LatLng? _destinoSeleccionado;
  String? _nombreDestino;

  @override
  void dispose() {
    _ubicacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.route, color: Colors.teal),
          const SizedBox(width: 8),
          const Text('Iniciar Ruta'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Busca y selecciona el destino de la ruta. Se enviará a todos los participantes de la sesión.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            LocationSearchField(
              controller: _ubicacionController,
              labelText: 'Destino',
              hintText: 'Buscar ubicación...',
              onLocationSelected: (address, coordinates) {
                setState(() {
                  _destinoSeleccionado = coordinates;
                  _nombreDestino = address;
                });
                debugPrint('📍 Destino seleccionado: $address');
                debugPrint('   Coordenadas: ${coordinates.latitude}, ${coordinates.longitude}');
              },
            ),
            if (_destinoSeleccionado != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Destino confirmado',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _nombreDestino ?? 'Ubicación seleccionada',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${_destinoSeleccionado!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_destinoSeleccionado!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _destinoSeleccionado != null ? _confirmar : null,
          icon: const Icon(Icons.navigation),
          label: const Text('Iniciar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _confirmar() {
    if (_destinoSeleccionado == null) return;

    Navigator.pop(context, {
      'lat': _destinoSeleccionado!.latitude,
      'lng': _destinoSeleccionado!.longitude,
      'nombre': _nombreDestino,
    });
  }
}

/// Widget de texto con efecto marquee (scroll horizontal) para textos largos
///
/// Si el texto cabe en el ancho disponible, se muestra normal.
/// Si es muy largo, se anima con efecto marquee (scroll horizontal continuo).
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _MarqueeText({
    required this.text,
    this.style,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Esperar a que se construya el widget para verificar si necesita scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrollingIfNeeded();
    });
  }

  void _startScrollingIfNeeded() {
    if (!mounted) return;

    // Verificar si el contenido excede el ancho disponible
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _isScrolling = true;
      });
      _animate();
    }
  }

  void _animate() async {
    if (!mounted || !_isScrolling) return;

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted || !_scrollController.hasClients) return;

    // Scroll hacia la derecha
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: widget.text.length * 50),
      curve: Curves.linear,
    );

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted || !_scrollController.hasClients) return;

    // Volver al inicio
    await _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: widget.text.length * 50),
      curve: Curves.linear,
    );

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));

    // Repetir
    _animate();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}
