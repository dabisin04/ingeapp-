import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_bloc.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_event.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/repositories/unidad_de_tiempo_repository.dart';

const _kAplicaOpciones = ['Todos', 'Ingreso', 'Egreso'];

class RateCardDialog extends StatefulWidget {
  final TasaDeInteres? tasa;
  final UnidadDeTiempoRepository unidadDeTiempoRepository;

  const RateCardDialog({
    Key? key,
    this.tasa,
    required this.unidadDeTiempoRepository,
  }) : super(key: key);

  @override
  State<RateCardDialog> createState() => _RateCardDialogState();
}

class _RateCardDialogState extends State<RateCardDialog> {
  // ─ Text controllers ─
  final _valorCtrl = TextEditingController();
  final _iniCtrl = TextEditingController();
  final _finCtrl = TextEditingController();

  // ─ Estado de combos/switches ─
  int _periodicidadId = 1;
  int _capitalizacionId = 1;
  bool _isAnticipada = false;

  // ─ Campo NUEVO: a qué flujo aplica la tasa ─
  String _aplicaA = 'Todos';

  // ─ Datos auxiliares ─
  List<UnidadDeTiempo> _unidades = [];

  @override
  void initState() {
    super.initState();
    _cargarUnidades().then((_) {
      if (widget.tasa != null) _precargarDatos(widget.tasa!);
    });
  }

  Future<void> _cargarUnidades() async {
    _unidades = await widget.unidadDeTiempoRepository.obtenerUnidadesDeTiempo();
    if (mounted) setState(() {});
  }

  void _precargarDatos(TasaDeInteres t) {
    _valorCtrl.text = (t.valor * 100).toString();
    _iniCtrl.text = t.periodoInicio.toString();
    _finCtrl.text = t.periodoFin.toString();
    _periodicidadId = t.periodicidad.id;
    _capitalizacionId = t.capitalizacion.id;
    _isAnticipada = t.tipo.toLowerCase() == 'anticipada';
    _aplicaA = t.aplicaA; // ← NUEVO
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _iniCtrl.dispose();
    _finCtrl.dispose();
    super.dispose();
  }

  /* ─────────────────── Guardar ─────────────────── */

  void _onSave() {
    // Validaciones básicas …
    final i = int.tryParse(_iniCtrl.text.trim());
    final f = int.tryParse(_finCtrl.text.trim());
    final raw = double.tryParse(_valorCtrl.text.trim());

    if (i == null || f == null || raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa valor y periodos')),
      );
      return;
    }

    final periodicidad = _unidades.firstWhere((u) => u.id == _periodicidadId);
    final capitaliz = _unidades.firstWhere((u) => u.id == _capitalizacionId);
    final tipoStr = _isAnticipada ? 'Anticipada' : 'Vencida';

    final nueva = TasaDeInteres(
      id: widget.tasa?.id ?? DateTime.now().millisecondsSinceEpoch,
      valor: raw / 100, // se almacena como decimal
      periodicidad: periodicidad,
      capitalizacion: capitaliz,
      tipo: tipoStr,
      periodoInicio: i,
      periodoFin: f,
      aplicaA: _aplicaA, // ← NUEVO
    );

    final bloc = context.read<TasaInteresBloc>();
    widget.tasa == null
        ? bloc.add(AgregarTasaInteres(nueva))
        : bloc.add(EditarTasaInteres(nueva.id, nueva));

    Navigator.of(context).pop();
  }

  /* ───────────────────  Build  ─────────────────── */

  @override
  Widget build(BuildContext context) {
    if (_unidades.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Capitalizaciones válidas ≥ periodicidad elegida
    final per = _unidades.firstWhere((u) => u.id == _periodicidadId);
    final caps = _unidades.where((u) => u.valor >= per.valor).toList();

    return AlertDialog(
      title: Text(widget.tasa == null ? 'Añadir Tasa' : 'Editar Tasa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Valor %
            TextField(
              controller: _valorCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor (%)'),
            ),
            // Periodos
            TextField(
              controller: _iniCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Periodo Inicio'),
            ),
            TextField(
              controller: _finCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Periodo Fin'),
            ),
            // Periodicidad
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Periodicidad'),
              value: _periodicidadId,
              items: _unidades
                  .map((u) =>
                      DropdownMenuItem(value: u.id, child: Text(u.nombre)))
                  .toList(),
              onChanged: (v) => setState(() {
                _periodicidadId = v!;
                // ajusta capitalización si quedó fuera de rango
                final nuevaPer = _unidades.firstWhere((u) => u.id == v);
                final capsValid =
                    _unidades.where((u) => u.valor >= nuevaPer.valor).toList();
                if (!capsValid.any((c) => c.id == _capitalizacionId)) {
                  _capitalizacionId = capsValid.first.id;
                }
              }),
            ),
            // Capitalización
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Capitalización'),
              value: _capitalizacionId,
              items: caps
                  .map((u) =>
                      DropdownMenuItem(value: u.id, child: Text(u.nombre)))
                  .toList(),
              onChanged: (v) => setState(() => _capitalizacionId = v!),
            ),
            // Anticipada / Vencida
            SwitchListTile(
              title: const Text('Anticipada'),
              dense: true,
              value: _isAnticipada,
              onChanged: (v) => setState(() => _isAnticipada = v),
            ),
            const Divider(),
            // Radio-buttons “Aplica a”
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aplica a',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                ..._kAplicaOpciones.map(
                  (op) => RadioListTile<String>(
                    dense: true,
                    title: Text(op),
                    value: op,
                    groupValue: _aplicaA,
                    onChanged: (v) => setState(() => _aplicaA = v!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _onSave, child: const Text('Guardar')),
      ],
    );
  }
}
