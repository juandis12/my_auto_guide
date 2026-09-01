import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_apple_theme.dart';
import '../data/models/motorcycle_manual_model.dart';
import '../data/repositories/motorcycle_manuals_repository.dart';

class ManualesScreen extends StatefulWidget {
  final String? initialMake;
  final String? initialModel;

  const ManualesScreen({
    super.key,
    this.initialMake,
    this.initialModel,
  });

  @override
  State<ManualesScreen> createState() => _ManualesScreenState();
}

class _ManualesScreenState extends State<ManualesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MotorcycleManualsRepository _repository = MotorcycleManualsRepository();

  List<MotorcycleManual> _manuals = [];
  bool _isLoading = true;
  String _selectedBrand = 'Todas';

  final List<String> _popularBrands = [
    'Todas', 'Yamaha', 'Honda', 'Suzuki', 'Kawasaki', 'Bajaj',
    'KTM', 'BMW', 'Ducati', 'Royal Enfield', 'TVS', 'Hero',
    'Benelli', 'Husqvarna', 'Aprilia', 'Triumph'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialMake != null && widget.initialMake!.isNotEmpty) {
      _selectedBrand = widget.initialMake!;
    }
    if (widget.initialModel != null && widget.initialModel!.isNotEmpty) {
      _searchController.text = widget.initialModel!;
    }
    _fetchManuals();
  }

  Future<void> _fetchManuals() async {
    setState(() => _isLoading = true);
    final results = await _repository.searchManuals(
      make: _selectedBrand == 'Todas' ? null : _selectedBrand,
      query: _searchController.text.trim(),
      limit: 100,
    );
    if (mounted) {
      setState(() {
        _manuals = results;
        _isLoading = false;
      });
    }
  }

  void _onBrandSelected(String brand) {
    HapticFeedback.selectionClick();
    setState(() => _selectedBrand = brand);
    _fetchManuals();
  }

  void _onSearchChanged(String query) {
    _fetchManuals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppAppleTheme.midnightBackground : const Color(0xFFF2F5F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ─── APPLE LARGE TITLE APP BAR ───────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: (isDark ? AppAppleTheme.midnightBackground : Colors.white)
                .withValues(alpha: 0.85),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppAppleTheme.glassBlurSigma,
                  sigmaY: AppAppleTheme.glassBlurSigma,
                ),
                child: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
                  title: Text(
                    'Manuales & Fichas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── BARRA DE BÚSQUEDA Y CHIPS DE MARCAS ──────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar Estilo iOS
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar por modelo (ej: MT-09, Duke 390, Pulsar)...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(CupertinoIcons.search, size: 20, color: Color(0xFF00FF87)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchManuals();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Carrusel Horizontal de Marcas
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _popularBrands.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final brand = _popularBrands[index];
                        final isSelected = _selectedBrand.toLowerCase() == brand.toLowerCase();
                        return GestureDetector(
                          onTap: () => _onBrandSelected(brand),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00FF87)
                                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00FF87)
                                    : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                brand,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.black
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── LISTADO DE MANUALES Y FICHAS TÉCNICAS ─────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CupertinoActivityIndicator(radius: 14),
              ),
            )
          else if (_manuals.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.book,
                      size: 54,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No se encontraron manuales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Intenta buscar con otra marca o modelo',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final manual = _manuals[index];
                    return _buildManualCard(context, manual, isDark);
                  },
                  childCount: _manuals.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManualCard(BuildContext context, MotorcycleManual manual, bool isDark) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppAppleTheme.glassBlurSigma,
              sigmaY: AppAppleTheme.glassBlurSigma,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showManualDetailsModal(context, manual),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera: Marca, Modelo y Año
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF87).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.two_wheeler_rounded,
                              color: Color(0xFF00FF87),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${manual.make} ${manual.model}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Modelo ${manual.year} • ${manual.type ?? "Estándar"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              manual.displacement ?? 'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF00FF87) : const Color(0xFF0F766E),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Grid de Especificaciones Clave
                      Row(
                        children: [
                          _buildSpecPill(
                            icon: Icons.flash_on_rounded,
                            label: 'Potencia',
                            value: manual.power != null ? manual.power!.split('@').first.trim() : 'N/A',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildSpecPill(
                            icon: Icons.speed_rounded,
                            label: 'Torque',
                            value: manual.torque != null ? manual.torque!.split('@').first.trim() : 'N/A',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildSpecPill(
                            icon: Icons.local_gas_station_rounded,
                            label: 'Tanque',
                            value: manual.fuelCapacity != null ? manual.fuelCapacity!.split('(').first.trim() : 'N/A',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecPill({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: const Color(0xFF00FF87)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualDetailsModal(BuildContext context, MotorcycleManual manual) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B111E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              // Indicador de arrastre superior
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Cabecera Modal
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${manual.make} ${manual.model}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Ficha Técnica y Manual • Año ${manual.year}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF00FF87),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 28),
                      color: isDark ? Colors.white38 : Colors.black38,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Detalle de especificaciones
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSectionHeader('⚙️ Motor y Rendimiento', isDark),
                    _buildDetailRow('Cilindraje', manual.displacement, isDark),
                    _buildDetailRow('Tipo de Motor', manual.engine, isDark),
                    _buildDetailRow('Potencia', manual.power, isDark),
                    _buildDetailRow('Torque', manual.torque, isDark),
                    _buildDetailRow('Compresión', manual.compression, isDark),
                    _buildDetailRow('Válvulas x Cilindro', manual.valvesPerCylinder, isDark),
                    _buildDetailRow('Refrigeración', manual.cooling, isDark),
                    _buildDetailRow('Lubricación', manual.lubrication, isDark),
                    _buildDetailRow('Arranque', manual.starter, isDark),

                    const SizedBox(height: 20),
                    _buildSectionHeader('⛽ Combustible y Transmisión', isDark),
                    _buildDetailRow('Sistema de Combustible', manual.fuelSystem, isDark),
                    _buildDetailRow('Capacidad Tanque', manual.fuelCapacity, isDark),
                    _buildDetailRow('Consumo Promedio', manual.fuelConsumption, isDark),
                    _buildDetailRow('Caja de Cambios', manual.gearbox, isDark),
                    _buildDetailRow('Transmisión Final', manual.transmission, isDark),
                    _buildDetailRow('Embrague', manual.clutch, isDark),

                    const SizedBox(height: 20),
                    _buildSectionHeader('🛠️ Chasis, Frenos y Llantas', isDark),
                    _buildDetailRow('Chasis', manual.frame, isDark),
                    _buildDetailRow('Suspensión Delantera', manual.frontSuspension, isDark),
                    _buildDetailRow('Suspensión Trasera', manual.rearSuspension, isDark),
                    _buildDetailRow('Frenos Delanteros', manual.frontBrakes, isDark),
                    _buildDetailRow('Frenos Traseros', manual.rearBrakes, isDark),
                    _buildDetailRow('Llanta Delantera', manual.frontTire, isDark),
                    _buildDetailRow('Llanta Trasera', manual.rearTire, isDark),

                    const SizedBox(height: 20),
                    _buildSectionHeader('📏 Dimensiones y Peso', isDark),
                    _buildDetailRow('Peso Total', manual.totalWeight, isDark),
                    _buildDetailRow('Peso Seco', manual.dryWeight, isDark),
                    _buildDetailRow('Altura Asiento', manual.seatHeight, isDark),
                    _buildDetailRow('Distancia al Suelo', manual.groundClearance, isDark),
                    _buildDetailRow('Distancia entre Ejes', manual.wheelbase, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: isDark ? const Color(0xFF00FF87) : const Color(0xFF0F766E),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, bool isDark) {
    if (value == null || value.trim().isEmpty || value == 'null') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
