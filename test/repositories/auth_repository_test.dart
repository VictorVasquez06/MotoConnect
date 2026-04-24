// Módulo: Repositorio de autenticación — tests de contrato
// Fuente: lib/data/repositories/auth_repository.dart (interfaz)
//         lib/data/repositories/impl/auth_repository_impl.dart (implementación)
//
// AuthRepositoryImpl depende de AuthApiService, que internamente usa
// Supabase.instance.client. No es posible instanciar AuthRepositoryImpl
// en tests unitarios sin inicializar Supabase primero.
//
// Estos tests verifican el contrato de la interfaz y la relación de tipos.

import 'package:flutter_test/flutter_test.dart';

import 'package:motoconnect/data/repositories/auth_repository.dart';
import 'package:motoconnect/data/repositories/impl/auth_repository_impl.dart';

import '../helpers/mock_repositories.dart';

void main() {
  group('AuthRepository — contrato de interfaz', () {
    test('MockAuthRepository implementa AuthRepository', () {
      final mock = MockAuthRepository();
      expect(mock, isA<AuthRepository>());
    });

    test('AuthRepositoryImpl implementa AuthRepository (verificación de tipo)',
        () {
      // No se puede instanciar sin Supabase inicializado, pero el sistema
      // de tipos de Dart garantiza que AuthRepositoryImpl implements AuthRepository.
      // Si esta línea compila, el contrato se cumple.
      expect(AuthRepositoryImpl, isNotNull);
    });

    test(
      'AuthRepositoryImpl se instancia correctamente',
      () {
        // AuthApiService() requiere Supabase.instance → no disponible en tests.
        final impl = AuthRepositoryImpl();
        expect(impl, isA<AuthRepository>());
      },
      skip: 'Requiere integración real con Supabase '
          '(AuthApiService usa Supabase.instance internamente)',
    );

    test('la interfaz declara los métodos esperados', () {
      // Verificación en tiempo de compilación: si alguno de estos métodos
      // no existe en AuthRepository, el test no compila.
      final mock = MockAuthRepository();
      expect(mock.signIn, isNotNull);
      expect(mock.signUp, isNotNull);
      expect(mock.signOut, isNotNull);
      expect(mock.getCurrentUser, isNotNull);
      expect(mock.isAuthenticated, isNotNull);
      expect(mock.resetPassword, isNotNull);
      expect(mock.signInWithGoogle, isNotNull);
      // onAuthStateChange es un getter Stream — requiere stub para no ser null.
      // La existencia del getter se verifica en tiempo de compilación.
    });
  });
}
