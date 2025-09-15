import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParametrizacionMantenimientosScreen extends StatefulWidget {
  final String vehiculoId;
  final DateTime? lastCadena;
  final DateTime? lastFiltro;
  final DateTime? lastAceite;
  const ParametrizacionMantenimientosScreen({
    Key? key,
    required this.vehiculoId,
    this.lastCadena,
    this.lastFiltro,
    this.lastAceite,
  }) : super(key: key);

  @override
  State<ParametrizacionMantenimientosScreen> createState() =>
      _ParametrizacionMantenimientosScreenState();
}

class _ParametrizacionMantenimientosScreenState
    extends State<ParametrizacionMantenimientosScreen> {
  final supabase = Supabase.instance.client;

  DateTime? _cadena;
  DateTime? _filtro;
  DateTime? _aceite;

  @override
  void initState() {
    super.initState();
    _cadena = widget.lastCadena;
    _filtro = widget.lastFiltro;
    _aceite = widget.lastAceite;
  }

  Future<void> _pickDate(
    ValueChanged<DateTime> onPicked, {
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    ); // selector recomendado [28]
    if (picked != null)
      onPicked(DateTime(picked.year, picked.month, picked.day));
  }

  double _pctRestante(DateTime? last, int cicloDias) {
    if (last == null) return 0.0;
    final dias = DateTime.now()
        .difference(last)
        .inDays; // días entre fechas [23]
    final restante = 1.0 - (dias / cicloDias);
    return restante.clamp(0.0, 1.0);
  }

  bool _vencido(DateTime? last, int cicloDias) {
    if (last == null) return false;
    final dias = DateTime.now().difference(last).inDays;
    return dias > cicloDias;
  }

  String _fmt(DateTime? d) => d == null
      ? 'Sin seleccionar'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _guardar() async {
    try {
      await supabase
          .from('vehiculos')
          .update({
            'last_cadena': _cadena == null ? null : _fmt(_cadena),
            'last_filtro': _filtro == null ? null : _fmt(_filtro),
            'last_aceite': _aceite == null ? null : _fmt(_aceite),
          })
          .eq('id', widget.vehiculoId)
          .select(); // confirma actualización [18][21]

      final result = {
        'lastCadena': _cadena,
        'lastFiltro': _filtro,
        'lastAceite': _aceite,
        'pctCadena': _pctRestante(_cadena, 15),
        'pctFiltro': _pctRestante(_filtro, 90),
        'pctAceite': _pctRestante(_aceite, 25),
        'vencCadena': _vencido(_cadena, 15),
        'vencFiltro': _vencido(_filtro, 90),
        'vencAceite': _vencido(_aceite, 25),
      }; // retorna para actualizar UI [23][24]

      if (!mounted) return;
      Navigator.pop(context, result);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parametrización de mantenimientos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.build_circle),
            title: const Text('Última lubricación de cadena'),
            subtitle: Text(_cadena == null ? 'Sin seleccionar' : _fmt(_cadena)),
            trailing: FilledButton(
              onPressed: () => _pickDate(
                (d) => setState(() => _cadena = d),
                initial: _cadena,
              ),
              child: const Text('Elegir'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.filter_alt),
            title: const Text('Último mantenimiento de filtro de aire'),
            subtitle: Text(_filtro == null ? 'Sin seleccionar' : _fmt(_filtro)),
            trailing: FilledButton(
              onPressed: () => _pickDate(
                (d) => setState(() => _filtro = d),
                initial: _filtro,
              ),
              child: const Text('Elegir'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.oil_barrel),
            title: const Text('Último cambio de aceite'),
            subtitle: Text(_aceite == null ? 'Sin seleccionar' : _fmt(_aceite)),
            trailing: FilledButton(
              onPressed: () => _pickDate(
                (d) => setState(() => _aceite = d),
                initial: _aceite,
              ),
              child: const Text('Elegir'),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Guardar y calcular'),
            onPressed: _guardar,
          ),
        ],
      ),
    );
  }
}
