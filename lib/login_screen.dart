import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registro_screen.dart';
import 'Agregar_vehiculo.dart';
import 'inicio_app.dart'; // pantalla de inicio

class CarRentalLoginScreen extends StatefulWidget {
  const CarRentalLoginScreen({Key? key}) : super(key: key);

  @override
  State<CarRentalLoginScreen> createState() => _CarRentalLoginScreenState();
}

class _CarRentalLoginScreenState extends State<CarRentalLoginScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

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
    final session =
        supabase.auth.currentSession; // sesión persistida si existe [1]
    if (session == null) return;
    if (!mounted) return;
    await _goToDestination(); // decide destino por vehículos [2][3]
  }

  // Decide a dónde navegar: InicioApp con id o AgregarVehiculo si no hay registros
  Future<void> _goToDestination() async {
    final user = supabase.auth.currentUser; // usuario autenticado [1]
    if (user == null) return;

    try {
      final List data = await supabase
          .from('vehiculos')
          .select('id') // solo id, más eficiente [2]
          .eq('user_id', user.id) // filas del usuario [4]
          .order('created_at', ascending: false)
          .limit(1); // máximo 1 fila [3]

      if (!mounted) return;
      if (data.isNotEmpty) {
        final String vehiculoId = (data.first as Map)['id'] as String;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => InicioApp(vehiculoId: vehiculoId)),
        ); // ir a inicio con el id hallado [2]
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AgregarVehiculoScreen()),
        ); // no hay vehículos, ir a agregar [2]
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo verificar vehículos: ${e.message}')),
      ); // mensaje de respaldo [2]
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AgregarVehiculoScreen()),
      ); // fallback razonable [2]
    }
  }

  Future<void> signIn() async {
    setState(() => isLoading = true);
    try {
      final res = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      ); // login con email/contraseña [1]

      if (res.session != null && res.user != null) {
        if (!mounted) return;
        await _goToDestination(); // reutiliza la misma verificación [2][3]
      }
    } on AuthException catch (e) {
      final msg = (e.message ?? '').toLowerCase();

      // Caso: correo no confirmado
      if (msg.contains('not confirmed')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Tu correo no está confirmado. Revisa tu bandeja o reenvía el correo de verificación.',
            ),
            action: SnackBarAction(
              label: 'Reenviar',
              onPressed: () async {
                try {
                  await supabase.auth.resend(
                    type: OtpType.signup,
                    email: emailController.text.trim(),
                  ); // reenvía confirmación [1]
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Correo de confirmación reenviado.'),
                    ),
                  );
                } on AuthException catch (e2) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No se pudo reenviar: ${e2.message}'),
                    ),
                  );
                }
              },
            ),
            duration: const Duration(seconds: 8),
          ),
        ); // aviso de confirmación [1]
        return;
      }

      // Otros errores (incluye "Invalid login credentials")
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      ); // feedback [1]
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> sendPasswordReset() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu e-mail para recuperar la contraseña.'),
        ),
      ); // validación simple [1]
      return;
    }
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
      ); // restablecer contraseña [1]
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Te enviamos un enlace para restablecer tu contraseña.',
          ),
        ),
      ); // éxito [1]
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar recuperación: ${e.message}')),
      ); // error [1]
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg_pattern.png', fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/car.png', height: 180),
                  const SizedBox(height: 20),
                  const Text(
                    'Car Rental',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Viajar, Amar un coche',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color.fromARGB(
                        255,
                        0,
                        0,
                        0,
                      ).withOpacity(0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      labelText: 'E-mail',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) =>
                            setState(() => rememberMe = value ?? false),
                      ),
                      const Text(
                        'Recuerdame',
                        style: TextStyle(color: Colors.black),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: sendPasswordReset,
                        child: const Text(
                          'Recuperar contraseña',
                          style: TextStyle(
                            color: Color.fromARGB(255, 3, 88, 128),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 3, 88, 128),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(color: Color.fromARGB(137, 0, 0, 0)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Ingresa con',
                          style: TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Color.fromARGB(137, 0, 0, 0)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Image.asset('assets/google.png'),
                        iconSize: 40,
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Image.asset('assets/facebook.png'),
                        iconSize: 40,
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Image.asset('assets/apple.png'),
                        iconSize: 40,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistroScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        '¿Aún no tienes cuenta? Registrarme',
                        style: TextStyle(
                          color: Color.fromARGB(255, 3, 88, 128),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
