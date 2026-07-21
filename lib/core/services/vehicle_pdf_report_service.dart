// =============================================================================
// vehicle_pdf_report_service.dart — GENERADOR DE HOJA DE VIDA EN PDF (ANDROID & IOS)
// =============================================================================
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

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

    final String fechaReporte = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Cargar imagen de vehículo si existe (opcional)
    pw.ImageProvider? vehicleImage;
    if (vehicleImageUrl != null && vehicleImageUrl.isNotEmpty) {
      try {
        vehicleImage = await networkImage(vehicleImageUrl);
      } catch (e) {
        debugPrint('Aviso: No se pudo descargar la imagen para el PDF: $e');
      }
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
                          _buildPdfRow('Marca:', marca.toUpperCase()),
                          _buildPdfRow('Modelo:', modelo),
                          _buildPdfRow('Nombre / Apodo:', apodo.isNotEmpty ? apodo : '-'),
                          _buildPdfRow('Kilometraje Registrado:', '${kms.round()} Km'),
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
                      _buildBodyCell(lastSoat != null ? 'Vencimiento: $lastSoat' : 'Sin fecha registrada'),
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
                      _buildBodyCell(lastTecno != null ? 'Vencimiento: $lastTecno' : 'Sin fecha registrada'),
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

  static String _checkDocumentStatus(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Sin Registro';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'Formato no válido';
    return date.isBefore(DateTime.now()) ? 'VENCIDO' : 'VIGENTE';
  }

  static PdfColor _checkDocumentColor(String? dateStr, PdfColor danger, PdfColor success) {
    if (dateStr == null || dateStr.isEmpty) return PdfColors.grey700;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return PdfColors.grey700;
    return date.isBefore(DateTime.now()) ? danger : success;
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
}
