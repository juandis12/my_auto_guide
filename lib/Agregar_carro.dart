import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inicio_app.dart';
import 'Agregar_vehiculo.dart';

class AgregarCarroScreen extends StatefulWidget {
  const AgregarCarroScreen({Key? key}) : super(key: key);

  @override
  State<AgregarCarroScreen> createState() => _AgregarCarroScreenState();
}

class _AgregarCarroScreenState extends State<AgregarCarroScreen> {
  // Catálogo de carros
  final Map<String, List<Map<String, String>>> catalogo = {
    'TOYOTA': [
      {'modelo': 'Corolla', 'img': 'assets/carros/toyota/corolla.png'},
      {'modelo': 'Hilux', 'img': 'assets/carros/toyota/hilux.png'},
      {'modelo': 'YARIS', 'img': 'assets/carros/toyota/yaris.png'},
      {'modelo': 'YARIS CROSS', 'img': 'assets/carros/toyota/yaris_cross.png'},
      {'modelo': 'TUNDRA', 'img': 'assets/carros/toyota/tundra.png'},
      {
        'modelo': 'LAND CRUISER 300',
        'img': 'assets/carros/toyota/landcruiser300.png',
      },
      {'modelo': 'HILUX CARGA', 'img': 'assets/carros/toyota/hiluxcarga.png'},
      {'modelo': 'FORTUNER', 'img': 'assets/carros/toyota/fortuner.png'},
      {
        'modelo': 'COROLLA CROSS',
        'img': 'assets/carros/toyota/corolla_cross.png',
      },
      {
        'modelo': 'COROLLA CROSS GR-S',
        'img': 'assets/carros/toyota/corolla_cross_gr-s.png',
      },
    ],
    'MAZDA': [
      {'modelo': 'MAZDA 2 HATCHBACK', 'img': 'assets/carros/mazda/mazda2.png'},
      {'modelo': 'MAZDA 2 SEDAN', 'img': 'assets/carros/mazda/mazda2sedan.png'},
      {'modelo': 'MAZDA 3 SEDAN', 'img': 'assets/carros/mazda/mazda3.png'},
    ],
    'CHEVROLET': [
      {'modelo': 'Onix', 'img': 'assets/carros/chevrolet/onix.png'},
      {'modelo': 'Tracker', 'img': 'assets/carros/chevrolet/tracker.png'},
    ],
  };

  // Logos
  final Map<String, String> logos = const {
    'TOYOTA': 'assets/logos/toyota_logo.png',
    'MAZDA': 'assets/logos/mazda_logo.png',
    'CHEVROLET': 'assets/logos/chevrolet_logo.png',
  };

  // Colores
  final Map<String, Color> brandColors = const {
    'TOYOTA': Color(0xFFEB0A1E),
    'MAZDA': Color(0xFF1B1B1B),
    'CHEVROLET': Color(0xFFFFC107),
  };

  String marcaSeleccionada = 'TOYOTA';
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

  void _irSiguiente() {
    final next = (indexModelo + 1).clamp(0, modelosDeMarca.length - 1);
    _page.animateToPage(
      next,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _irAnterior() {
    final prev = (indexModelo - 1).clamp(0, modelosDeMarca.length - 1);
    _page.animateToPage(
      prev,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Guardar en Supabase y navegar
  Future<void> _guardarVehiculo() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
      return;
    }

    final kms = int.tryParse(_kmsController.text.trim()) ?? 0;
    final apodo = _apodoController.text.trim();
    final modelo = modelosDeMarca.isEmpty
        ? ''
        : modelosDeMarca[indexModelo]['modelo']!;
    final imagePath = modelosDeMarca.isEmpty
        ? ''
        : modelosDeMarca[indexModelo]['img']!;

    if (modelo.isEmpty || imagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un carro válido')),
      );
      return;
    }

    try {
      final row = await supabase
          .from('vehiculos')
          .insert({
            'user_id': user.id,
            'marca': marcaSeleccionada,
            'modelo': modelo,
            'apodo': apodo,
            'kms': kms,
            'image_path': imagePath,
          })
          .select()
          .single();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InicioApp(vehiculoId: row['id'] as String),
        ),
      );
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 240;
    final modeloActual = modelosDeMarca.isEmpty
        ? ''
        : modelosDeMarca[indexModelo]['modelo']!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Fondo
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
          // Contenido
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Agrega Tu Carro',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Header
                SizedBox(
                  height: headerHeight,
                  width: double.infinity,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tabs
                      SizedBox(
                        height: headerHeight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _SideTab(
                              text: 'Carro',
                              selected: true,
                              onTap: null,
                            ),
                            const SizedBox(),
                            _SideTab(
                              text: 'Moto',
                              selected: false,
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AgregarVehiculoScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Carrusel
                      Expanded(
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _page,
                              itemCount: modelosDeMarca.length,
                              onPageChanged: (i) =>
                                  setState(() => indexModelo = i),
                              itemBuilder: (context, i) {
                                final img = modelosDeMarca[i]['img']!;
                                return Center(
                                  child: Image.asset(
                                    img,
                                    fit: BoxFit.contain,
                                    height: double.infinity,
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: IconButton(
                                onPressed: _irSiguiente,
                                icon: const Icon(Icons.chevron_right),
                                color: Colors.black54,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 6,
                              top: 6,
                              child: IconButton(
                                onPressed: _irAnterior,
                                icon: const Icon(Icons.chevron_left),
                                color: Colors.black54,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  modeloActual,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),

                // Logos
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    itemBuilder: (context, index) {
                      final marca = logos.keys.elementAt(index);
                      final selected = marcaSeleccionada == marca;
                      final logoPath = logos[marca]!;
                      final highlight = brandColors[marca] ?? Colors.blue;

                      return GestureDetector(
                        onTap: () => _cambiarMarca(marca),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: selected
                                    ? highlight.withOpacity(0.10)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? highlight
                                      : Colors.grey.shade300,
                                  width: selected ? 2.5 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(logoPath, fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              marca,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? highlight
                                        : Colors.black87,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemCount: logos.length,
                  ),
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _kmsController,
                  decoration: const InputDecoration(
                    labelText: 'Cuantos kms tiene?',
                    hintText: '25000',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 14),
                TextFormField(
                  controller: _modeloController,
                  decoration: const InputDecoration(
                    labelText: 'Modelo (año)',
                    hintText: '2022',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 14),
                TextFormField(
                  controller: _apodoController,
                  decoration: const InputDecoration(
                    labelText: 'Apodo',
                    hintText: 'Mi Nave',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),

                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _guardarVehiculo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontSize: 17),
                    ),
                    child: const Text('Crear Carro'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Botón lateral
class _SideTab extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  const _SideTab({
    Key? key,
    required this.text,
    required this.selected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.blue : Colors.white;
    final fg = selected ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 120,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              text,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
