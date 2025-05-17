import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/infrastructure/adapters/diagrama_de_flujo_repository_impl.dart';
import 'package:inge_app/infrastructure/adapters/movimiento_repository_impl.dart';
import 'package:inge_app/infrastructure/adapters/tasa_de_interes_repository_impl.dart';
import 'package:inge_app/infrastructure/adapters/unidad_de_tiempo_repository_impl.dart';
import 'package:inge_app/domain/repositories/unidad_de_tiempo_repository.dart';
import 'package:inge_app/domain/repositories/diagrama_de_flujo_repository.dart';
import 'package:inge_app/domain/repositories/tasa_de_interes_repository.dart';
import 'package:inge_app/domain/repositories/movimiento_repository.dart';
import 'package:inge_app/domain/repositories/valor_repository.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_bloc.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_bloc.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_bloc.dart';
import 'package:inge_app/application/blocs/valor/valor_bloc.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_event.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_event.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_event.dart';
import 'package:inge_app/application/blocs/valor/valor_event.dart';
import 'package:inge_app/infrastructure/adapters/valor_repository_impl.dart';
import 'package:inge_app/presentation/screens/flow.dart';

void main() {
  // Instancias de los adapters
  final unidadRepo = UnidadDeTiempoAdapter();
  final flowRepo = FlowDiagramAdapter();
  final tasasRepo = TasaInteresAdapter();
  final movimientosRepo = MovementAdapter();
  final valorRepo = ValorAdapter();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UnidadDeTiempoRepository>.value(value: unidadRepo),
        RepositoryProvider<FlowDiagramRepository>.value(value: flowRepo),
        RepositoryProvider<TasaInteresRepository>.value(value: tasasRepo),
        RepositoryProvider<MovementRepository>.value(value: movimientosRepo),
        RepositoryProvider<ValorRepository>.value(value: valorRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<UnidadDeTiempoBloc>(
            create:
                (_) =>
                    UnidadDeTiempoBloc(repository: unidadRepo)
                      ..add(CargarUnidadesDeTiempo()),
          ),
          BlocProvider<FlowDiagramBloc>(
            create: (_) => FlowDiagramBloc(repository: flowRepo),
          ),
          BlocProvider<TasaInteresBloc>(
            create:
                (_) =>
                    TasaInteresBloc(repository: tasasRepo)
                      ..add(CargarTasasInteres()),
          ),
          BlocProvider<MovimientoBloc>(
            create:
                (_) =>
                    MovimientoBloc(repository: movimientosRepo)
                      ..add(CargarMovimientos()),
          ),
          BlocProvider<ValorBloc>(
            create:
                (_) =>
                    ValorBloc(repository: valorRepo)..add(CargarValoresEvent()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diagrama de Flujo Económico',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF75),
          secondary: Color(0xFF3700FF),
        ),
      ),
      home: FlowScreen(),
    );
  }
}
