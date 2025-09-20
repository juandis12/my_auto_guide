import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inicio_app.dart'; // Asegura la ruta real de tu pantalla de inicio

class AgregarVehiculoScreen extends StatefulWidget {
  const AgregarVehiculoScreen({Key? key}) : super(key: key);

  @override
  State<AgregarVehiculoScreen> createState() => _AgregarVehiculoScreenState();
}

class _AgregarVehiculoScreenState extends State<AgregarVehiculoScreen> {
  // Catálogo por marca (igual que tenías)
  final Map<String, List<Map<String, String>>> catalogo = {
    'YAMAHA': [
      {'modelo': 'MT 15', 'img': 'assets/motos/yamaha/mt15.png'},
      {'modelo': 'R15', 'img': 'assets/motos/yamaha/r15.png'},
      {'modelo': 'FZ 25', 'img': 'assets/motos/yamaha/fz25.png'},
      {'modelo': 'CRYPTON FI', 'img': 'assets/motos/yamaha/cripton.png'},
      {'modelo': 'FZ 2.0', 'img': 'assets/motos/yamaha/fz2.0.png'},
      {'modelo': 'N-MAX', 'img': 'assets/motos/yamaha/nmax.png'},
      {'modelo': 'XTZ 150', 'img': 'assets/motos/yamaha/XTZ150.png'},
    ],
    'SUZUKI': [
      {'modelo': 'Gixxer 150 FI', 'img': 'assets/motos/suzuki/gixxer150.png'},
      {
        'modelo': 'Gixxer SF 150 FI',
        'img': 'assets/motos/suzuki/gixxersf150.png',
      },
    ],
    'BMW': [
      {'modelo': 'G 310 R', 'img': 'assets/motos/bmw/g310r.png'},
      {'modelo': 'G 310 GS', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'F 900 R', 'img': 'assets/motos/bmw/f900r.png'},
    ],
    'KAWASAKI': [
      {'modelo': 'VERSYS 650', 'img': 'assets/motos/kawasaki/versys650.png'},
      {'modelo': 'Ninja 650', 'img': 'assets/motos/kawasaki/ninja650.png'},
      {'modelo': 'Ninja 400', 'img': 'assets/motos/kawasaki/ninja400.png'},
      {'modelo': 'Z 400', 'img': 'assets/motos/kawasaki/z400.png'},
    ],

    'BAJAJ': [
      {
        'modelo': 'BOXER CT 100 KS',
        'img': 'assets/motos/bajaj/boxer-ct100-ks.png',
      },
      {
        'modelo': 'BOXER CT 100 ES',
        'img': 'assets/motos/bajaj/boxer-ct100.png',
      },
      {
        'modelo': 'BOXER CT 125 SPORT',
        'img': 'assets/motos/bajaj/boxer-ct-125-sport.png',
      },
      {'modelo': 'BOXER 150 X', 'img': 'assets/motos/bajaj/boxer-150x.png'},
      {'modelo': 'BOXER S', 'img': 'assets/motos/bajaj/boxer-s.png'},
      {
        'modelo': 'DISCOVER 125 SPORT',
        'img': 'assets/motos/bajaj/discover-125.png',
      },
      {'modelo': 'DOMINAR 250', 'img': 'assets/motos/bajaj/Dominar-250.png'},
      {
        'modelo': 'DOMINAR 400',
        'img': 'assets/motos/bajaj/Dominar-400-touring.png',
      },
      {
        'modelo': 'DOMINAR 400 VOLCANO',
        'img': 'assets/motos/bajaj/dominar400-volcano.png',
      },
      {'modelo': 'PULSAR N125', 'img': 'assets/motos/bajaj/pulsar-n125.png'},
      {
        'modelo': 'PULSAR N160 PRO',
        'img': 'assets/motos/bajaj/pulsar-n160-pro.png',
      },
      {'modelo': 'PULSAR N160', 'img': 'assets/motos/bajaj/pulsar-n160.png'},
      {'modelo': 'PULSAR N250', 'img': 'assets/motos/bajaj/Pulsar-N250.png'},
      {
        'modelo': 'PULSAR NS125 ',
        'img': 'assets/motos/bajaj/pulsar-ns-125.png',
      },
      {
        'modelo': 'PULSAR NS 160 FI ABS ',
        'img': 'assets/motos/bajaj/pulsar-ns-160-fi-abs.png',
      },
      {
        'modelo': 'PULSAR NS 16O',
        'img': 'assets/motos/bajaj/pulsar-ns160-fi.png',
      },
      {
        'modelo': 'PULSAR NS 200 UG',
        'img': 'assets/motos/bajaj/pulsar-ns-200-ug.png',
      },
      {
        'modelo': 'PULSAR NS 200 FI ABS',
        'img': 'assets/motos/bajaj/pulsar-ns200-fi-abs.png',
      },
      {
        'modelo': 'PULSAR NS 400z',
        'img': 'assets/motos/bajaj/pulsar-ns400z.png',
      },
      {'modelo': 'PULSAR P 150 ', 'img': 'assets/motos/bajaj/Pulsar-p150.png'},
      {
        'modelo': 'PULSAR RS 200 FI ABS',
        'img': 'assets/motos/bajaj/pulsar-rs200.png',
      },
      {
        'modelo': 'PULSAR 200 PULSARMANIA',
        'img': 'assets/motos/bajaj/pulsarmania.png',
      },
    ],
    'HERO': [
      {'modelo': 'HUNK 125 R', 'img': 'assets/motos/hero/Hunk125r.png'},
      {'modelo': 'HUNK 150 XT', 'img': 'assets/motos/hero/Hunk150xt.png'},
      {'modelo': 'HUNK 160 R', 'img': 'assets/motos/hero/hunk160r.png'},
      {'modelo': 'HUNK 160 R 4V', 'img': 'assets/motos/hero/Hunk160R4v.png'},
      {'modelo': 'ECO DELUXE', 'img': 'assets/motos/hero/Eco_Deluxe.png'},
      {'modelo': 'ECO T ', 'img': 'assets/motos/hero/ECO-T.png'},
      {'modelo': 'ECO 100', 'img': 'assets/motos/hero/Eco100.png'},
      {
        'modelo': 'ECO DELUXE CLASICA',
        'img': 'assets/motos/hero/EcoDeluxeClasica.png',
      },
      {'modelo': 'IGNITOR', 'img': 'assets/motos/hero/Ignitor.png'},
      {'modelo': 'IGNITOR XTECH', 'img': 'assets/motos/hero/IgnitorXtech.png'},
      {
        'modelo': 'SPLENDOR X PRO',
        'img': 'assets/motos/hero/Splendor-Xpro.png',
      },
      {'modelo': 'XOOM 110', 'img': 'assets/motos/hero/Xoom110.png'},
      {'modelo': 'X PULSE 200 4V', 'img': 'assets/motos/hero/Xpulse2004v.png'},
      {
        'modelo': 'X PULSE 200 PRO 4V',
        'img': 'assets/motos/hero/XpulsePro2004v.png',
      },
      {
        'modelo': 'X PULSE 200 RALLY',
        'img': 'assets/motos/hero/XpulseRally.png',
      },
    ],
    'AKT': [
      {'modelo': 'CR 250R ', 'img': 'assets/motos/akt/250R.png'},
      {'modelo': 'CR4 150', 'img': 'assets/motos/akt/CR4_150.png'},
      {'modelo': 'CR4 200', 'img': 'assets/motos/akt/CR4_200.png'},
      {'modelo': 'NKD', 'img': 'assets/motos/akt/NKD.png'},
      {'modelo': 'MAWI', 'img': 'assets/motos/akt/mawi.png'},
      {'modelo': 'SPECIAL X', 'img': 'assets/motos/akt/AKT19O.png'},
    ],
    'KTM': [
      {'modelo': 'DUKE 200 ', 'img': 'assets/motos/ktm/DUKE-200.png'},
      {'modelo': 'DUKE 250', 'img': 'assets/motos/ktm/KTM-250-DUKE.png'},
      {'modelo': 'DUKE 390', 'img': 'assets/motos/ktm/KTM-390-DUKE.png'},
      {'modelo': 'DUKE 990', 'img': 'assets/motos/ktm/KTM-990-DUKE.png'},
      {
        'modelo': 'SUPER DUKE 1390',
        'img': 'assets/motos/ktm/KTM1390superduke2025.png',
      },
      {
        'modelo': 'ADVENTUR 250',
        'img': 'assets/motos/ktm/KTM-250-Adventure.png',
      },
      {'modelo': 'ADVENTUR 390', 'img': 'assets/motos/ktm/KTM-390-adv.png'},
      {
        'modelo': 'ADVENTUR 390X',
        'img': 'assets/motos/ktm/KTM-390-adventure.png',
      },
    ],
  }; // PageView.builder consumirá la lista de la marca seleccionada.

  // Logos para selección de marca
  final Map<String, String> logos = const {
    'YAMAHA': 'assets/logos/yamaha_logo.png',
    'SUZUKI': 'assets/logos/suzuki_logo.png',
    'BMW': 'assets/logos/bmw_logo.png',
    'KAWASAKI': 'assets/logos/kawa_logo.png',
    'HONDA': 'assets/logos/honda_logo.png',
    'KTM': 'assets/logos/ktm_logo.png',
    'BAJAJ': 'assets/logos/bajaj_logo.png',
    'DUCATI': 'assets/logos/ducati_logo.png',
    'HERO': 'assets/logos/hero_logo.png',
    'AKT': 'assets/logos/akt_logo.png',
  }; // Las rutas deben existir en assets/logos/.

  // COLORES POR MARCA (personaliza a tu gusto)
  final Map<String, Color> brandColors = const {
    'YAMAHA': Color(0xFF0055CC), // azul Yamaha
    'SUZUKI': Color(0xFFE30613), // rojo Suzuki
    'BMW': Color(0xFF2A2A2A), // gris/negro BMW
    'KAWASAKI': Color(0xFF00A651), // verde Kawasaki
    'HONDA': Color(0xFFB30101), // rojo oscuro Honda
    'DUCATI': Color(0xFFEB2A11), // rojo anaranjado Ducati
    'KTM': Color(0xFFFF7B00), // naranja KTM
    'BAJAJ': Color(0xFF006EFF), // azul claro Bajaj
    'HERO': Color.fromARGB(255, 0, 0, 0),
    'AKT': Color.fromARGB(255, 21, 54, 172),
  }; // Usa cualquier Color(Material) o hex ARGB para el resaltado.

  // Estado actual
  String marcaSeleccionada = 'YAMAHA';
  int indexModelo = 0;

  // Controlador del carrusel
  late PageController _page;

  // Form
  final TextEditingController _kmsController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _apodoController = TextEditingController();

  // Supabase
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

  // Guardar en Supabase y navegar a inicio_app.dart
  Future<void> _guardarVehiculo() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
      return;
    } // usuario autenticado

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
        const SnackBar(content: Text('Selecciona una moto válida')),
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
          .single(); // devuelve la fila creada

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
          // Fondo superior
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
                  'Agrega Tu Vehiculo',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Header: tabs + carrusel por marca
                SizedBox(
                  height: headerHeight,
                  width: double.infinity,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tabs verticales (decorativos)
                      SizedBox(
                        height: headerHeight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            _SideTab(
                              text: 'Carro',
                              selected: false,
                              onTap: null,
                            ),
                            SizedBox(height: 7),
                            _SideTab(text: 'Moto', selected: true, onTap: null),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Carrusel de modelos de la marca seleccionada
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
                            // Flechas
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

                // Logos por marca con color de selección específico
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
                    hintText: '6500',
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
                    hintText: '2024',
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
                    hintText: 'Demon',
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
                    child: const Text('Crear Vehiculo'),
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

// Botón vertical de barra lateral (sin cambios de lógica)
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
