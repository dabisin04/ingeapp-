import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/valor/valor_bloc.dart';
import 'package:inge_app/application/blocs/valor/valor_state.dart';
import 'package:inge_app/presentation/widgets/value_card.dart';
import 'package:inge_app/presentation/widgets/value_card_dialog.dart';

class ValuesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ValorBloc, ValorState>(
      builder: (context, state) {
        if (state is ValorLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (state is ValorLoaded) {
          final tienePresente = state.valores.any((v) => v.tipo == 'Presente');
          final tieneFuturo = state.valores.any((v) => v.tipo == 'Futuro');
          final puedenAnadir = !(tienePresente && tieneFuturo);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Valores', style: Theme.of(context).textTheme.titleLarge),
              ...state.valores.map((v) => ValueCard(valor: v)),
              SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Añadir Valor'),
                onPressed:
                    puedenAnadir
                        ? () => showDialog(
                          context: context,
                          builder: (_) => ValueCardDialog(),
                        )
                        : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ya existe un Presente y un Futuro. Borra uno antes de añadir.',
                              ),
                            ),
                          );
                        },
              ),
            ],
          );
        } else if (state is ValorError) {
          return Text('Error: ${state.mensaje}');
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
