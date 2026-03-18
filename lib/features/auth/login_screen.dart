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

class CarRentalLoginScreen extends StatefulWidget {
  const CarRentalLoginScreen({super.key});

  @override
  State<CarRentalLoginScreen> createState() => _CarRentalLoginScreenState();
}

class _CarRentalLoginScreenState extends State<CarRentalLoginScreen> {
  final _auth = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _bootstrapSession(); // intenta usar sesión reciente guardada [1]
  }

  // Si hay sesión vigente, salta el login y navega donde corresponda
  Future<void> _bootstrapSession() async {
    if (_auth.currentUser == null) return;
    if (!mounted) return;
    await _goToDestination(); 
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

  Future<void> signIn() async {
    setState(() => isLoading = true);
    try {
      await _auth.signIn(
         emailController.text, 
         passwordController.text
      );

      if (!mounted) return;
      await _goToDestination();
    } on AuthLogicException catch (e) {
      if (!mounted) return;
      if (e.isNotConfirmed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            action: SnackBarAction(
              label: 'Reenviar',
              onPressed: () async {
                try {
                  await _auth.resendConfirmationEmail(emailController.text);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correo de confirmación reenviado.')),
                  );
                } on AuthLogicException catch (e2) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo reenviar: ${e2.message}')),
                  );
                }
              },
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: ${e.message}')),
         );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> sendPasswordReset() async {
    try {
      await _auth.sendPasswordReset(emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te enviamos un enlace para restablecer tu contraseña.')),
      ); 
    } on AuthLogicException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      ); 
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
                  PerformanceGuard.adaptiveBlur(
                    borderRadius: BorderRadius.circular(16),
                    fallbackColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1)),
                      ),
                      child: TextField(
                        controller: emailController,
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          labelText: 'E-mail',
                          labelStyle: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.6)),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.email_outlined,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.6)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PerformanceGuard.adaptiveBlur(
                    borderRadius: BorderRadius.circular(16),
                    fallbackColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1)),
                      ),
                      child: TextField(
                        controller: passwordController,
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.6)),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.lock_outline,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.6)),
                        ),
                        obscureText: true,
                      ),
                    ),
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

                  // Botón Iniciar Sesión con gradiente armonizado
                  Container(
                    width: double.infinity,
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
                      _SocialButton(icon: 'assets/google.png', onTap: () {}),
                      const SizedBox(width: 24),
                      _SocialButton(icon: 'assets/facebook.png', onTap: () {}),
                      const SizedBox(width: 24),
                      _SocialButton(icon: 'assets/apple.png', onTap: () {}),
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
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1)),
          boxShadow: [
            if (!PerformanceGuard().isLowEnd)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              )
          ],
        ),
        child: Image.asset(icon, height: 28),
      ),
    );
  }
}
