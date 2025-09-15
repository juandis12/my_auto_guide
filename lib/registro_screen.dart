import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({Key? key}) : super(key: key);

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;

  // Estados para confirmación
  bool waitingForConfirm = false;
  int secondsLeft = 60;
  bool canSwitchEmail = false;
  Timer? _timer;

  Future<void> signUp() async {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1) Crear cuenta (con confirmación de email activada no hay sesión hasta confirmar)
      await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: password,
      );

      // 2) Aviso con opción de reenviar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Registro enviado. Revisa tu correo y confirma la cuenta para continuar.',
          ),
          action: SnackBarAction(
            label: 'Reenviar',
            onPressed: () async {
              try {
                await supabase.auth.resend(
                  type: OtpType.signup,
                  email: emailController.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Correo reenviado. Revisa tu bandeja.'),
                  ),
                );
              } on AuthException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al reenviar: ${e.message}')),
                );
              }
            },
          ),
          duration: const Duration(seconds: 8),
        ),
      );

      // 3) Espera de confirmación: 60 s con reintentos de login
      _startConfirmationWatch(
        email: emailController.text.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      // Manejo “correo ya registrado”: ofrecer reenviar
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('already') || msg.contains('exists')) {
        try {
          await supabase.auth.resend(
            type: OtpType.signup,
            email: emailController.text.trim(),
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Este correo ya existe pero puede no estar confirmado. Revisa tu bandeja o usa “Reenviar”.',
              ),
            ),
          );
          setState(() {
            waitingForConfirm = true;
            secondsLeft = 60;
            canSwitchEmail = false;
          });
          _startConfirmationWatch(
            email: emailController.text.trim(),
            password: password,
          );
        } on AuthException catch (e2) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al reenviar: ${e2.message}')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de autenticación: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startConfirmationWatch({
    required String email,
    required String password,
  }) {
    setState(() {
      waitingForConfirm = true;
      secondsLeft = 60;
      canSwitchEmail = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      setState(() => secondsLeft--);

      // Intento de login cada 5s para detectar confirmación
      if (secondsLeft % 5 == 0 && secondsLeft > 0) {
        try {
          final res = await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          if (res.session != null && res.user != null) {
            t.cancel();
            if (!mounted) return;
            setState(() {
              waitingForConfirm = false;
              canSwitchEmail = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Correo verificado. Inicia sesión para continuar.',
                ),
              ),
            );
            Navigator.pop(context); // Volver al login
            return;
          }
        } on AuthException {
          // Seguir esperando; no saturar de mensajes
        }
      }

      if (secondsLeft <= 0) {
        t.cancel();
        if (!mounted) return;
        setState(() {
          canSwitchEmail = true;
          waitingForConfirm = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se confirmó el correo en 60 s. Puedes usar otro correo.',
            ),
          ),
        );
      }
    });
  }

  void _switchToAnotherEmail() {
    _timer?.cancel();
    supabase.auth.signOut(); // seguro aunque no haya sesión
    setState(() {
      waitingForConfirm = false;
      canSwitchEmail = false;
      secondsLeft = 60;
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    nombreController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg_pattern.png', fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/car.png', height: 180),
                  const SizedBox(height: 20),
                  const Text(
                    'Registrarme',
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
                    'Crea tu cuenta',
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

                  if (waitingForConfirm)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirma tu correo para continuar',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tiempo restante: $secondsLeft s',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await supabase.auth.resend(
                                      type: OtpType.signup,
                                      email: emailController.text.trim(),
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Correo reenviado. Revisa tu bandeja.',
                                        ),
                                      ),
                                    );
                                  } on AuthException catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error al reenviar: ${e.message}',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Reenviar correo'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: canSwitchEmail
                                    ? _switchToAnotherEmail
                                    : null,
                                child: const Text('Usar otro correo'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  TextField(
                    controller: nombreController,
                    enabled: !waitingForConfirm,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      labelText: 'Nombre',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: emailController,
                    enabled: !waitingForConfirm || canSwitchEmail,
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
                    enabled: !waitingForConfirm || canSwitchEmail,
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
                  const SizedBox(height: 18),
                  TextField(
                    controller: confirmPasswordController,
                    enabled: !waitingForConfirm || canSwitchEmail,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      labelText: 'Confirmar Contraseña',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (isLoading || waitingForConfirm)
                          ? null
                          : signUp,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Registrarme'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 3, 88, 128),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
