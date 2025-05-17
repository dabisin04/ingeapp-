import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_bloc.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_event.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_state.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

class UnitDropdownWidget extends StatelessWidget {
  const UnitDropdownWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnidadDeTiempoBloc, UnidadDeTiempoState>(
      builder: (context, state) {
        if (state is UnidadDeTiempoLoaded) {
          return DropdownButtonFormField<UnidadDeTiempo>(
            decoration: const InputDecoration(
              labelText: 'Unidad de Tiempo',
              border: OutlineInputBorder(),
            ),
            items: state.unidades.map((u) {
              return DropdownMenuItem<UnidadDeTiempo>(
                value: u,
                child: Text('${u.nombre} (${u.valor})'),
              );
            }).toList(),
            value: state.seleccionada,
            onChanged: (UnidadDeTiempo? e) {
              if (e != null) {
                context.read<UnidadDeTiempoBloc>().add(
                      SeleccionarUnidadDeTiempo(unidad: e),
                    );
              }
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
