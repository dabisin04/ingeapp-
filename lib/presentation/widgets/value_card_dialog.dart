import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/valor/valor_state.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/application/blocs/valor/valor_bloc.dart';
import 'package:inge_app/application/blocs/valor/valor_event.dart';

class ValueCardDialog extends StatefulWidget {
  final Valor? valor;
  const ValueCardDialog({Key? key, this.valor}) : super(key: key);

  @override
  _ValueCardDialogState createState() => _ValueCardDialogState();
}

class _ValueCardDialogState extends State<ValueCardDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _periodoCtrl;
  late TextEditingController _valorCtrl;
  late TextEditingController _hastaPeriodoCtrl;
  String? _tipo;
  String _flujo = 'ingreso';
  bool _esSerie = false;
  String _tipoSerie = 'vencida';
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _periodoCtrl = TextEditingController(
      text: widget.valor?.periodo?.toString() ?? '',
    );
    _hastaPeriodoCtrl = TextEditingController(
      text: widget.valor?.hastaPeriodo?.toString() ?? '',
    );
    _valorCtrl = TextEditingController();

    if (widget.valor != null) {
      final val = widget.valor!.valor;
      if (val != null) {
        if (val is double) {
          _valorCtrl.text = val.toStringAsFixed(2);
        } else if (val is String) {
          _valorCtrl.text = val;
        }
      }

      _tipo = widget.valor!.tipo;
      _flujo = widget.valor!.flujo.toLowerCase();
      _esSerie = widget.valor!.esSerie ?? false;
      _tipoSerie = widget.valor!.tipoSerie ?? 'vencida';
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (_esSerie) _animationController.forward();
  }

  @override
  void dispose() {
    _periodoCtrl.dispose();
    _valorCtrl.dispose();
    _hastaPeriodoCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSave() {
    final periodoText = _periodoCtrl.text.trim();
    final valorText = _valorCtrl.text.trim();
    final hastaPeriodoText = _hastaPeriodoCtrl.text.trim();

    final int? periodo = periodoText.isEmpty ? null : int.tryParse(periodoText);
    final int? hastaPeriodo =
        hastaPeriodoText.isEmpty ? null : int.tryParse(hastaPeriodoText);

    dynamic valorFinal;
    if (valorText.isEmpty) {
      valorFinal = null;
    } else if (double.tryParse(valorText) != null) {
      valorFinal = double.parse(valorText);
    } else {
      valorFinal = valorText;
    }

    if (_tipo == null) return;

    final nueva = Valor(
      valor: valorFinal,
      periodo: periodo,
      tipo: _tipo!,
      flujo: _flujo,
      esSerie: _esSerie,
      tipoSerie: _esSerie ? _tipoSerie : null,
      hastaPeriodo: _esSerie ? hastaPeriodo : null,
    );

    final bloc = context.read<ValorBloc>();
    if (widget.valor == null) {
      bloc.add(AgregarValorEvent(nueva));
    } else {
      bloc.add(EditarValorEvent(nueva));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ValorBloc>().state;
    List<String> tiposDisponibles = ['Presente', 'Futuro'];
    if (state is ValorLoaded) {
      final usados = state.valores.map((v) => v.tipo).toSet();
      tiposDisponibles =
          tiposDisponibles.where((t) => !usados.contains(t)).toList();
      if (widget.valor != null &&
          !tiposDisponibles.contains(widget.valor!.tipo)) {
        tiposDisponibles.insert(0, widget.valor!.tipo);
      }
    }

    if (tiposDisponibles.isEmpty) {
      return AlertDialog(
        title: const Text('No hay tipos disponibles'),
        content: const Text(
          'Ya existe un valor Presente y un valor Futuro.\n'
          'Borra uno antes de añadir otro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    final tipoSeleccionado = (_tipo != null && tiposDisponibles.contains(_tipo))
        ? _tipo!
        : tiposDisponibles.first;
    _tipo = tipoSeleccionado;

    return AlertDialog(
      title: Text(widget.valor == null ? 'Añadir Valor' : 'Editar Valor'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _periodoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Periodo (opcional)',
                hintText: 'Déjalo vacío si no aplica',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: tipoSeleccionado,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: tiposDisponibles
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _flujo,
              decoration: const InputDecoration(labelText: 'Flujo'),
              items: const [
                DropdownMenuItem(value: 'ingreso', child: Text('Ingreso')),
                DropdownMenuItem(value: 'egreso', child: Text('Egreso')),
              ],
              onChanged: (v) => setState(() => _flujo = v!),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Es una serie de pagos'),
              value: _esSerie,
              onChanged: (value) {
                setState(() {
                  _esSerie = value;
                  if (value) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                });
              },
            ),
            SizeTransition(
              sizeFactor: _animation,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _tipoSerie,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de Serie'),
                    items: ['anticipada', 'vencida']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _tipoSerie = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hastaPeriodoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hasta Período',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
