import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_auto_guide/core/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
      debug: false,
    );
  });

  group('AuthProvider', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    test('Initial state', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoading, false);
      expect(authProvider.user, isNull);
    });

    test('signOut leaves the provider unauthenticated', () async {
      await authProvider.signOut();
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
    });

    test('signIn with invalid credentials rethrows and clears the loading flag', () async {
      await expectLater(
        authProvider.signIn('nobody@example.com', 'wrong-password'),
        throwsA(isA<Exception>()),
      );
      expect(authProvider.isLoading, false);
      expect(authProvider.isAuthenticated, false);
    });
  });
}
