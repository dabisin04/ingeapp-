import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_bloc.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_event.dart';

class MovementCardDialog extends StatefulWidget {
  final Movimiento? mov;
  const MovementCardDialog({Key? key, this.mov}) : super(key: key);

  @override
  _MovementCardDialogState createState() => _MovementCardDialogState();
}

class _MovementCardDialogState extends State<MovementCardDialog>
    with SingleTickerProviderStateMixin {
  final _periodoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _hastaPeriodoCtrl = TextEditingController();
  String _tipo = 'ingreso';
  bool _esSerie = false;
  String _tipoSerie = 'vencida';
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (widget.mov != null) {
      _periodoCtrl.text = widget.mov!.periodo?.toString() ?? '';
      _hastaPeriodoCtrl.text = widget.mov!.hastaPeriodo?.toString() ?? '';
      final val = widget.mov!.valor;
      _valorCtrl.text = val == null
          ? ''
          : (val is double)
              ? val.toStringAsFixed(2)
              : val.toString();
      final tipo = widget.mov!.tipo.toLowerCase().trim();
      if (tipo == 'ingreso' || tipo == 'egreso') _tipo = tipo;
      _esSerie = widget.mov!.esSerie;
      _tipoSerie = widget.mov!.tipoSerie ?? 'vencida';
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

    final nuevo = Movimiento(
      id: widget.mov?.id ?? DateTime.now().millisecondsSinceEpoch,
      periodo: periodo,
      valor: valorFinal,
      tipo: _tipo,
      esSerie: _esSerie,
      tipoSerie: _esSerie ? _tipoSerie : null,
      hastaPeriodo: _esSerie ? hastaPeriodo : null,
    );

    final bloc = context.read<MovimientoBloc>();
    widget.mov == null
        ? bloc.add(AgregarMovimiento(nuevo))
        : bloc.add(EditarMovimiento(nuevo));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.mov == null ? 'Añadir Movimiento' : 'Editar Movimiento',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _tipo,
              items: ['ingreso', 'egreso']
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() + t.substring(1)),
                      ))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Tipo'),
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _periodoCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Periodo (opcional)',
                hintText: 'Déjalo vacío si no aplica',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor (\$)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Serie',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                    ),
                    items: ['anticipada', 'vencida']
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t[0].toUpperCase() + t.substring(1)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _tipoSerie = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hastaPeriodoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Hasta Período',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
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
        ElevatedButton.icon(
          onPressed: _onSave,
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
