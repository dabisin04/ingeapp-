// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_bloc.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_event.dart';
import 'package:inge_app/presentation/widgets/movement_card_dialog.dart';

class MovementCard extends StatelessWidget {
  final Movimiento mov;
  const MovementCard({Key? key, required this.mov}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final valorTexto = mov.valor == null
        ? '—'
        : (mov.valor is double
            ? '\$${(mov.valor as double).toStringAsFixed(2)}'
            : mov.valor.toString());

    final isIngreso = mov.tipo == 'ingreso';
    final color = isIngreso ? Colors.green : Colors.red;
    final icon = isIngreso ? Icons.arrow_downward : Icons.arrow_upward;

    String periodoTexto = 'Periodo ${mov.periodo ?? "—"}';
    if (mov.esSerie && mov.hastaPeriodo != null) {
      periodoTexto += ' → ${mov.hastaPeriodo}';
      if (mov.tipoSerie != null) {
        periodoTexto +=
            ' (${mov.tipoSerie![0].toUpperCase()}${mov.tipoSerie!.substring(1)})';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          '${mov.tipo[0].toUpperCase()}${mov.tipo.substring(1)} — $periodoTexto',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(valorTexto),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => MovementCardDialog(mov: mov),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                context.read<MovimientoBloc>().add(EliminarMovimiento(mov));
              },
            ),
          ],
        ),
      ),
    );
  }
}
