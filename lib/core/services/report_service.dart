import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../logic/vehicle_ai_logic.dart';
import '../utils/formatters.dart';

class ReportService {
  static Future<void> generateVehicleReport({
    required String brand,
    required String model,
    String? plate,
    DateTime? weekStart,
    DateTime? weekEnd,
    required String vehicleImage,
    required int totalKms,
    required List<Map<String, dynamic>> routeHistory,
    required List<Map<String, dynamic>> upcomingIssues,
  }) async {
    final pdf = pw.Document();

    // Cargar Imágenes
    final Uint8List appLogoBytes = await _loadAsset('assets/APK.png');
    final Uint8List? vehicleImgBytes = await _loadAssetSafe(vehicleImage);
    final Uint8List? brandLogoBytes = await _loadAssetSafe(_getBrandLogoPath(brand));

    final aiInsights = VehicleAILogic.analyzeJourneyPatterns(
      routeHistory: routeHistory,
      modelName: model,
      isCar: brand.toUpperCase().contains('TOYOTA') || brand.toUpperCase().contains('MAZDA') || brand.toUpperCase().contains('CHEVROLET'),
    );

    // Calcular Gastos y Métricas de la selección
    double totalFuel = 0.0;
    double totalCost = 0.0;
    double totalKm = 0.0;
    for (var route in routeHistory) {
      final f = (route['consumo_estimado'] ?? route['consumo_galones'] ?? 0.0) as num;
      final c = (route['costo_estimado'] ?? 0.0) as num;
      final k = (route['distancia_km'] ?? route['distancia'] ?? 0.0) as num;
      totalFuel += f.toDouble();
      totalCost += c.toDouble();
      totalKm += k.toDouble();
    }

    final String dateStr = AppFormat.dateTime(DateTime.now());
    
    // Rango de fechas
    String periodoStr = 'Histórico Consolidado';
    String fileDateSuffix = 'Historico';
    if (weekStart != null && weekEnd != null) {
      periodoStr = '${weekStart.day.toString().padLeft(2, '0')}/${weekStart.month.toString().padLeft(2, '0')}/${weekStart.year} al ${weekEnd.day.toString().padLeft(2, '0')}/${weekEnd.month.toString().padLeft(2, '0')}/${weekEnd.year}';
      fileDateSuffix = '${weekStart.day.toString().padLeft(2, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.year}_al_${weekEnd.day.toString().padLeft(2, '0')}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.year}';
    }

    final cleanPlate = (plate != null && plate.trim().isNotEmpty) ? plate.trim().toUpperCase() : 'SIN_PLACA';
    final fileName = '${cleanPlate}_Reporte_Semanal_$fileDateSuffix.pdf';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MY AUTO GUIDE', 
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Hoja de Vida & Reporte Semanal del Activo', 
                      style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
                    pw.SizedBox(height: 3),
                    pw.Text('Período: $periodoStr',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  ],
                ),
                pw.Image(pw.MemoryImage(appLogoBytes), width: 55, height: 55),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 14),

            // INFO VEHÍCULO & PLACA
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (vehicleImgBytes != null)
                  pw.Container(
                    width: 140,
                    height: 95,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(8),
                      color: PdfColors.grey100,
                    ),
                    child: pw.Image(pw.MemoryImage(vehicleImgBytes), fit: pw.BoxFit.contain),
                  ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [
                        if (brandLogoBytes != null) 
                          pw.Padding(padding: const pw.EdgeInsets.only(right: 8), child: pw.Image(pw.MemoryImage(brandLogoBytes), width: 22, height: 22)),
                        pw.Text('$brand $model', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        if (plate != null && plate.trim().isNotEmpty) ...[
                          pw.SizedBox(width: 10),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.yellow300,
                              borderRadius: pw.BorderRadius.circular(4),
                              border: pw.Border.all(color: PdfColors.black, width: 0.8),
                            ),
                            child: pw.Text(
                              plate.toUpperCase(),
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                            ),
                          ),
                        ],
                      ]),
                      pw.SizedBox(height: 6),
                      pw.Text('Odómetro Actual: ${AppFormat.thousands(totalKms)} KM', 
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                      pw.Text('Distancia en el Período: ${totalKm.toStringAsFixed(1)} KM', 
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('Consumo de Combustible: ${totalFuel.toStringAsFixed(2)} Galones', 
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.green800)),
                      pw.Text('Gasto Estimado: \$${AppFormat.thousands(totalCost)} COP', 
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.SizedBox(height: 4),
                      pw.Text('Fecha de Emisión: $dateStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // AI INSIGHTS SECTION
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('DIAGNÓSTICO INTELIGENTE (IA MY AUTO GUIDE)', 
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('Estado: ${aiInsights['healthStatus'] ?? 'Óptimo'}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _pdfStat('Puntuación de Cuidado', '${(aiInsights['careScore'] as num?)?.round() ?? 100}%'),
                      _pdfStat('Intensidad de Uso', '${aiInsights['intensity']}'),
                      _pdfStat('Consistencia', '${aiInsights['consistency']}'),
                      _pdfStat('Rutas Registradas', '${routeHistory.length}'),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Evaluación Técnica:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.Text(aiInsights['advice'] ?? 'Operación en parámetros normales.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // ALERTAS PREDICTIVAS
            pw.Text('PLAN PREVENTIVO & ALERTAS TÉCNICAS', 
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            if (upcomingIssues.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('OK', style: pw.TextStyle(color: PdfColors.green800, fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.SizedBox(width: 8),
                    pw.Text('No se detectan alertas críticas pendientes. Todos los ciclos preventivos están al día.', 
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.green900)),
                  ],
                ),
              )
            else
              ...upcomingIssues.map((issue) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange50,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 4,
                          height: 4,
                          decoration: const pw.BoxDecoration(color: PdfColors.orange800, shape: pw.BoxShape.circle),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text('${issue['item'] ?? issue['component']}: ${issue['reason'] ?? ''}', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Text('Riesgo ${issue['risk'] ?? ''}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                      ],
                    ),
                  )),

            pw.SizedBox(height: 18),
            pw.Text('DETALLE DE RECORRIDOS REALIZADOS', 
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            if (routeHistory.isEmpty)
              pw.Text('No hay trayectos guardados en este período.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _tableHeader('Fecha'),
                      _tableHeader('Origen'),
                      _tableHeader('Destino'),
                      _tableHeader('Distancia'),
                      _tableHeader('Consumo'),
                      _tableHeader('Costo Est.'),
                      _tableHeader('Vel. Prom'),
                    ],
                  ),
                  ...routeHistory.take(40).map((r) {
                    final origen = r['origen_name'] ?? r['origen'] ?? 'Origen';
                    final destino = r['destino_name'] ?? r['destino'] ?? 'Destino';
                    final num dist = r['distancia_km'] ?? r['distancia'] ?? 0;
                    final num fuel = r['consumo_estimado'] ?? r['consumo_galones'] ?? 0;
                    final num cost = r['costo_estimado'] ?? 0;
                    final num vProm = r['velocidad_prom'] ?? 0;
                    final String fecha = AppFormat.dateTime(DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now());

                    return pw.TableRow(
                      children: [
                        _tableCell(fecha),
                        _tableCell(origen),
                        _tableCell(destino),
                        _tableCell('${dist.toStringAsFixed(1)} km'),
                        _tableCell('${fuel.toStringAsFixed(2)} gal'),
                        _tableCell('\$${AppFormat.thousands(cost.toDouble())}'),
                        _tableCell('${vProm.toStringAsFixed(0)} km/h'),
                      ],
                    );
                  }),
                ],
              ),

            pw.SizedBox(height: 16),
          ];
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generado por My Auto Guide • Hoja de Vida Vehicular', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _pdfStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
      ],
    );
  }

  static Future<Uint8List> _loadAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  static Future<Uint8List?> _loadAssetSafe(String path) async {
    try {
      if (path.isEmpty) return null;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final response = await http.get(Uri.parse(path));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
        return null;
      }
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  static String _getBrandLogoPath(String brand) {
    final b = brand.toUpperCase();
    if (b.contains('YAMAHA')) return 'assets/logos/yamaha_logo.png';
    if (b.contains('SUZUKI')) return 'assets/logos/suzuki_logo.png';
    if (b.contains('BMW')) return 'assets/logos/bmw_logo.png';
    if (b.contains('KAWASAKI') || b.contains('KAWA')) return 'assets/logos/kawa_logo.png';
    if (b.contains('HONDA')) return 'assets/logos/honda_logo.png';
    if (b.contains('DUCATI')) return 'assets/logos/ducati_logo.png';
    if (b.contains('KTM')) return 'assets/logos/ktm_logo.png';
    if (b.contains('BAJAJ') || b.contains('PULSAR') || b.contains('DOMINAR')) return 'assets/logos/bajaj_logo.png';
    if (b.contains('HERO')) return 'assets/logos/hero_logo.png';
    if (b.contains('AKT')) return 'assets/logos/akt_logo.png';
    if (b.contains('VICTORI') || b.contains('VICTORY')) return 'assets/logos/victori_logo.png';
    if (b.contains('TOYOTA')) return 'assets/logos/toyota_logo.png';
    if (b.contains('MAZDA')) return 'assets/logos/mazda_logo.png';
    if (b.contains('CHEVROLET') || b.contains('CHEVY')) return 'assets/logos/chevrolet_logo.png';
    return '';
  }
}
