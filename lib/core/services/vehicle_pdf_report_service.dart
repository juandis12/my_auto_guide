import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/formatters.dart';

class VehiclePdfReportService {
  static Future<Uint8List> generatePdfReport({
    required String placa,
    required String marca,
    required String modelo,
    required String apodo,
    required double kms,
    required double healthIndex,
    required String simitStatus,
    required int simitFinesCount,
    required double simitTotalAmount,
    required String? lastSoat,
    required String? lastTecno,
    required String? lastAceite,
    required double kmsLastAceite,
    String? vehicleImageUrl,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#035880');
    final secondaryColor = PdfColor.fromHex('#2563EB');
    final dangerColor = PdfColor.fromHex('#D9534F');
    final successColor = PdfColor.fromHex('#5CB85C');

    final String fechaReporte = AppFormat.dateTime(DateTime.now());

    // Cargar imagen de vehículo si existe (priorizando foto 360 o principal)
    pw.ImageProvider? vehicleImage;
    if (vehicleImageUrl != null && vehicleImageUrl.isNotEmpty) {
      final imgBytes = await _loadAssetSafe(vehicleImageUrl);
      if (imgBytes != null) {
        vehicleImage = pw.MemoryImage(imgBytes);
      }
    }

    // Cargar logo de marca
    final Uint8List? brandLogoBytes = await _loadAssetSafe(_getBrandLogoPath(marca));
    pw.ImageProvider? brandLogoImage;
    if (brandLogoBytes != null) {
      brandLogoImage = pw.MemoryImage(brandLogoBytes);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ENCABEZADO
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MY AUTO GUIDE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'HOJA DE VIDA CERTIFICADA DEL VEHÍCULO',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'PLACA: $placa',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Fecha: $fechaReporte',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // INFORMACIÓN DEL VEHÍCULO E IMAGEN
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'INFORMACIÓN GENERAL',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: primaryColor,
                            ),
                          ),
                          pw.Divider(),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Marca:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                pw.Row(
                                  children: [
                                    if (brandLogoImage != null) ...[
                                      pw.Image(brandLogoImage, width: 16, height: 16),
                                      pw.SizedBox(width: 4),
                                    ],
                                    pw.Text(marca.toUpperCase(), style: const pw.TextStyle(fontSize: 9)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildPdfRow('Modelo:', modelo),
                          _buildPdfRow('Nombre / Apodo:', apodo.isNotEmpty ? apodo : '-'),
                          _buildPdfRow('Odómetro Actual:', '${AppFormat.thousands(kms.round())} Km'),
                          _buildPdfRow('Índice de Salud (ISH):', '${healthIndex.round()}%'),
                        ],
                      ),
                    ),
                  ),
                  if (vehicleImage != null) pw.SizedBox(width: 15),
                  if (vehicleImage != null)
                    pw.Expanded(
                      flex: 2,
                      child: pw.Container(
                        height: 120,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(vehicleImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                    ),
                ],
              ),

              pw.SizedBox(height: 20),

              // ESTADO LEGAL Y SIMIT
              pw.Text(
                '1. ESTADO LEGAL Y COMPARENDOS (SIMIT)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildHeaderCell('Concepto'),
                      _buildHeaderCell('Estado Legal'),
                      _buildHeaderCell('Detalles'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildBodyCell('Comparendos SIMIT'),
                      _buildBodyCell(
                        simitFinesCount > 0 ? '$simitFinesCount Multas' : 'SIN MULTAS',
                        color: simitFinesCount > 0 ? dangerColor : successColor,
                        bold: true,
                      ),
                      _buildBodyCell(
                        simitFinesCount > 0
                            ? 'Monto acumulado: \$${simitTotalAmount.round()} COP'
                            : 'Vehículo a paz y salvo en el portal SIMIT.',
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildBodyCell('SOAT'),
                      _buildBodyCell(
                        _checkDocumentStatus(lastSoat),
                        color: _checkDocumentColor(lastSoat, dangerColor, successColor),
                        bold: true,
                      ),
                      _buildBodyCell(lastSoat != null
                          ? 'Vencimiento: ${_formatExpirationDate(lastSoat)}'
                          : 'Sin fecha registrada'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildBodyCell('Tecnomecánica'),
                      _buildBodyCell(
                        _checkDocumentStatus(lastTecno),
                        color: _checkDocumentColor(lastTecno, dangerColor, successColor),
                        bold: true,
                      ),
                      _buildBodyCell(lastTecno != null
                          ? 'Vencimiento: ${_formatExpirationDate(lastTecno)}'
                          : 'Sin fecha registrada'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // HISTORIAL DE MANTENIMIENTO
              pw.Text(
                '2. MANTENIMIENTOS Y PREVENTIVOS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildHeaderCell('Componente'),
                      _buildHeaderCell('Último Servicio'),
                      _buildHeaderCell('Próximo Cambio Recomendado'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildBodyCell('Aceite de Motor'),
                      _buildBodyCell(lastAceite ?? 'No registrado'),
                      _buildBodyCell(
                        kmsLastAceite > 0
                            ? 'A los ${(kmsLastAceite + 3000).round()} Km (Faltan ${((kmsLastAceite + 3000) - kms).round().clamp(0, 99999)} Km)'
                            : 'Cada 3,000 Km',
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // PIE DE PÁGINA CON CÓDIGO QR Y CERTIFICACIÓN
              pw.Divider(color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Documento generado automáticamente por la plataforma My Auto Guide.',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Información verificada en tiempo real con Supabase Backend.',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'https://simit.fcm.org.co/#/home-public?placa=$placa',
                    width: 50,
                    height: 50,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
    );
  }

  static pw.Widget _buildBodyCell(String text, {PdfColor? color, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: color ?? PdfColors.black,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static DateTime? _computeExpirationDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    final now = DateTime.now();
    if (date.isBefore(now)) {
      return DateTime(date.year + 1, date.month, date.day);
    }
    return date;
  }

  static String _formatExpirationDate(String? dateStr) {
    final exp = _computeExpirationDate(dateStr);
    if (exp == null) return dateStr ?? '';
    return '${exp.day.toString().padLeft(2, '0')}/${exp.month.toString().padLeft(2, '0')}/${exp.year}';
  }

  static String _checkDocumentStatus(String? dateStr) {
    final exp = _computeExpirationDate(dateStr);
    if (exp == null) return 'Sin Registro';
    return exp.isBefore(DateTime.now()) ? 'VENCIDO' : 'VIGENTE';
  }

  static PdfColor _checkDocumentColor(String? dateStr, PdfColor danger, PdfColor success) {
    final exp = _computeExpirationDate(dateStr);
    if (exp == null) return PdfColors.grey700;
    return exp.isBefore(DateTime.now()) ? danger : success;
  }

  /// Imprime o abre el menú nativo de compartir (funciona en iOS y Android)
  static Future<void> sharePdfReport({
    required String filename,
    required Uint8List pdfBytes,
  }) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
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
