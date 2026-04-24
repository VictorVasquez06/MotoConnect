// Mock repositories para testing — cubre las 9 interfaces abstractas del proyecto.
// Fuente: lib/data/repositories/*.dart

import 'package:mocktail/mocktail.dart';

import 'package:motoconnect/data/repositories/auth_repository.dart';
import 'package:motoconnect/data/repositories/community_repository.dart';
import 'package:motoconnect/data/repositories/event_repository.dart';
import 'package:motoconnect/data/repositories/grupo_repository.dart';
import 'package:motoconnect/data/repositories/navigation_repository.dart';
import 'package:motoconnect/data/repositories/profile_repository.dart';
import 'package:motoconnect/data/repositories/routes_repository.dart';
import 'package:motoconnect/data/repositories/saved_routes_repository.dart';
import 'package:motoconnect/data/repositories/taller_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCommunityRepository extends Mock implements CommunityRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockGrupoRepository extends Mock implements GrupoRepository {}

class MockNavigationRepository extends Mock implements NavigationRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockRoutesRepository extends Mock implements RoutesRepository {}

class MockSavedRoutesRepository extends Mock implements SavedRoutesRepository {}

class MockTallerRepository extends Mock implements TallerRepository {}
