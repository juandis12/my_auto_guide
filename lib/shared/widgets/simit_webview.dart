// =============================================================================
// simit_webview.dart — PANTALLA SIMIT CON ASISTENCIA Y GUARDADO DE MULTAS
// =============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'liquid_glass_fab.dart';
import '../../core/services/ai_bot_service.dart';

class SimitWebViewScreen extends StatefulWidget {
  final String placa;
  final String cedula;
  final String vehiculoId;

  const SimitWebViewScreen({
    super.key,
    required this.placa,
    required this.cedula,
    required this.vehiculoId,
  });

  @override
  State<SimitWebViewScreen> createState() => _SimitWebViewScreenState();
}

class _SimitWebViewScreenState extends State<SimitWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isSaving = false;

  // Estado local para multas
  String _simitStatus = 'unchecked'; // unchecked, clean, has_fines
  double _totalAmount = 0.0;
  int _finesCount = 0;
  List<Map<String, dynamic>> _finesDetails = [];

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            setState(() => _isLoading = false);

            // Intentar inyectar la placa y cédula en los inputs comunes de FCM SIMIT
            await _controller.runJavaScript('''
              function fillSimit() {
                // SIMIT FCM usa selectores dinámicos. Buscamos inputs comunes.
                const inputs = document.querySelectorAll('input');
                inputs.forEach(input => {
                  const placeholder = (input.placeholder || '').toLowerCase();
                  const name = (input.name || '').toLowerCase();
                  const id = (input.id || '').toLowerCase();
                  
                  if (placeholder.includes('placa') || name.includes('placa') || id.includes('placa')) {
                    input.value = '${widget.placa}';
                    input.dispatchEvent(new Event('input', { bubbles: true }));
                  }
                  if (placeholder.includes('documento') || placeholder.includes('cédula') || placeholder.includes('cedula') || name.includes('documento') || id.includes('documento')) {
                    if ('${widget.cedula}'.length > 0) {
                      input.value = '${widget.cedula}';
                      input.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                  }
                });
              }
              // Ejecutar con pequeño delay
              setTimeout(fillSimit, 1500);
            ''');
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://www.fcm.org.co/simit/#/home-public'),
      );
  }

  // Guardar resultados en Supabase
  Future<void> _guardarResultados() async {
    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;

    try {
      final dataToUpdate = {
        'simit_status': _simitStatus,
        'simit_fines_data': _finesDetails,
        'simit_last_check': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('vehiculos')
          .update(dataToUpdate)
          .eq('id', widget.vehiculoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Resultados de SIMIT guardados correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Devolver true para actualizar dashboard
      }
    } catch (e) {
      debugPrint('Error al guardar en Supabase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar datos: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Cuadro de diálogo interactivo para ingresar las multas encontradas manualmente
  // Esto es necesario por las restricciones de CORS, captchas y cambios dinámicos del DOM en la web del SIMIT.
  void _mostrarDialogoCaptura() {
    final TextEditingController countCtrl = TextEditingController(text: _finesCount.toString());
    final TextEditingController amountCtrl = TextEditingController(text: _totalAmount.round().toString());
    String categoria = 'Tránsito';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Registrar Resultado de Multas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa el número de multas y el valor total que observas en la pantalla del SIMIT:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: countCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de multas',
                    prefixIcon: Icon(Icons.gavel_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Valor total (COP)',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría predominante',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Tránsito', 'Foto-Multa', 'Pico y Placa', 'Mal parqueado', 'SOAT/Tecno vencido']
                      .map((String val) => DropdownMenuItem<String>(
                            value: val,
                            child: Text(val),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) categoria = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            LiquidGlassButton(
              label: 'Cancelar',
              onTap: () => Navigator.pop(ctx),
              width: 100,
              height: 38,
            ),
            LiquidGlassButton(
              label: 'Guardar',
              onTap: () {
                final count = int.tryParse(countCtrl.text) ?? 0;
                final amount = double.tryParse(amountCtrl.text) ?? 0.0;

                setState(() {
                  _finesCount = count;
                  _totalAmount = amount;
                  _simitStatus = count > 0 ? 'has_fines' : 'clean';
                  _finesDetails = [
                    {
                      'cantidad': count,
                      'valor_total': amount,
                      'categoria': categoria,
                      'fecha_verificacion': DateTime.now().toIso8601String(),
                    }
                  ];
                });

                Navigator.pop(ctx);
                _guardarResultados();
              },
              width: 100,
              height: 38,
            ),
          ],
        );
      },
    );
  }

  Future<String> _obtenerExplicacionInfraccion(String code) async {
    const Map<String, String> localDescriptions = {
      'A01': 'No adquirir el SOAT obligatorio.',
      'A02': 'Conducir sobre aceras, plazas, bermas o separadores.',
      'B01': 'Conducir sin llevar la licencia de conducción.',
      'B02': 'Conducir con la licencia vencida.',
      'C02': 'Estacionar en sitios prohibidos (parquear mal).',
      'C03': 'Bloquear una calzada o intersección.',
      'C14': 'Transitar en sitios o de horas prohibidas (Pico y Placa).',
      'C24': 'Conducir moto sin casco o chaleco reflectivo reglamentario.',
      'C29': 'Conducir a velocidad superior a la permitida.',
      'C35': 'No tener la revisión Técnico-Mecánica al día.',
      'D02': 'Conducir sin portar el SOAT vigente.',
      'D04': 'Pasarse un semáforo en rojo o señal de PARE.',
      'D08': 'Conducir sin luces encendidas en horas de la noche.',
      'D12': 'Conducir en contravía (sentido contrario).',
      'E04': 'Conducir bajo el influjo del alcohol o sustancias psicoactivas.',
      'F': 'Conducir invadiendo el carril exclusivo de Transmilenio/MIO/Metroplús.',
    };

    final String upCode = code.toUpperCase();
    String localDesc = localDescriptions[upCode] ?? '';
    
    // Intentar consultar con la IA Experto
    try {
      final aiBot = AIBotService();
      aiBot.initialize();
      final prompt = 'Explica brevemente en una sola frase qué significa el código de infracción de tránsito "$upCode" en Colombia y cuál es su causa común.';
      final aiResult = await aiBot.sendMessage(prompt);
      
      if (aiResult.isNotEmpty && !aiResult.contains('Error') && !aiResult.contains('problema')) {
        return '$upCode: ${aiResult.trim()}';
      }
    } catch (_) {
      // Ignorar fallas y usar local
    }

    if (localDesc.isNotEmpty) {
      return '$upCode: $localDesc';
    }
    
    return '$upCode: Infracción de tránsito colombiana.';
  }

  Future<void> _escanearPagina() async {
    setState(() => _isLoading = true);
    try {
      final Object resultObj = await _controller.runJavaScriptReturningResult(r'''
        (function() {
          var totalAmount = 0.0;
          var finesCount = 0;
          var category = 'Tránsito';
          var codesFound = [];
          
          var bodyText = document.body.innerText || '';
          
          // 1. Extraer montos de dinero
          var currencyRegex = /\$\s*([0-9]{1,3}(\.[0-9]{3})+|[0-9]{4,10})/g;
          var match;
          var foundAmounts = [];
          while ((match = currencyRegex.exec(bodyText)) !== null) {
            var numStr = match[1].replace(/\./g, '').trim();
            var val = parseFloat(numStr);
            if (!isNaN(val) && val > 10000) { // Ignorar cobros menores a 10 mil pesos
              foundAmounts.push(val);
            }
          }
          
          if (foundAmounts.length > 0) {
            totalAmount = Math.max.apply(null, foundAmounts);
          }
          
          // 2. Extraer cantidad de comparendos / multas
          // A. Buscar en el texto de resumen del SIMIT: "Comparendos: X", "Multas: Y", "Acuerdos de pago: Z"
          var compMatch = bodyText.match(/comparendos?\s*:\s*(\d+)/i);
          var multMatch = bodyText.match(/multas?\s*:\s*(\d+)/i);
          var acueMatch = bodyText.match(/acuerdos?\s*(de\s+pago)?\s*:\s*(\d+)/i);
          
          var compVal = compMatch ? parseInt(compMatch[1]) : 0;
          var multVal = multMatch ? parseInt(multMatch[1]) : 0;
          var acueVal = acueMatch ? parseInt(acueMatch[2]) : 0;
          
          finesCount = compVal + multVal + acueVal;
          
          // B. Si da 0, buscar el indicador "Total (X):" o "Total (X)" que suele salir al pie de la tabla
          if (finesCount === 0) {
            var totalCountMatch = bodyText.match(/Total\s*\((\d+)\)/i);
            if (totalCountMatch && totalCountMatch[1]) {
              finesCount = parseInt(totalCountMatch[1]);
            }
          }
          
          // C. Si sigue dando 0, buscar números largos de comparendos/resoluciones (de 8 a 20 dígitos)
          if (finesCount === 0) {
            var comparendoNumbers = bodyText.match(/\b\d{8,20}\b/g) || [];
            var distinctComparendos = [];
            comparendoNumbers.forEach(function(num) {
              if (distinctComparendos.indexOf(num) === -1) {
                distinctComparendos.push(num);
              }
            });
            finesCount = distinctComparendos.length;
          }
          
          // D. Fallback si hay valor total pero contador es 0
          if (totalAmount > 0 && finesCount === 0) {
            finesCount = 1;
          }
          
          // E. Extraer códigos de infracción (ej: C02, C14, D02)
          var codeRegex = /\b([A-F]\d{1,2})(?=\.\.\.|\b|\s|$)/gi;
          var codeMatch;
          while ((codeMatch = codeRegex.exec(bodyText)) !== null) {
            var code = codeMatch[1].toUpperCase();
            if (codesFound.indexOf(code) === -1) {
              codesFound.push(code);
            }
          }
          
          // 3. Determinar categoría predominante
          if (bodyText.toLowerCase().indexOf('fotomulta') !== -1 || 
              bodyText.toLowerCase().indexOf('foto dete') !== -1 || 
              bodyText.toLowerCase().indexOf('electrónica') !== -1) {
            category = 'Foto-Multa';
          }
          
          return JSON.stringify({
            "finesCount": finesCount,
            "totalAmount": totalAmount,
            "category": category,
            "codes": codesFound
          });
        })()
      ''');

      // Algunos motores de WebView devuelven el resultado formateado como un string con comillas dobles escapadas
      String resultStr = resultObj.toString();
      if (resultStr.startsWith('"') && resultStr.endsWith('"')) {
        resultStr = resultStr.substring(1, resultStr.length - 1)
            .replaceAll('\\"', '"')
            .replaceAll('\\\\', '\\');
      }

      final Map<String, dynamic> data = jsonDecode(resultStr);
      final int count = data['finesCount'] as int? ?? 0;
      final double amount = (data['totalAmount'] as num? ?? 0.0).toDouble();
      final String category = data['category'] as String? ?? 'Tránsito';
      final List<dynamic> codesRaw = data['codes'] as List<dynamic>? ?? [];
      final List<String> codes = codesRaw.map((e) => e.toString()).toList();

      // Buscar explicaciones de las infracciones encontradas
      List<String> explanations = [];
      for (String code in codes) {
        final String exp = await _obtenerExplicacionInfraccion(code);
        explanations.add(exp);
      }

      setState(() {
        _isLoading = false;
        _finesCount = count;
        _totalAmount = amount;
        _simitStatus = count > 0 ? 'has_fines' : 'clean';
        _finesDetails = [
          {
            'cantidad': count,
            'valor_total': amount,
            'categoria': category,
            'codigos': codes,
            'explicaciones': explanations,
            'fecha_verificacion': DateTime.now().toIso8601String(),
          }
        ];
      });

      if (count > 0 || amount > 0) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                SizedBox(width: 10),
                Text('Multas Encontradas'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Se encontraron $count multas/comparendos en el portal SIMIT.'),
                  const SizedBox(height: 10),
                  Text(
                    'Valor Total: \$${amount.round()} COP',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (explanations.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Motivo de las Infracciones:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ...explanations.map((exp) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• $exp',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        )),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );

        await _guardarResultados();
      } else {
        // No se encontraron comparendos evidentes en pantalla
        final bool? clean = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Resultado del Escaneo'),
            content: const Text('No se encontraron comparendos ni montos pendientes de pago visibles en la página.\n\n¿Quieres marcar tu estado SIMIT como "Libre de multas"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí, libre de multas'),
              ),
            ],
          ),
        );
        if (clean == true) {
          setState(() {
            _simitStatus = 'clean';
            _finesCount = 0;
            _totalAmount = 0.0;
            _finesDetails = [];
          });
          await _guardarResultados();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ No se pudo auto-escanear la página: $e. Inténtalo manualmente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta SIMIT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView principal
          WebViewWidget(controller: _controller),

          // Indicador de carga
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Barra flotante inferior de asistencia y guardado (Glassmorphic)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Placa: ${widget.placa}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (widget.cedula.isNotEmpty)
                                Text(
                                  'Cédula: ${widget.cedula}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              LiquidGlassButton(
                                icon: Icons.copy_rounded,
                                label: 'Placa',
                                height: 32,
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: widget.placa));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Placa copiada al portapapeles.'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              if (widget.cedula.isNotEmpty)
                                LiquidGlassButton(
                                  icon: Icons.copy_rounded,
                                  label: 'Cédula',
                                  height: 32,
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: widget.cedula));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Cédula copiada al portapapeles.'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      LiquidGlassButton(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Escanear Página (Auto)',
                        width: double.infinity,
                        height: 44,
                        customColors: [
                          Colors.blue.shade900.withOpacity(0.6),
                          Colors.purple.shade900.withOpacity(0.4),
                        ],
                        onTap: _escanearPagina,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: LiquidGlassButton(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Sin Multas',
                              height: 42,
                              customColors: [
                                Colors.green.shade800.withOpacity(0.5),
                                const Color(0xFF064E3B).withOpacity(0.3),
                              ],
                              onTap: _isSaving
                                  ? () {}
                                  : () {
                                      setState(() {
                                        _simitStatus = 'clean';
                                        _finesCount = 0;
                                        _totalAmount = 0.0;
                                        _finesDetails = [];
                                      });
                                      _guardarResultados();
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LiquidGlassButton(
                              icon: Icons.warning_amber_rounded,
                              label: 'Con Multas',
                              height: 42,
                              customColors: [
                                Colors.red.shade900.withOpacity(0.6),
                                Colors.deepOrange.shade900.withOpacity(0.4),
                              ],
                              onTap: _isSaving ? () {} : _mostrarDialogoCaptura,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
