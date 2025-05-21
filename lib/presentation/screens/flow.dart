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
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/presentation/widgets/description_section.dart';
import 'package:inge_app/presentation/widgets/equation_section.dart';
import 'package:inge_app/presentation/widgets/focal_period_section.dart';
import 'package:inge_app/presentation/widgets/period_input_widget.dart';
import 'package:inge_app/presentation/widgets/unit_dropdown_widget.dart';
import 'package:inge_app/presentation/widgets/rates_section.dart';
import 'package:inge_app/presentation/widgets/values_section.dart';
import 'package:inge_app/presentation/widgets/movements_section.dart';
import 'package:inge_app/presentation/widgets/flow_diagram_widget.dart';

class FlowScreen extends StatefulWidget {
  @override
  _FlowScreenState createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  final List<EquationAnalysis> _historial = [];

  void _agregarAlHistorial(EquationAnalysis analisis) {
    setState(() {
      _historial.insert(0, analisis);
      if (_historial.length > 10) {
        _historial.removeLast();
      }
    });
  }

  void _mostrarHistorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historial de Análisis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _historial.isEmpty
                  ? Center(
                      child: Text(
                        'No hay análisis en el historial',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _historial.length,
                      itemBuilder: (context, index) {
                        final analisis = _historial[index];
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              'Ecuación: ${analisis.equation}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Solución: ${analisis.solution}'),
                                Text(
                                  'Pasos: ${analisis.steps.length}',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Icon(Icons.history),
                            onTap: () {
                              // Aquí podrías mostrar más detalles del análisis
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Detalles del Análisis'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Ecuación: ${analisis.equation}'),
                                        SizedBox(height: 8),
                                        Text('Solución: ${analisis.solution}'),
                                        SizedBox(height: 16),
                                        Text('Pasos:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        ...analisis.steps.map((step) => Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16),
                                              child: Text('• $step'),
                                            )),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cerrar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

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
        appBar: AppBar(
          title: Text('Diagrama de Flujo Económico'),
          actions: [
            IconButton(
              icon: Icon(Icons.history),
              onPressed: _mostrarHistorial,
              tooltip: 'Ver historial',
            ),
          ],
        ),
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
              BlocListener<FlowDiagramBloc, FlowDiagramState>(
                listener: (context, state) {
                  if (state is AnalysisSuccess) {
                    _agregarAlHistorial(state.analysis);
                  }
                },
                child: const AnalysisSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
