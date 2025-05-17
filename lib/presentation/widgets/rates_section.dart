import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_bloc.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_state.dart';
import 'package:inge_app/presentation/widgets/rate_card.dart';
import 'package:inge_app/presentation/widgets/rate_card_dialog.dart';
import 'package:inge_app/domain/repositories/unidad_de_tiempo_repository.dart';

class RatesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasaInteresBloc, TasaInteresState>(
      builder: (context, state) {
        if (state is TasaInteresLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (state is TasaInteresLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tasas de Interés',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...state.tasas.map((t) => RateCard(tasa: t)),
              SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Añadir Tasa'),
                onPressed: () {
                  final unidadDeTiempoRepository =
                      context.read<UnidadDeTiempoRepository>();
                  showDialog(
                    context: context,
                    builder:
                        (_) => RateCardDialog(
                          unidadDeTiempoRepository: unidadDeTiempoRepository,
                        ),
                  );
                },
              ),
            ],
          );
        } else if (state is TasaInteresError) {
          return Text('Error: ${state.mensaje}');
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
