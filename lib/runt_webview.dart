import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            setState(() => _loading = false);

            // Autocompletar los campos de placa y cédula automáticamente
            await _controller.runJavaScript('''
              function fillInputs() {
                const placa = document.getElementById('txtPlaca');
                const cedula = document.getElementById('txtNumDoc');
                if (placa && cedula) {
                  placa.value = '${widget.placa}';
                  cedula.value = '${widget.cedula}';
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
          'https://www.runt.com.co/consultaCiudadana/#/consultaVehiculo',
        ),
      );
  }

  String parseJsResult(Object? result) {
    if (result == null) return "";
    return result.toString().replaceAll('"', '').trim();
  }

  Future<String> getTextFromJs(String js) async {
    for (int i = 0; i < 10; i++) {
      try {
        final result = await _controller.runJavaScriptReturningResult(js);
        final text = parseJsResult(result);
        if (text.isNotEmpty) return text;
      } catch (e) {
        debugPrint("Error ejecutando JS: $e");
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    return "";
  }

  Future<void> consultarFechas() async {
    setState(() => _loading = true);
    debugPrint("🔍 Buscando fechas...");

    // Buscar fechas del SOAT
    fechaSoatExpedicion = await getTextFromJs('''
      (function() {
        const soatTable = [...document.querySelectorAll('table')].find(t => 
          t.innerText.includes('PÓLIZA SOAT') || t.innerText.includes('SOAT')
        );
        if (!soatTable) return "";
        const rows = soatTable.querySelectorAll('tr');
        let expedicion = "", vencimiento = "";
        rows.forEach(r => {
          if (r.innerText.includes('FECHA EXPEDICIÓN')) expedicion = r.cells[1]?.innerText.trim();
          if (r.innerText.includes('FECHA VENCIMIENTO')) vencimiento = r.cells[1]?.innerText.trim();
        });
        return expedicion;
      })();
    ''');

    fechaSoatVencimiento = await getTextFromJs('''
      (function() {
        const soatTable = [...document.querySelectorAll('table')].find(t => 
          t.innerText.includes('PÓLIZA SOAT') || t.innerText.includes('SOAT')
        );
        if (!soatTable) return "";
        const rows = soatTable.querySelectorAll('tr');
        let vencimiento = "";
        rows.forEach(r => {
          if (r.innerText.includes('FECHA VENCIMIENTO')) vencimiento = r.cells[1]?.innerText.trim();
        });
        return vencimiento;
      })();
    ''');

    // Buscar fechas de Tecnomecánica / RTM
    fechaTecnoExpedicion = await getTextFromJs('''
      (function() {
        const tecnoTable = [...document.querySelectorAll('table')].find(t => 
          t.innerText.includes('CERTIFICADO DE REVISIÓN TÉCNICO-MECÁNICA') || 
          t.innerText.includes('RTM')
        );
        if (!tecnoTable) return "";
        const rows = tecnoTable.querySelectorAll('tr');
        let expedicion = "";
        rows.forEach(r => {
          if (r.innerText.includes('FECHA EXPEDICIÓN')) expedicion = r.cells[1]?.innerText.trim();
        });
        return expedicion;
      })();
    ''');

    fechaTecnoVencimiento = await getTextFromJs('''
      (function() {
        const tecnoTable = [...document.querySelectorAll('table')].find(t => 
          t.innerText.includes('CERTIFICADO DE REVISIÓN TÉCNICO-MECÁNICA') || 
          t.innerText.includes('RTM')
        );
        if (!tecnoTable) return "";
        const rows = tecnoTable.querySelectorAll('tr');
        let vencimiento = "";
        rows.forEach(r => {
          if (r.innerText.includes('FECHA VENCIMIENTO')) vencimiento = r.cells[1]?.innerText.trim();
        });
        return vencimiento;
      })();
    ''');

    debugPrint("📅 SOAT: $fechaSoatExpedicion → $fechaSoatVencimiento");
    debugPrint("📅 TECNO: $fechaTecnoExpedicion → $fechaTecnoVencimiento");

    setState(() => _loading = false);

    await guardarFechas();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("✅ Fechas consultadas y guardadas correctamente"),
              if (fechaSoatExpedicion.isNotEmpty)
                Text("SOAT expedido: $fechaSoatExpedicion"),
              if (fechaSoatVencimiento.isNotEmpty)
                Text("SOAT vence: $fechaSoatVencimiento"),
              if (fechaTecnoExpedicion.isNotEmpty)
                Text("Tecnomecánica expedida: $fechaTecnoExpedicion"),
              if (fechaTecnoVencimiento.isNotEmpty)
                Text("Tecnomecánica vence: $fechaTecnoVencimiento"),
            ],
          ),
        ),
      );
    }
  }

  /// Guardar en Supabase usando upsert (seguro y sin conflictos)
  Future<void> guardarFechas() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint("❌ Usuario no autenticado");
      return;
    }

    try {
      final response = await supabase
          .from('vehiculos')
          .upsert({
            'vehiculo_id': widget.vehiculoId,
            'placa': widget.placa,
            'cedula': widget.cedula,
            'user_id': userId,
            'soat_expedicion': fechaSoatExpedicion,
            'soat_vencimiento': fechaSoatVencimiento,
            'tecno_expedicion': fechaTecnoExpedicion,
            'tecno_vencimiento': fechaTecnoVencimiento,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      debugPrint("✅ Datos guardados en Supabase: $response");
    } catch (e) {
      debugPrint("❌ Error guardando en Supabase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta RUNT'),
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
          if (_loading) const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: consultarFechas,
                  icon: const Icon(Icons.search),
                  label: const Text("Consultar Fechas SOAT y Tecno"),
                ),
                const SizedBox(height: 10),
                if (fechaSoatExpedicion.isNotEmpty ||
                    fechaSoatVencimiento.isNotEmpty ||
                    fechaTecnoExpedicion.isNotEmpty ||
                    fechaTecnoVencimiento.isNotEmpty)
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (fechaSoatExpedicion.isNotEmpty)
                            Text("SOAT expedido: $fechaSoatExpedicion"),
                          if (fechaSoatVencimiento.isNotEmpty)
                            Text("SOAT vence: $fechaSoatVencimiento"),
                          if (fechaTecnoExpedicion.isNotEmpty)
                            Text(
                              "Tecnomecánica expedida: $fechaTecnoExpedicion",
                            ),
                          if (fechaTecnoVencimiento.isNotEmpty)
                            Text("Tecnomecánica vence: $fechaTecnoVencimiento"),
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
