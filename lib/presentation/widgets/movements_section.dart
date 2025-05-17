import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_bloc.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_state.dart';
import 'package:inge_app/presentation/widgets/movement_card.dart';
import 'package:inge_app/presentation/widgets/movement_card_dialog.dart';

class MovementsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovimientoBloc, MovimientoState>(
      builder: (context, state) {
        if (state is MovimientoLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (state is MovimientoLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Movimientos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...state.movimientos.map((m) => MovementCard(mov: m)),
              SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Añadir Movimiento'),
                onPressed:
                    () => showDialog(
                      context: context,
                      builder: (_) => MovementCardDialog(),
                    ),
              ),
            ],
          );
        } else if (state is MovimientoError) {
          return Text('Error: ${state.mensaje}');
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
