import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../logic/vehicle_ai_logic.dart';

class ReportService {
  static Future<void> generateVehicleReport({
    required String brand,
    required String model,
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
      isCar: brand.toUpperCase() == 'TOYOTA' || brand.toUpperCase() == 'MAZDA' || brand.toUpperCase() == 'CHEVROLET',
    );

    // Calcular Gastos
    double totalFuel = 0.0;
    double totalCost = 0.0;
    for (var route in routeHistory) {
      final f = (route['consumo_estimado'] ?? route['consumo_galones'] ?? 0.0) as num;
      final c = (route['costo_estimado'] ?? 0.0) as num;
      totalFuel += f.toDouble();
      totalCost += c.toDouble();
    }

    final String dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

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
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('Reporte Inteligente de Vehículo', 
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Image(pw.MemoryImage(appLogoBytes), width: 60, height: 60),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 20),

              // INFO VEHÍCULO
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (vehicleImgBytes != null)
                    pw.Container(
                      width: 150,
                      height: 100,
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(10),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Image(pw.MemoryImage(vehicleImgBytes), fit: pw.BoxFit.contain),
                    ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(children: [
                          if (brandLogoBytes != null) 
                            pw.Padding(padding: pw.EdgeInsets.only(right: 8), child: pw.Image(pw.MemoryImage(brandLogoBytes), width: 25, height: 25)),
                          pw.Text('$brand $model', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        ]),
                        pw.SizedBox(height: 8),
                        pw.Text('Kilometraje Actual: ${totalKms.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} KM', 
                          style: const pw.TextStyle(fontSize: 14)),
                        pw.Text('Consumo Documentado: ${totalFuel.toStringAsFixed(2)} Gal', style: const pw.TextStyle(fontSize: 12, color: PdfColors.green800)),
                        pw.Text('Gasto Estimado: \$${totalCost.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} COP', 
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        pw.SizedBox(height: 8),
                        pw.Text('Fecha de Emisión: $dateStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

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
                    pw.Text('DIAGNÓSTICO IA MY AUTO GUIDE', 
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _pdfStat('Care Score', '${aiInsights['careScore'].round()}%'),
                        _pdfStat('Intensidad', '${aiInsights['intensity']}'),
                        _pdfStat('Consistencia', '${aiInsights['consistency']}'),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Consejo de la IA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(aiInsights['advice'], style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),

              // ALERTAS PREDICTIVAS
              pw.Text('ALERTAS TÉCNICAS (PRÓXIMOS MANTENIMIENTOS)', 
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              if (upcomingIssues.isEmpty)
                pw.Text('No se detectan alertas críticas pendientes.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700))
              else
                ...upcomingIssues.map((issue) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 5),
                  padding: const pw.EdgeInsets.all(8),
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
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Text('${issue['item']}: ${issue['reason']}', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Text(issue['risk'], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                    ],
                  ),
                )),

              pw.SizedBox(height: 30),
              pw.Text('HISTORIAL DE RUTAS RECIENTES', 
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              if (routeHistory.isEmpty)
                pw.Text('No hay trayectos guardados en el historial.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic))
              else
                pw.TableHelper.fromTextArray(
                  context: context,
                  cellAlignment: pw.Alignment.centerLeft,
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  headers: ['Fecha', 'Origen', 'Destino', 'KM', 'V. Máx', 'V. Prom', 'Galones', 'Costo'],
                  data: routeHistory.map((r) {
                    final fechaRaw = r['fecha'] ?? r['created_at'];
                    final date = fechaRaw != null ? DateTime.tryParse(fechaRaw.toString()) : null;
                    final displayDate = date != null ? DateFormat('dd/MM HH:mm').format(date) : '-';
                    final ori = r['origen'] ?? r['origen_name'] ?? 'Desconocido';
                    final des = r['destino'] ?? r['destino_name'] ?? 'Desconocido';
                    final dist = (r['distancia'] ?? r['distancia_km'] ?? 0.0) as num;
                    final gal = (r['consumo_estimado'] ?? r['consumo_galones'] ?? 0.0) as num;
                    final cost = (r['costo_estimado'] ?? 0.0) as num;
                    
                    final vMax = (r['velocidad_max'] ?? 0.0) as num;
                    final vProm = (r['velocidad_prom'] ?? 0.0) as num;
                    
                    return [
                      displayDate,
                      ori.toString().length > 15 ? '${ori.toString().substring(0, 15)}...' : ori.toString(),
                      des.toString().length > 15 ? '${des.toString().substring(0, 15)}...' : des.toString(),
                      dist.toStringAsFixed(1),
                      '${vMax.toStringAsFixed(0)}',
                      '${vProm.toStringAsFixed(0)}',
                      gal.toStringAsFixed(2),
                      '\$${cost.toStringAsFixed(0)}'
                    ];
                  }).toList(),
                ),

              pw.SizedBox(height: 20),
            ];
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generado por My Auto Guide AI Engine', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ]
          );
        }
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_${brand}_$model.pdf',
    );
  }

  static pw.Widget _pdfStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
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
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  static String _getBrandLogoPath(String brand) {
    final Map<String, String> brandLogos = {
      'YAMAHA': 'assets/logos/yamaha_logo.png',
      'SUZUKI': 'assets/logos/suzuki_logo.png',
      'BMW': 'assets/logos/bmw_logo.png',
      'KAWASAKI': 'assets/logos/kawa_logo.png',
      'HONDA': 'assets/logos/honda_logo.png',
      'DUCATI': 'assets/logos/ducati_logo.png',
      'KTM': 'assets/logos/ktm_logo.png',
      'BAJAJ': 'assets/logos/bajaj_logo.png',
      'HERO': 'assets/logos/hero_logo.png',
      'AKT': 'assets/logos/akt_logo.png',
      'VICTORI': 'assets/logos/victori_logo.png',
      'TOYOTA': 'assets/logos/toyota_logo.png',
      'MAZDA': 'assets/logos/mazda_logo.png',
      'CHEVROLET': 'assets/logos/chevrolet_logo.png',
    };
    return brandLogos[brand.toUpperCase()] ?? '';
  }
}
