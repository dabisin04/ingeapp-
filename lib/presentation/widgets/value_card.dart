import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/valor/valor_bloc.dart';
import 'package:inge_app/application/blocs/valor/valor_event.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/presentation/widgets/value_card_dialog.dart';

class ValueCard extends StatelessWidget {
  final Valor valor;
  const ValueCard({Key? key, required this.valor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final valorTexto = valor.valor == null
        ? 'Sin valor'
        : (valor.valor is double
            ? '\$${(valor.valor as double).toStringAsFixed(2)}'
            : valor.valor.toString()); // si es String, mostrar como texto

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text('Periodo ${valor.periodo ?? "—"} — ${valor.tipo}'),
        subtitle: Text(valorTexto),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ValueCardDialog(valor: valor),
              ),
            ),
            if (valor.periodo != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  context.read<ValorBloc>().add(
                        EliminarValorEvent(
                          valor.periodo,
                          valor.tipo,
                          valor.flujo,
                        ),
                      );
                },
              ),
          ],
        ),
      ),
    );
  }
}
