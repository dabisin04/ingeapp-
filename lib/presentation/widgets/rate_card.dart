import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/repositories/unidad_de_tiempo_repository.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_bloc.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_event.dart';

import 'rate_card_dialog.dart';

class RateCard extends StatelessWidget {
  final TasaDeInteres tasa;
  const RateCard({Key? key, required this.tasa}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final esAnt = tasa.tipo.toLowerCase() == 'anticipada';

    // Si aplica a “Todos” no lo mostramos en la tarjeta
    final aplicaStr =
        tasa.aplicaA == 'Todos' ? '' : ' • Aplica: ${tasa.aplicaA}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          '${(tasa.valor * 100).toStringAsFixed(2)}% '
          '(${esAnt ? "Ant." : "Ven."})$aplicaStr',
        ),
        subtitle: Text(
          'Período: ${tasa.periodoInicio} → ${tasa.periodoFin}\n'
          'Periodicidad: ${tasa.periodicidad.nombre}, '
          'Capitalización: ${tasa.capitalizacion.nombre}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                final unidadRepo = context.read<UnidadDeTiempoRepository>();
                showDialog(
                  context: context,
                  builder: (_) => RateCardDialog(
                    tasa: tasa,
                    unidadDeTiempoRepository: unidadRepo,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => context
                  .read<TasaInteresBloc>()
                  .add(EliminarTasaInteres(tasa.id)),
            ),
          ],
        ),
      ),
    );
  }
}
