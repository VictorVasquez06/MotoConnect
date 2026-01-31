/// Pruebas unitarias para RoutesBloc
///
/// Valida la lógica de negocio de rutas sin necesidad de UI.
/// Usa FakeRouteRepository para simular respuestas del repositorio.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:motoconnect/data/models/route_model.dart';
import 'package:motoconnect/domain/repositories/i_route_repository.dart';
import 'package:motoconnect/presentation/blocs/routes/routes_bloc.dart';
import 'package:motoconnect/presentation/blocs/routes/routes_event.dart';
import 'package:motoconnect/presentation/blocs/routes/routes_state.dart';

// ============================================================================
// FAKE REPOSITORY - Implementación manual para testing
// ============================================================================

class FakeRouteRepository implements IRouteRepository {
  bool shouldSucceed = true;
  String errorMessage = 'Error de prueba';
  List<RouteModel> mockRoutes = [];

  /// Rutas de prueba por defecto
  List<RouteModel> get defaultRoutes => [
    RouteModel(
      id: 'route-1',
      userId: 'user-123',
      nombreRuta: 'Ruta al Páramo',
      descripcionRuta: 'Una ruta escénica por las montañas',
      puntos: const [LatLng(4.5981, -74.0758), LatLng(4.6500, -74.1000)],
      distanciaKm: 45.5,
      duracionMinutos: 90,
      fecha: DateTime.now().subtract(const Duration(days: 7)),
    ),
    RouteModel(
      id: 'route-2',
      userId: 'user-456',
      nombreRuta: 'Circuito Urbano',
      descripcionRuta: 'Ruta por la ciudad',
      puntos: const [LatLng(4.6097, -74.0818), LatLng(4.6200, -74.0900)],
      distanciaKm: 20.0,
      duracionMinutos: 45,
      fecha: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Future<List<RouteModel>> getUserRoutes(String userId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultRoutes.where((r) => r.userId == userId).toList();
  }

  @override
  Future<RouteModel?> getRouteById(String routeId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    try {
      return defaultRoutes.firstWhere((r) => r.id == routeId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RouteModel> createRoute({
    required String userId,
    required String nombreRuta,
    String? descripcionRuta,
    required List<LatLng> puntos,
    double? distanciaKm,
    int? duracionMinutos,
    String? imagenUrl,
  }) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return RouteModel(
      id: 'new-route-id',
      userId: userId,
      nombreRuta: nombreRuta,
      descripcionRuta: descripcionRuta,
      puntos: puntos,
      distanciaKm: distanciaKm,
      duracionMinutos: duracionMinutos,
      imagenUrl: imagenUrl,
      fecha: DateTime.now(),
    );
  }

  @override
  Future<void> updateRoute({
    required String routeId,
    String? nombreRuta,
    String? descripcionRuta,
    List<LatLng>? puntos,
    double? distanciaKm,
    int? duracionMinutos,
    String? imagenUrl,
  }) async {
    if (!shouldSucceed) throw Exception(errorMessage);
  }

  @override
  Future<void> deleteRoute(String routeId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
  }

  @override
  Future<List<RouteModel>> getRecentRoutes({int limit = 20}) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return mockRoutes.isNotEmpty ? mockRoutes : defaultRoutes;
  }

  @override
  Future<List<RouteModel>> searchRoutes(String query, {String? userId}) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultRoutes
        .where((r) => r.nombreRuta.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<RouteModel>> getRoutes({
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  }) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultRoutes;
  }

  @override
  Future<List<RouteModel>> getSavedRoutesForUser(String userId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultRoutes;
  }

  @override
  Future<List<RouteModel>> getRoutesCreatedByUser(String userId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultRoutes.where((r) => r.userId == userId).toList();
  }

  @override
  Future<bool> isRouteSavedByUser(String routeId, String userId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return false;
  }

  @override
  Future<void> saveRouteForUser(String routeId, String userId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
  }

  @override
  Future<void> removeRouteFromUserFavorites(
    String routeId,
    String userId,
  ) async {
    if (!shouldSucceed) throw Exception(errorMessage);
  }

  @override
  Future<void> updateRouteStatus(String routeId, String status) async {
    if (!shouldSucceed) throw Exception(errorMessage);
  }

  @override
  Future<bool> isRouteUsedInActiveEvents(String routeId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return false;
  }

  @override
  Future<List<RouteModel>> getRoutesByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultRoutes;
  }

  @override
  double calculateRouteDistance(List<LatLng> puntos) {
    return 10.0; // Valor fijo para testing
  }
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  late FakeRouteRepository fakeRepository;
  late RoutesBloc routesBloc;

  setUp(() {
    fakeRepository = FakeRouteRepository();
    routesBloc = RoutesBloc(routeRepository: fakeRepository);
  });

  tearDown(() {
    routesBloc.close();
  });

  group('RoutesBloc', () {
    // ========================================================================
    // TEST: Estado Inicial
    // ========================================================================
    test('estado inicial debe ser RoutesInitial', () {
      expect(routesBloc.state, const RoutesInitial());
    });

    // ========================================================================
    // TEST: RoutesFetchRequested - Carga Exitosa de Rutas de Usuario
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesLoaded] cuando RoutesFetchRequested exitoso',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const RoutesFetchRequested(userId: 'user-123')),
      expect: () => [const RoutesLoading(), isA<RoutesLoaded>()],
      verify: (bloc) {
        final state = bloc.state as RoutesLoaded;
        expect(state.filterType, 'user');
        // Solo debe cargar rutas del usuario especificado
        for (var route in state.routes) {
          expect(route.userId, 'user-123');
        }
      },
    );

    // ========================================================================
    // TEST: RoutesFetchRequested - Error de Carga
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesError] cuando RoutesFetchRequested falla',
      build: () {
        fakeRepository.shouldSucceed = false;
        fakeRepository.errorMessage = 'Network error';
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const RoutesFetchRequested(userId: 'user-123')),
      expect: () => [const RoutesLoading(), isA<RoutesError>()],
      verify: (bloc) {
        final state = bloc.state as RoutesError;
        expect(state.message.isNotEmpty, true);
      },
    );

    // ========================================================================
    // TEST: RoutesFetchRecentRequested - Carga Exitosa Rutas Recientes
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesLoaded] para rutas recientes',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const RoutesFetchRecentRequested()),
      expect: () => [const RoutesLoading(), isA<RoutesLoaded>()],
      verify: (bloc) {
        final state = bloc.state as RoutesLoaded;
        expect(state.filterType, 'recent');
        expect(state.routes.length, 2);
      },
    );

    // ========================================================================
    // TEST: RoutesCreateRequested - Creación Exitosa
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesOperationSuccess, ...] al crear ruta',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act:
          (bloc) => bloc.add(
            const RoutesCreateRequested(
              userId: 'user-123',
              nombreRuta: 'Nueva Ruta de Prueba',
              descripcionRuta: 'Descripción de la ruta de prueba',
              puntos: [
                LatLng(4.5981, -74.0758),
                LatLng(4.6500, -74.1000),
                LatLng(4.7000, -74.0500),
              ],
              distanciaKm: 55.0,
              duracionMinutos: 120,
            ),
          ),
      expect:
          () => [
            const RoutesLoading(),
            isA<RoutesOperationSuccess>(),
            // Después recarga rutas del usuario
            const RoutesLoading(),
            isA<RoutesLoaded>(),
          ],
      verify: (bloc) {
        // El estado final debe ser RoutesLoaded (por la recarga)
        expect(bloc.state, isA<RoutesLoaded>());
      },
    );

    // ========================================================================
    // TEST: RoutesCreateRequested - Creación Fallida
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesError] cuando crear ruta falla',
      build: () {
        fakeRepository.shouldSucceed = false;
        fakeRepository.errorMessage = 'Database error';
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act:
          (bloc) => bloc.add(
            const RoutesCreateRequested(
              userId: 'user-123',
              nombreRuta: 'Ruta Fallida',
              puntos: [LatLng(4.5981, -74.0758)],
            ),
          ),
      expect: () => [const RoutesLoading(), isA<RoutesError>()],
    );

    // ========================================================================
    // TEST: RoutesUpdateRequested - Actualización Exitosa
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesOperationSuccess] al actualizar ruta',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act:
          (bloc) => bloc.add(
            const RoutesUpdateRequested(
              routeId: 'route-1',
              nombreRuta: 'Ruta Actualizada',
              descripcionRuta: 'Nueva descripción',
            ),
          ),
      expect: () => [const RoutesLoading(), isA<RoutesOperationSuccess>()],
      verify: (bloc) {
        final state = bloc.state as RoutesOperationSuccess;
        expect(state.operationType, RoutesOperationType.updated);
      },
    );

    // ========================================================================
    // TEST: RoutesDeleteRequested - Eliminación Exitosa
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesOperationSuccess] al eliminar ruta',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const RoutesDeleteRequested(routeId: 'route-1')),
      expect: () => [const RoutesLoading(), isA<RoutesOperationSuccess>()],
      verify: (bloc) {
        final state = bloc.state as RoutesOperationSuccess;
        expect(state.operationType, RoutesOperationType.deleted);
      },
    );

    // ========================================================================
    // TEST: RoutesSaveToFavoritesRequested - Guardar en Favoritos
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesOperationSuccess] al guardar en favoritos',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act:
          (bloc) => bloc.add(
            const RoutesSaveToFavoritesRequested(
              routeId: 'route-2',
              userId: 'user-123',
            ),
          ),
      expect: () => [const RoutesLoading(), isA<RoutesOperationSuccess>()],
      verify: (bloc) {
        final state = bloc.state as RoutesOperationSuccess;
        expect(state.operationType, RoutesOperationType.savedToFavorites);
      },
    );

    // ========================================================================
    // TEST: RoutesRemoveFromFavoritesRequested - Eliminar de Favoritos
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesOperationSuccess] al eliminar de favoritos',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act:
          (bloc) => bloc.add(
            const RoutesRemoveFromFavoritesRequested(
              routeId: 'route-2',
              userId: 'user-123',
            ),
          ),
      expect: () => [const RoutesLoading(), isA<RoutesOperationSuccess>()],
      verify: (bloc) {
        final state = bloc.state as RoutesOperationSuccess;
        expect(state.operationType, RoutesOperationType.removedFromFavorites);
      },
    );

    // ========================================================================
    // TEST: RoutesSearchRequested - Búsqueda Exitosa
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesLoaded] al buscar rutas',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const RoutesSearchRequested(query: 'Páramo')),
      expect: () => [const RoutesLoading(), isA<RoutesLoaded>()],
      verify: (bloc) {
        final state = bloc.state as RoutesLoaded;
        expect(state.filterType, 'search');
        expect(state.routes.length, 1);
        expect(state.routes.first.nombreRuta, contains('Páramo'));
      },
    );

    // ========================================================================
    // TEST: RoutesLoadDetailsRequested - Cargar Detalles
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesDetailLoaded] al cargar detalles de ruta',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act:
          (bloc) =>
              bloc.add(const RoutesLoadDetailsRequested(routeId: 'route-1')),
      expect: () => [const RoutesLoading(), isA<RoutesDetailLoaded>()],
      verify: (bloc) {
        final state = bloc.state as RoutesDetailLoaded;
        expect(state.route.id, 'route-1');
        expect(state.route.nombreRuta, 'Ruta al Páramo');
      },
    );

    // ========================================================================
    // TEST: RoutesLoadDetailsRequested - Ruta No Encontrada
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesError] cuando ruta no encontrada',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act:
          (bloc) => bloc.add(
            const RoutesLoadDetailsRequested(routeId: 'ruta-inexistente'),
          ),
      expect: () => [const RoutesLoading(), isA<RoutesError>()],
      verify: (bloc) {
        final state = bloc.state as RoutesError;
        expect(state.message.toLowerCase(), contains('no encontr'));
      },
    );

    // ========================================================================
    // TEST: RoutesFetchByLocationRequested - Búsqueda por Ubicación
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesLoaded] al buscar por ubicación',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act:
          (bloc) => bloc.add(
            const RoutesFetchByLocationRequested(
              latitude: 4.5981,
              longitude: -74.0758,
              radiusKm: 20,
            ),
          ),
      expect: () => [const RoutesLoading(), isA<RoutesLoaded>()],
      verify: (bloc) {
        final state = bloc.state as RoutesLoaded;
        expect(state.filterType, 'location');
      },
    );

    // ========================================================================
    // TEST: RoutesFetchSavedRequested - Rutas Guardadas
    // ========================================================================
    blocTest<RoutesBloc, RoutesState>(
      'emite [RoutesLoading, RoutesLoaded] al cargar rutas guardadas',
      build: () {
        fakeRepository.shouldSucceed = true;
        return RoutesBloc(routeRepository: fakeRepository);
      },
      act:
          (bloc) =>
              bloc.add(const RoutesFetchSavedRequested(userId: 'user-123')),
      expect: () => [const RoutesLoading(), isA<RoutesLoaded>()],
      verify: (bloc) {
        final state = bloc.state as RoutesLoaded;
        expect(state.filterType, 'saved');
      },
    );
  });
}
