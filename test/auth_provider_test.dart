import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    test('Initial state', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoading, false);
    });
  });
}
