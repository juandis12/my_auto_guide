// =============================================================================
// vehicle_registration_view.dart — REGISTRO DE VEHÍCULOS (MOTOS Y CARROS)
// =============================================================================
//
// Pantalla compartida por el registro de motocicletas y el de automóviles.
// Ambos flujos son idénticos salvo el catálogo, la marca por defecto y los
// textos, por lo que se parametrizan mediante [VehicleKind]:
//   - Catálogo visual por marca con carrusel deslizable (PageView).
//   - Selector horizontal de marcas con logos y colores personalizados.
//   - Formulario: placa, cédula, kilometraje, modelo (año) y apodo.
//   - Tabs laterales «Carro / Moto» para alternar entre ambos registros.
//   - Guardado en la tabla `vehiculos` de Supabase y navegación a [InicioApp].
//
// Widgets auxiliares:
//   - [_SideTab]: Botón vertical rotado para los tabs «Carro / Moto».
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/vehicle_catalog_service.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../inicio_app.dart';

/// Tipo de vehículo que se está registrando.
enum VehicleKind { moto, carro }

extension VehicleKindData on VehicleKind {
  String get label => this == VehicleKind.moto ? 'Moto' : 'Carro';

  String get defaultBrand => this == VehicleKind.moto ? 'YAMAHA' : 'TOYOTA';

  String get plateLabel =>
      this == VehicleKind.moto ? 'Placa de la moto' : 'Placa del carro';

  String get submitLabel =>
      this == VehicleKind.moto ? 'Crear Vehículo' : 'Crear Carro';

  String get invalidSelectionMessage => this == VehicleKind.moto
      ? 'Selecciona una moto válida'
      : 'Selecciona un carro válido';

  VehicleKind get other =>
      this == VehicleKind.moto ? VehicleKind.carro : VehicleKind.moto;
}

class VehicleRegistrationView extends StatefulWidget {
  final VehicleKind kind;

  const VehicleRegistrationView({super.key, required this.kind});

  @override
  State<VehicleRegistrationView> createState() =>
      _VehicleRegistrationViewState();
}

class _VehicleRegistrationViewState extends State<VehicleRegistrationView> {
  // Servicios
  final _catalogService = VehicleCatalogService();

  late final Map<String, List<Map<String, String>>> catalogo;
  late final Map<String, String> logos;
  late final Map<String, Color> brandColors;

  late String marcaSeleccionada;
  int indexModelo = 0;
  late PageController _page;

  final TextEditingController _kmsController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _apodoController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();

  final supabase = Supabase.instance.client;

  List<Map<String, String>> get modelosDeMarca =>
      catalogo[marcaSeleccionada] ?? const [];

  @override
  void initState() {
    super.initState();
    final isMoto = widget.kind == VehicleKind.moto;
    catalogo = isMoto
        ? _catalogService.getMotoCatalog()
        : _catalogService.getCarCatalog();
    logos =
        isMoto ? _catalogService.getMotoLogos() : _catalogService.getCarLogos();
    brandColors = _catalogService.getBrandColors();
    marcaSeleccionada = widget.kind.defaultBrand;
    _page = PageController(initialPage: indexModelo);
  }

  @override
  void dispose() {
    _page.dispose();
    _kmsController.dispose();
    _modeloController.dispose();
    _apodoController.dispose();
    _placaController.dispose();
    _cedulaController.dispose();
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

  // Guardar en Supabase y navegar
  Future<void> _guardarVehiculo() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      AppSnackBar.show(context, 'Debes iniciar sesión');
      return;
    }

    final kms = int.tryParse(_kmsController.text.trim()) ?? 0;
    final apodo = _apodoController.text.trim();
    final placa = _placaController.text.trim().toUpperCase();
    final cedula = _cedulaController.text.trim();
    final modelo =
        modelosDeMarca.isEmpty ? '' : modelosDeMarca[indexModelo]['modelo']!;
    final imagePath =
        modelosDeMarca.isEmpty ? '' : modelosDeMarca[indexModelo]['img']!;

    if (placa.isEmpty) {
      AppSnackBar.show(context, 'Por favor ingresa la ${widget.kind.plateLabel.toLowerCase()}');
      return;
    }
    if (cedula.isEmpty) {
      AppSnackBar.show(context, 'Por favor ingresa la cédula del propietario');
      return;
    }
    if (modelo.isEmpty || imagePath.isEmpty) {
      AppSnackBar.show(context, widget.kind.invalidSelectionMessage);
      return;
    }

    try {
      final row = await SupabaseService().createVehicle(
        userId: user.id,
        marca: marcaSeleccionada,
        modelo: modelo,
        apodo: apodo,
        kms: kms,
        imagePath: imagePath,
        placa: placa,
        cedula: cedula,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InicioApp(vehiculoId: row['id'] as String),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Error al guardar: ${e.message}');
    }
  }

  void _irAOtroRegistro() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleRegistrationView(kind: widget.kind.other),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 240;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/lineasfondo.png'),
                  fit: BoxFit.cover,
                  alignment: const Alignment(-0.20, -0.05),
                  colorFilter: isDark
                      ? ColorFilter.mode(
                          Colors.black.withOpacity(0.85), BlendMode.darken)
                      : null,
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
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Registra tu vehículo para empezar',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
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
                            selected: widget.kind == VehicleKind.carro,
                            onTap: widget.kind == VehicleKind.carro
                                ? null
                                : _irAOtroRegistro,
                          ),
                          _SideTab(
                            text: 'Moto',
                            selected: widget.kind == VehicleKind.moto,
                            onTap: widget.kind == VehicleKind.moto
                                ? null
                                : _irAOtroRegistro,
                          ),
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
                      final brandColor = brandColors[marca] ?? Colors.blue;
                      return GestureDetector(
                        onTap: () => _cambiarMarca(marca),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: selected
                                    ? brandColor.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: selected
                                        ? brandColor
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
                                        ? brandColor
                                        : Colors.black54)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildField(
                    _placaController, widget.kind.plateLabel, Icons.tag),
                _buildField(
                    _cedulaController, 'Cédula del propietario', Icons.badge),
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
                    child: Text(widget.kind.submitLabel),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
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
