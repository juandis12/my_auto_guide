// =============================================================================
// login_screen.dart — PANTALLA DE INICIO DE SESIÓN
// =============================================================================
//
// Maneja la autenticación del usuario mediante email y contraseña usando
// Supabase Auth. Incluye:
//   - Login con email/contraseña.
//   - Verificación automática de sesión previa (auto-login).
//   - Recuperación de contraseña por correo.
//   - Reenvío de correo de confirmación si la cuenta no está verificada.
//   - Navegación post-login: si el usuario tiene vehículos registrados va a
//     [InicioApp]; si no, va a [AgregarVehiculoScreen].
//   - Botones decorativos de login social (Google, Facebook, Apple).
//   - Enlace para navegar a la pantalla de registro [RegistroScreen].
//
// Flujo de navegación:
//   CarRentalLoginScreen → InicioApp (si hay vehículos)
//                        → AgregarVehiculoScreen (si no hay vehículos)
//                        → RegistroScreen (si el usuario quiere registrarse)
//
// =============================================================================

import 'package:flutter/material.dart';
import 'registro_screen.dart';
import '../vehicles/presentation/Agregar_vehiculo.dart';
import '../vehicles/presentation/inicio_app.dart';
import '../../core/services/auth_service.dart';
import '../../core/logic/performance_guard.dart';
import '../../shared/widgets/app_snack_bar.dart';
import '../../shared/widgets/glass_text_field.dart';

import '../../core/services/biometric_service.dart';
import '../../core/services/app_update_service.dart';
import '../updater/presentation/app_update_lock_screen.dart';

class CarRentalLoginScreen extends StatefulWidget {
  const CarRentalLoginScreen({super.key});

  @override
  State<CarRentalLoginScreen> createState() => _CarRentalLoginScreenState();
}

class _CarRentalLoginScreenState extends State<CarRentalLoginScreen> {
  final _auth = AuthService();
  final _biometric = BiometricService();
  final _updateService = AppUpdateService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = true; // Por defecto true para mayor comodidad
  bool canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final update = await _updateService.checkForUpdate();
    if (update != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AppUpdateLockScreen(updateInfo: update)),
      );
      return;
    }
    await _checkBiometrics();
    await _bootstrapSession();
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometric.isBiometricAvailable();
    if (mounted) setState(() => canUseBiometrics = available);
  }

  // Carga preferencias pero no autologuea de forma automática en el arranque
  Future<void> _bootstrapSession() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldRemember = prefs.getBool('remember_me') ?? false;
    
    if (mounted) setState(() => rememberMe = shouldRemember);

    // Rellenar email del usuario actual si existe sesión previa
    if (_auth.currentUser != null && _auth.currentUser!.email != null) {
      emailController.text = _auth.currentUser!.email!;
    }
  }

  Future<void> _loginAlternative() async {
    if (!canUseBiometrics) return;
    final authenticated = await _biometric.authenticate();
    if (authenticated) {
      if (_auth.currentUser != null) {
        await _goToDestination();
      } else {
        AppSnackBar.show(
          context,
          'Por favor, inicia sesión con correo y contraseña primero para habilitar el acceso biométrico.',
        );
      }
    }
  }

  // Decide a dónde navegar: InicioApp con id o AgregarVehiculo si no hay registros
  Future<void> _goToDestination() async {
    if (_auth.currentUser == null) return;

    final String? vehiculoId = await _auth.getFirstVehicleId();
    if (!mounted) return;
    
    if (vehiculoId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InicioApp(vehiculoId: vehiculoId)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AgregarVehiculoScreen()),
      );
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => isLoading = true);
    try {
      await _auth.signInWithGoogle();
      await _goToDestination();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, '$e');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loginFacebook() async {
    setState(() => isLoading = true);
    try {
      await _auth.signInWithFacebook();
      await _goToDestination();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, '$e');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signIn() async {
    setState(() => isLoading = true);
    try {
      await _auth.signIn(
         emailController.text, 
         passwordController.text
      );

      // Guardar preferencia de recordar
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);

      if (!mounted) return;
      await _goToDestination();
    } on AuthLogicException catch (e) {
      if (!mounted) return;
      if (e.isNotConfirmed) {
        AppSnackBar.show(
          context,
          e.message,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Reenviar',
            onPressed: () async {
              try {
                await _auth.resendConfirmationEmail(emailController.text);
                if (!mounted) return;
                AppSnackBar.show(context, 'Correo de confirmación reenviado.');
              } on AuthLogicException catch (e2) {
                if (!mounted) return;
                AppSnackBar.show(
                    context, 'No se pudo reenviar: ${e2.message}');
              }
            },
          ),
        );
      } else {
        AppSnackBar.show(context, 'Error: ${e.message}');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> sendPasswordReset() async {
    try {
      await _auth.sendPasswordReset(emailController.text);
      if (!mounted) return;
      AppSnackBar.show(
          context, 'Te enviamos un enlace para restablecer tu contraseña.');
    } on AuthLogicException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/bg_pattern.png',
              fit: BoxFit.cover,
              cacheWidth: PerformanceGuard().isLowEnd
                  ? 400
                  : null, // Reducir carga de textura
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/car.png', height: 180),
                  const Text(
                    'Car Rental',
                    style: TextStyle(
                      fontFamily: 'Outfit', // Usando la nueva fuente Outfit
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Viajar, Amar un coche',
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 0.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Campos de entrada con Glassmorphism suave
                  GlassTextField(
                    controller: emailController,
                    label: 'E-mail',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Theme(
                        data: ThemeData(
                            unselectedWidgetColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.black.withOpacity(0.3)),
                        child: Checkbox(
                          value: rememberMe,
                          checkColor: Colors.white,
                          activeColor: const Color(0xFF035880),
                          onChanged: (value) =>
                              setState(() => rememberMe = value ?? false),
                        ),
                      ),
                      Text(
                        'Recuerdame',
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.black.withOpacity(0.7)),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: sendPasswordReset,
                        child: Text(
                          'Recuperar contraseña',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.7)
                                    : const Color(0xFF035880),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                      // Botón Iniciar Sesión y Biometría
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: PerformanceGuard().isLowEnd
                                    ? null
                                    : const LinearGradient(
                                        colors: [Color(0xFF035880), Color(0xFF023E5A)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                color: PerformanceGuard().isLowEnd
                                    ? const Color(0xFF035880)
                                    : null,
                                boxShadow: [
                                  if (!PerformanceGuard().isLowEnd)
                                    BoxShadow(
                                      color: const Color(0xFF035880).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Iniciar Sesión'),
                              ),
                            ),
                          ),
                          if (canUseBiometrics) ...[
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: _loginAlternative,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF035880).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF035880).withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.fingerprint, size: 32, color: Color(0xFF035880)),
                              ),
                            ),
                          ],
                        ],
                      ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Ingresa con',
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.5)),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(
                        icon: 'assets/google.png',
                        fallbackIcon: Icons.g_mobiledata_rounded,
                        iconColor: Colors.redAccent,
                        onTap: _loginGoogle,
                      ),
                      const SizedBox(width: 24),
                      _SocialButton(
                        icon: 'assets/facebook.png',
                        fallbackIcon: Icons.facebook_rounded,
                        iconColor: const Color(0xFF1877F2),
                        onTap: _loginFacebook,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegistroScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: '¿Aún no tienes cuenta? ',
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.black.withOpacity(0.6)),
                        children: [
                          TextSpan(
                            text: 'Registrarme',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF035880),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String icon;
  final IconData? fallbackIcon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    this.fallbackIcon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.12)),
          boxShadow: PerformanceGuard().isLowEnd
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: fallbackIcon != null
            ? Icon(fallbackIcon, size: 28, color: iconColor ?? Colors.white)
            : Image.asset(icon, height: 28),
      ),
    );
  }
}
