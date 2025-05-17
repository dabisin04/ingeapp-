import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_event.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_state.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_bloc.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_state.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_bloc.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_state.dart';
import 'package:inge_app/application/blocs/valor/valor_bloc.dart';
import 'package:inge_app/application/blocs/valor/valor_state.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_bloc.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_state.dart';
import 'package:inge_app/presentation/widgets/description_section.dart';
import 'package:inge_app/presentation/widgets/equation_section.dart';
import 'package:inge_app/presentation/widgets/focal_period_section.dart';
import 'package:inge_app/presentation/widgets/period_input_widget.dart';
import 'package:inge_app/presentation/widgets/unit_dropdown_widget.dart';
import 'package:inge_app/presentation/widgets/rates_section.dart';
import 'package:inge_app/presentation/widgets/values_section.dart';
import 'package:inge_app/presentation/widgets/movements_section.dart';
import 'package:inge_app/presentation/widgets/flow_diagram_widget.dart';

class FlowScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final flowBloc = context.read<FlowDiagramBloc>();

    return MultiBlocListener(
      listeners: [
        // 1) Cuando cambian las tasas, actualizamos la capa visual de tasas
        BlocListener<TasaInteresBloc, TasaInteresState>(
          listener: (ctx, tasaState) {
            if (tasaState is TasaInteresLoaded) {
              ctx.read<FlowDiagramBloc>().add(
                    UpdateTasasEvent(tasaState.tasas),
                  );
            }
          },
        ),
        // 2) Cuando cambian los valores, actualizamos la capa de valores
        BlocListener<ValorBloc, ValorState>(
          listener: (ctx, valorState) {
            if (valorState is ValorLoaded) {
              ctx.read<FlowDiagramBloc>().add(
                    UpdateValoresEvent(valorState.valores),
                  );
            }
          },
        ),
        // 3) Cuando cambian los movimientos, actualizamos la capa de movimientos
        BlocListener<MovimientoBloc, MovimientoState>(
          listener: (ctx, movState) {
            if (movState is MovimientoLoaded) {
              ctx.read<FlowDiagramBloc>().add(
                    UpdateMovimientosEvent(movState.movimientos),
                  );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text('Diagrama de Flujo Económico')),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 0) Descripción del diagrama
              const DescriptionSection(),

              // 1) Periodo focal
              const FocalPeriodSection(),

              // 2) Periodos + unidad
              PeriodInputWidget(
                onSubmit: (periods) {
                  final unitState = context.read<UnidadDeTiempoBloc>().state;
                  if (unitState is UnidadDeTiempoLoaded &&
                      unitState.seleccionada != null) {
                    // Fetch existing data from other BLoCs
                    final tasaState = context.read<TasaInteresBloc>().state;
                    final valorState = context.read<ValorBloc>().state;
                    final movimientoState =
                        context.read<MovimientoBloc>().state;
                    final flowState = context.read<FlowDiagramBloc>().state;

                    // Extract rates, values, movements, description, and focal period
                    final tasas = tasaState is TasaInteresLoaded
                        ? tasaState.tasas
                        : null; // Nullable
                    final valores = valorState is ValorLoaded
                        ? valorState.valores
                        : null; // Nullable
                    final movimientos = movimientoState is MovimientoLoaded
                        ? movimientoState.movimientos
                        : null; // Nullable
                    final descripcion = flowState is FlowDiagramLoaded
                        ? flowState.diagrama.descripcion
                        : null; // Nullable
                    final periodoFocal = flowState is FlowDiagramLoaded
                        ? flowState.diagrama.periodoFocal
                        : null; // Nullable

                    // Dispatch the event with existing data (nullable fields)
                    flowBloc.add(
                      InitializeDiagramEvent(
                        periods: periods,
                        unit: unitState.seleccionada!,
                        tasas: tasas,
                        valores: valores,
                        movimientos: movimientos,
                        descripcion: descripcion,
                        periodoFocal: periodoFocal,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Seleccione primero la unidad de tiempo'),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 16),

              // 3) Unidad de tiempo
              UnitDropdownWidget(),

              SizedBox(height: 24),

              // 4) Tasas, valores y movimientos
              RatesSection(),
              Divider(),
              ValuesSection(),
              Divider(),
              MovementsSection(),

              SizedBox(height: 24),

              // 5) Vista del diagrama
              BlocBuilder<FlowDiagramBloc, FlowDiagramState>(
                builder: (_, state) {
                  if (state is FlowDiagramLoaded) {
                    return FlowDiagramWidget(diagram: state.diagrama);
                  } else if (state is FlowDiagramLoading) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    return Text(
                      'Inicie un diagrama arriba',
                      textAlign: TextAlign.center,
                    );
                  }
                },
              ),

              // 6) Botón de análisis
              const AnalysisSection(),
            ],
          ),
        ),
      ),
    );
  }
}
