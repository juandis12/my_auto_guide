import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'vehicle_expenses_logic.dart';

class PdfReportLogic {
  static Future<void> generateAndShareExpenseReport({
    required String vehiculoApodo,
    required String marcaModelo,
    required List<Map<String, dynamic>> expenses,
    String? brandLogoPath,
    String? vehicleImagePath,
  }) async {
    final pdf = pw.Document();

    // Cargar imágenes
    pw.ImageProvider? appLogo;
    pw.ImageProvider? brandLogo;
    pw.ImageProvider? vehicleImage;

    try {
      final appLogoBytes = await rootBundle.load('assets/APK.png');
      appLogo = pw.MemoryImage(appLogoBytes.buffer.asUint8List());
      
      if (brandLogoPath != null) {
        final brandBytes = await rootBundle.load(brandLogoPath);
        brandLogo = pw.MemoryImage(brandBytes.buffer.asUint8List());
      }

      if (vehicleImagePath != null) {
        if (vehicleImagePath.startsWith('assets/')) {
          final vBytes = await rootBundle.load(vehicleImagePath);
          vehicleImage = pw.MemoryImage(vBytes.buffer.asUint8List());
        } else if (vehicleImagePath.startsWith('http')) {
          // Para imágenes de red (firmadas de Supabase)
          final response = await NetworkAssetBundle(Uri.parse(vehicleImagePath)).load('');
          vehicleImage = pw.MemoryImage(response.buffer.asUint8List());
        }
      }
    } catch (e) {
      debugPrint('Error cargando imágenes para PDF: $e');
    }

    final total = VehicleExpensesLogic.calculateTotal(expenses);
    final grouped = VehicleExpensesLogic.groupByValues(expenses);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Cabecera con Logos
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (appLogo != null) pw.Image(appLogo, width: 40, height: 40),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('MY AUTO GUIDE', 
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('GESTIÓN INTEGRAL DE VEHÍCULOS', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                  ],
                ),
                if (brandLogo != null) pw.Image(brandLogo, width: 40, height: 40)
                else pw.SizedBox(width: 40),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 10),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Info Vehículo
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('REPORTE DE GASTOS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text('Vehículo: $vehiculoApodo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Marca/Modelo: $marcaModelo'),
                      pw.Text('Fecha Generación: ${DateTime.now().toString().split(' ')[0]}'),
                    ],
                  ),
                ),
                // Imagen Vehículo
                if (vehicleImage != null)
                  pw.Container(
                    width: 120,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.ClipRRect(
                      verticalRadius: 8,
                      horizontalRadius: 8,
                      child: pw.Image(vehicleImage, fit: pw.BoxFit.cover),
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Resumen Ejecutivo
            pw.Text('RESUMEN FINANCIERO', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Gasto Total Acumulado:'),
                pw.Text(VehicleExpensesLogic.formatCurrency(total), 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
              ],
            ),
            pw.SizedBox(height: 10),
            
            // Tabla de Categorías
            pw.Table.fromTextArray(
              headers: ['Categoría', 'Monto Invertido'],
              data: grouped.entries.map((e) => [e.key, VehicleExpensesLogic.formatCurrency(e.value)]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            
            pw.SizedBox(height: 30),
            pw.Text('DETALLE DE TRANSACCIONES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            
            // Listado de Gastos
            pw.Table.fromTextArray(
              headers: ['Fecha', 'Categoría', 'Descripción', 'Monto'],
              data: expenses.map((e) {
                final date = DateTime.parse(e['fecha']).toString().split(' ')[0];
                return [
                  date,
                  e['categoria'],
                  e['descripcion'] ?? '-',
                  VehicleExpensesLogic.formatCurrency((e['monto'] as num).toDouble()),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Reporte generado automáticamente por My Auto Guide App', 
                    style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8)),
                pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8)),
              ],
            ),
          );
        },
      ),
    );

    // Compartir el PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'reporte_gastos_${vehiculoApodo.replaceAll(' ', '_')}.pdf',
    );
  }
}
