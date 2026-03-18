// =============================================================================
// gastos_screen.dart — GESTIÓN FINANCIERA DEL VEHÍCULO
// =============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/logic/vehicle_expenses_logic.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/logic/pdf_report_logic.dart';
import '../../../core/logic/performance_guard.dart';

class GastosScreen extends StatefulWidget {
  final String vehiculoId;
  final String apodo;
  final String marcaModelo;
  final String? brandLogoPath;
  final String? vehicleImagePath;
  const GastosScreen({
    super.key,
    required this.vehiculoId,
    required this.apodo,
    required this.marcaModelo,
    this.brandLogoPath,
    this.vehicleImagePath,
  });

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final data = await SupabaseService().getExpenses(widget.vehiculoId);
      if (!mounted) return;
      
      setState(() {
        _expenses = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showAddExpenseDialog() {
    String? selectedCategory = VehicleExpensesLogic.categories[0].label;
    final montoController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Registrar Gasto',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: VehicleExpensesLogic.categories.map((c) {
                  return DropdownMenuItem(value: c.label, child: Text(c.label));
                }).toList(),
                onChanged: (v) => setM(() => selectedCategory = v),
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: montoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monto (COP)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () async {
                    if (montoController.text.isEmpty) return;
                    await SupabaseService().addExpense(
                      vehicleId: widget.vehiculoId,
                      categoria: selectedCategory!,
                      monto: double.parse(montoController.text),
                      descripcion: descController.text,
                    );
                    Navigator.pop(ctx);
                    _fetchExpenses();
                  },
                  child: const Text('Guardar Gasto',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = VehicleExpensesLogic.groupByValues(_expenses);
    final total = VehicleExpensesLogic.calculateTotal(_expenses);
    final segments = VehicleExpensesLogic.getDonutSegments(grouped);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Gastos'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Exportar Reporte',
            onPressed: () {
              PdfReportLogic.generateAndShareExpenseReport(
                vehiculoApodo: widget.apodo,
                marcaModelo: widget.marcaModelo,
                expenses: _expenses,
                brandLogoPath: widget.brandLogoPath,
                vehicleImagePath: widget.vehicleImagePath,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        label: const Text('Añadir Gasto'),
        icon: const Icon(Icons.add_rounded),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? _BuildEmptyState(onAdd: _showAddExpenseDialog)
              : ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    // --- SECCIÓN GRÁFICO (DASHBOARD) ---
                    _BuildFinancialDashboard(
                        total: total, segments: segments, grouped: grouped),
                    const SizedBox(height: 30),
                    const Text(
                      'HISTORIAL DE GASTOS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey,
                          letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 15),
                    // --- LISTA DE GASTOS ---
                    ..._expenses.map((exp) =>
                        _ExpenseTile(expense: exp, onDeleted: _fetchExpenses)),
                    const SizedBox(height: 100),
                  ],
                ),
    );
  }
}

class _BuildFinancialDashboard extends StatelessWidget {
  final double total;
  final List<DonutSegment> segments;
  final Map<String, double> grouped;

  const _BuildFinancialDashboard(
      {required this.total, required this.segments, required this.grouped});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          if (!isDark && !PerformanceGuard().isLowEnd)
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Gráfico de Dona
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(140, 140),
                        painter: _DonutPainter(segments: segments),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Gastos Totales',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(
                            VehicleExpensesLogic.formatCurrency(total),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 25),
              // Leyenda
              Expanded(
                child: Column(
                  children: VehicleExpensesLogic.categories.map((cat) {
                    final value = grouped[cat.label] ?? 0.0;
                    if (value == 0) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: cat.color, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cat.label,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            VehicleExpensesLogic.formatCurrency(value),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback onDeleted;

  const _ExpenseTile({required this.expense, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final cat = VehicleExpensesLogic.categories.firstWhere(
      (c) => c.label == expense['categoria'],
      orElse: () => VehicleExpensesLogic.categories.last,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: const [], // No shadows in list items for performance
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: cat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(cat.icon, color: cat.color, size: 22),
        ),
        title: Text(
          expense['categoria'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          expense['descripcion'] ?? 'Sin descripción',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '- ${VehicleExpensesLogic.formatCurrency((expense['monto'] as num).toDouble())}',
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.grey),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar Gasto'),
                    content:
                        const Text('¿Estás seguro de eliminar este registro?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar')),
                    ],
                  ),
                );
                if (ok == true) {
                  await SupabaseService().deleteExpense(expense['id']);
                  onDeleted();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _BuildEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text('No hay gastos registrados aún',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 10),
          TextButton(
              onPressed: onAdd, child: const Text('Registrar mi primer gasto')),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 24.0;
    final rect =
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2));

    var startAngle = -math.pi / 2;

    if (segments.isEmpty) {
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius - (strokeWidth / 2), paint);
      return;
    }

    for (var seg in segments) {
      final sweepAngle = seg.percentage * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
