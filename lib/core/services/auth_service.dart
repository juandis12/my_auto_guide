import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Excepción personalizada para mapear errores conocidos de Supabase a mensajes UI amigables
class AuthLogicException implements Exception {
  final String message;
  final bool isNotConfirmed;
  AuthLogicException(this.message, {this.isNotConfirmed = false});
  @override
  String toString() => message;
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = SupabaseService().client;

  /// Retorna el usuario actual si hay sesión; de otra forma, null
  User? get currentUser => _supabase.auth.currentUser;

  /// Retorna la id del primer vehículo que tenga el usuario; de otra forma, null
  Future<String?> getFirstVehicleId() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final List data = await _supabase
          .from('vehiculos')
          .select('id')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);
          
      if (data.isNotEmpty) {
        return (data.first as Map)['id'] as String;
      }
      return null;
    } catch (e) {
      // Retorna null silenciosamente porque el objetivo de bootstrap es enrutar limpiamente.
      return null;
    }
  }

  /// Inicia sesión con correo y clave.
  Future<void> signIn(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('not confirmed')) {
         throw AuthLogicException('Tu correo no está confirmado. Revisa tu bandeja o reenvía el correo de verificación.', isNotConfirmed: true);
      }
      throw AuthLogicException(e.message);
    } catch (e) {
      throw AuthLogicException('Error inesperado: $e');
    }
  }

  /// Reenvía confirmación de email (OtpType.signup)
  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
    } on AuthException catch (e) {
      throw AuthLogicException(e.message);
    } catch (e) {
      throw AuthLogicException('Error inesperado: $e');
    }
  }

  /// Envia enlace para restablecer contraseña
  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      throw AuthLogicException('Ingresa tu e-mail para recuperar la contraseña.');
    }
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthLogicException(e.message);
    } catch (e) {
      throw AuthLogicException('Error inesperado: $e');
    }
  }

  /// Cerrar Sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
