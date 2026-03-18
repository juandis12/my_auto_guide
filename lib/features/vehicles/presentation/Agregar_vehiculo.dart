// =============================================================================
// Agregar_vehiculo.dart — REGISTRO DE MOTOCICLETAS
// =============================================================================
//
// Pantalla para agregar una nueva motocicleta al sistema. Incluye:
//   - Catálogo visual de motos organizadas por marca (YAMAHA, SUZUKI, BMW,
//     KAWASAKI, BAJAJ, HERO, AKT, KTM) con imágenes reales de cada modelo.
//   - Formulario con campos adaptables a temas claro/oscuro.
//   - Guardado en Supabase con navegación a [InicioApp].
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inicio_app.dart';
import 'Agregar_carro.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/vehicle_catalog_service.dart';

class AgregarVehiculoScreen extends StatefulWidget {
  const AgregarVehiculoScreen({super.key});

  @override
  State<AgregarVehiculoScreen> createState() => _AgregarVehiculoScreenState();
}

class _AgregarVehiculoScreenState extends State<AgregarVehiculoScreen> {
  // Servicios
  final _catalogService = VehicleCatalogService();

  late final Map<String, List<Map<String, String>>> catalogo;
  late final Map<String, String> logos;
  late final Map<String, Color> brandColors;

  String marcaSeleccionada = 'YAMAHA';
  int indexModelo = 0;
  late PageController _page;

  final TextEditingController _kmsController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _apodoController = TextEditingController();

  final supabase = Supabase.instance.client;

  List<Map<String, String>> get modelosDeMarca =>
      catalogo[marcaSeleccionada] ?? const [];

  @override
  void initState() {
    super.initState();
    catalogo = _catalogService.getMotoCatalog();
    logos = _catalogService.getMotoLogos();
    brandColors = _catalogService.getBrandColors();
    _page = PageController(initialPage: indexModelo);
  }

  @override
  void dispose() {
    _page.dispose();
    _kmsController.dispose();
    _modeloController.dispose();
    _apodoController.dispose();
    super.dispose();
  }

  void _cambiarMarca(String marca) {
    if (marcaSeleccionada == marca) return;
    setState(() {
      marcaSeleccionada = marca;
      indexModelo = 0;
      _page.jumpToPage(0);
    });
  }

  Future<void> _guardarVehiculo() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final kms = int.tryParse(_kmsController.text.trim()) ?? 0;
    final apodo = _apodoController.text.trim();
    final modelo =
        modelosDeMarca.isEmpty ? '' : modelosDeMarca[indexModelo]['modelo']!;
    final imagePath =
        modelosDeMarca.isEmpty ? '' : modelosDeMarca[indexModelo]['img']!;

    try {
      final row = await SupabaseService().createVehicle(
        userId: user.id,
        marca: marcaSeleccionada,
        modelo: modelo,
        apodo: apodo,
        kms: kms,
        imagePath: imagePath,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => InicioApp(vehiculoId: row['id'] as String)),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 240;
    final modeloActual =
        modelosDeMarca.isEmpty ? '' : modelosDeMarca[indexModelo]['modelo']!;

    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 0, elevation: 0, backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: headerHeight,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/lineasfondo.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment(-0.20, -0.05),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  'Mi Garaje',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                Text(
                  'Registra tu vehículo para empezar',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: headerHeight,
                  child: Row(
                    children: [
                      Column(
                        children: [
                          _SideTab(
                            text: 'Carro',
                            selected: false,
                            onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AgregarCarroScreen())),
                          ),
                          const _SideTab(text: 'Moto', selected: true),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PageView.builder(
                          controller: _page,
                          itemCount: modelosDeMarca.length,
                          onPageChanged: (i) => setState(() => indexModelo = i),
                          itemBuilder: (context, i) {
                            final img = modelosDeMarca[i]['img']!;
                            return Hero(
                              tag: 'vehicle_main_image', 
                              child: Image.asset(img, fit: BoxFit.contain),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(modeloActual,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: logos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final marca = logos.keys.elementAt(index);
                      final selected = marcaSeleccionada == marca;
                      return GestureDetector(
                        onTap: () => _cambiarMarca(marca),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: selected
                                    ? (brandColors[marca] ?? Colors.blue)
                                        .withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: selected
                                        ? (brandColors[marca] ?? Colors.blue)
                                        : Colors.grey.shade300,
                                    width: 2),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(logos[marca]!,
                                  fit: BoxFit.contain),
                            ),
                            Text(marca,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? (brandColors[marca] ?? Colors.blue)
                                        : Colors.black54)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildField(_kmsController, 'Kilometraje', Icons.speed),
                _buildField(
                    _modeloController, 'Modelo (Año)', Icons.calendar_today),
                _buildField(_apodoController, 'Apodo', Icons.edit),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _guardarVehiculo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF035880),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Crear Vehículo'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller, String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : Colors.black12),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF035880)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _SideTab extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  const _SideTab({required this.text, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 35,
        height: 100,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF035880) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF035880).withOpacity(0.3)),
        ),
        child: RotatedBox(
            quarterTurns: 3,
            child: Center(
                child: Text(text,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold)))),
      ),
    );
  }
}
