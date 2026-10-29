// =============================================================================
// runt_webview.dart — CONSULTA Y EXTRACCIÓN AUTOMÁTICA RUNT COLOMBIA
// =============================================================================

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/app_snack_bar.dart';

class RuntWebViewScreen extends StatefulWidget {
  final String placa;
  final String cedula;
  final String vehiculoId;

  const RuntWebViewScreen({
    super.key,
    required this.placa,
    required this.cedula,
    required this.vehiculoId,
  });

  @override
  State<RuntWebViewScreen> createState() => _RuntWebViewScreenState();
}

class _RuntWebViewScreenState extends State<RuntWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  String fechaSoatExpedicion = "";
  String fechaSoatVencimiento = "";
  String fechaTecnoExpedicion = "";
  String fechaTecnoVencimiento = "";
  
  String? _cachedSoat;
  String? _cachedTecno;
  String? _cachedDate;
  bool _hasOfflineCache = false;

  @override
  void initState() {
    super.initState();
    _loadLocalRuntCache();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            debugPrint("RUNT WebView error: ${error.description}");
            if (mounted && _hasOfflineCache) {
              setState(() => _loading = false);
            }
          },
          onPageFinished: (url) async {
            if (mounted) setState(() => _loading = false);

            // Autocompletar placa y cédula de forma resiliente
            await _controller.runJavaScript('''
              function fillInputs() {
                const placaSelectors = ['#txtPlaca', '#placa', 'input[name="placa"]', 'input[placeholder*="Placa"]', 'input[ng-model*="placa"]'];
                const docSelectors = ['#txtNumDoc', '#noDocumento', '#numDoc', 'input[name="numDoc"]', 'input[placeholder*="Documento"]', 'input[ng-model*="numDoc"]'];

                let placaEl = null;
                for (const sel of placaSelectors) {
                  placaEl = document.querySelector(sel);
                  if (placaEl) break;
                }

                let docEl = null;
                for (const sel of docSelectors) {
                  docEl = document.querySelector(sel);
                  if (docEl) break;
                }

                if (placaEl && docEl) {
                  placaEl.value = '${widget.placa}';
                  docEl.value = '${widget.cedula}';
                  placaEl.dispatchEvent(new Event('input', { bubbles: true }));
                  docEl.dispatchEvent(new Event('input', { bubbles: true }));
                } else {
                  setTimeout(fillInputs, 500);
                }
              }
              fillInputs();
            ''');
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://www.runt.gov.co/consultaCiudadana/#/consultaVehiculo',
        ),
      );
  }

  String parseJsResult(Object? result) {
    if (result == null) return "";
    return result.toString().replaceAll('"', '').trim();
  }

  Future<String> getTextFromJs(String js) async {
    for (int i = 0; i < 5; i++) {
      try {
        final result = await _controller.runJavaScriptReturningResult(js);
        final text = parseJsResult(result);
        if (text.isNotEmpty) return text;
      } catch (e) {
        debugPrint("Error ejecutando JS RUNT: $e");
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    return "";
  }

  String? _convertToIsoDate(String rawDate) {
    if (rawDate.trim().isEmpty) return null;
    final match = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})').firstMatch(rawDate);
    if (match != null) {
      final day = match.group(1)!.padLeft(2, '0');
      final month = match.group(2)!.padLeft(2, '0');
      final year = match.group(3)!;
      return '$year-$month-$day';
    }
    final isoMatch = RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})').firstMatch(rawDate);
    if (isoMatch != null) {
      final year = isoMatch.group(1)!;
      final month = isoMatch.group(2)!.padLeft(2, '0');
      final day = isoMatch.group(3)!.padLeft(2, '0');
      return '$year-$month-$day';
    }
    return null;
  }

  Future<void> consultarFechas() async {
    setState(() => _loading = true);
    debugPrint("🔍 Extrayendo fechas RUNT...");

    // Buscar fechas del SOAT en el DOM
    fechaSoatVencimiento = await getTextFromJs('''
      (function() {
        const tables = [...document.querySelectorAll('table')];
        for (const t of tables) {
          const txt = (t.innerText || '').toUpperCase();
          if (txt.includes('SOAT') || txt.includes('PÓLIZA')) {
            const rows = [...t.querySelectorAll('tr')];
            for (const r of rows) {
              const rTxt = (r.innerText || '').toUpperCase();
              const dates = rTxt.match(/\\b(\\d{2}[\\/\\-]\\d{2}[\\/\\-]\\d{4})\\b/g);
              if (dates && dates.length > 0 && (rTxt.includes('VENCIMIENTO') || rTxt.includes('HASTA'))) {
                return dates[0];
              }
            }
          }
        }
        return "";
      })();
    ''');

    fechaTecnoVencimiento = await getTextFromJs('''
      (function() {
        const tables = [...document.querySelectorAll('table')];
        for (const t of tables) {
          const txt = (t.innerText || '').toUpperCase();
          if (txt.includes('RTM') || txt.includes('TÉCNICO') || txt.includes('REVISIÓN')) {
            const rows = [...t.querySelectorAll('tr')];
            for (const r of rows) {
              const rTxt = (r.innerText || '').toUpperCase();
              const dates = rTxt.match(/\\b(\\d{2}[\\/\\-]\\d{2}[\\/\\-]\\d{4})\\b/g);
              if (dates && dates.length > 0 && (rTxt.includes('VENCIMIENTO') || rTxt.includes('HASTA'))) {
                return dates[0];
              }
            }
          }
        }
        return "";
      })();
    ''');

    setState(() => _loading = false);

    await guardarFechas();
  }

  /// Actualizar en Supabase en la tabla `vehiculos`
  Future<void> guardarFechas() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) AppSnackBar.show(context, 'Error: Usuario no autenticado');
      return;
    }

    final String? soatIso = _convertToIsoDate(fechaSoatVencimiento);
    final String? tecnoIso = _convertToIsoDate(fechaTecnoVencimiento);

    final Map<String, dynamic> updateData = {};
    if (soatIso != null) updateData['last_soat'] = soatIso;
    if (tecnoIso != null) updateData['last_tecno'] = tecnoIso;
    if (widget.placa.isNotEmpty) updateData['placa'] = widget.placa;
    if (widget.cedula.isNotEmpty) updateData['cedula'] = widget.cedula;

    if (updateData.isEmpty) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Completa la consulta en el RUNT y asegúrate que la tabla con fechas esté desplegada.',
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      await supabase
          .from('vehiculos')
          .update(updateData)
          .eq('id', widget.vehiculoId)
          .eq('user_id', userId);

      debugPrint("✅ Fechas RUNT actualizadas en Supabase: $updateData");

      // Guardar también en caché local SharedPreferences para disponibilidad Offline
      final prefs = await SharedPreferences.getInstance();
      if (fechaSoatVencimiento.isNotEmpty) {
        await prefs.setString('runt_cached_soat_${widget.vehiculoId}', fechaSoatVencimiento);
      }
      if (fechaTecnoVencimiento.isNotEmpty) {
        await prefs.setString('runt_cached_tecno_${widget.vehiculoId}', fechaTecnoVencimiento);
      }
      await prefs.setString('runt_cached_date_${widget.vehiculoId}', DateTime.now().toIso8601String());

      if (mounted) {
        AppSnackBar.show(
          context,
          '✅ Fechas guardadas y actualizadas en tu vehículo',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context, true); // Retorna true para refrescar la vista de Inicio
      }
    } catch (e) {
      debugPrint("❌ Error actualizando fechas en Supabase: $e");
      if (mounted) AppSnackBar.show(context, 'Error actualizando fechas: $e');
    }
  }

  Future<void> _loadLocalRuntCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soat = prefs.getString('runt_cached_soat_${widget.vehiculoId}');
      final tecno = prefs.getString('runt_cached_tecno_${widget.vehiculoId}');
      final date = prefs.getString('runt_cached_date_${widget.vehiculoId}');
      if (soat != null || tecno != null) {
        if (mounted) {
          setState(() {
            _cachedSoat = soat;
            _cachedTecno = tecno;
            _cachedDate = date;
            _hasOfflineCache = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error leyendo caché RUNT local: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta RUNT Oficial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading && !_hasOfflineCache) const Center(child: CircularProgressIndicator()),
          if (_hasOfflineCache)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Card(
                color: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFF38BDF8), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.offline_bolt_rounded, color: Color(0xFF38BDF8), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Caché Local RUNT: SOAT ${_cachedSoat ?? "Al día"} • Tecno ${_cachedTecno ?? "Al día"}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: consultarFechas,
                  icon: const Icon(Icons.download_done_rounded),
                  label: const Text("Extraer y Guardar Fechas SOAT y Tecno"),
                ),
                const SizedBox(height: 10),
                if (fechaSoatVencimiento.isNotEmpty || fechaTecnoVencimiento.isNotEmpty)
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (fechaSoatVencimiento.isNotEmpty)
                            Text("SOAT vence: $fechaSoatVencimiento", style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (fechaTecnoVencimiento.isNotEmpty)
                            Text("Tecnomecánica vence: $fechaTecnoVencimiento", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
