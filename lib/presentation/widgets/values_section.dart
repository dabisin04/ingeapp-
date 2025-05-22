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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Valores', style: Theme.of(context).textTheme.titleLarge),
              ...state.valores.map((v) => ValueCard(valor: v)),
              SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Añadir Valor'),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => ValueCardDialog(),
                ),
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
