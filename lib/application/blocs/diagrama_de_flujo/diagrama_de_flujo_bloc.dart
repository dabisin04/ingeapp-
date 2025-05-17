import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/repositories/diagrama_de_flujo_repository.dart';

import 'diagrama_de_flujo_event.dart';
import 'diagrama_de_flujo_state.dart';

import 'package:inge_app/infrastructure/utils/financial_analyzer.dart';

class FlowDiagramBloc extends Bloc<FlowDiagramEvent, FlowDiagramState> {
  final FlowDiagramRepository repository;

  FlowDiagramBloc({required this.repository}) : super(FlowDiagramInitial()) {
    on<InitializeDiagramEvent>(_onInitializeDiagram);
    on<FetchDiagramEvent>(_onFetchDiagram);
    on<UpdatePeriodsEvent>(_onUpdatePeriods);
    on<ClearDiagramEvent>(_onClearDiagram);
    on<UpdateTasasEvent>(_onUpdateTasas);
    on<UpdateValoresEvent>(_onUpdateValores);
    on<UpdateMovimientosEvent>(_onUpdateMovimientos);
    on<UpdateDescriptionEvent>(_onUpdateDescription);
    on<AnalyzeDiagramEvent>(_onAnalyzeDiagram);
    on<UpdateFocalPeriodEvent>(_onUpdateFocalPeriod);
  }

  //helpers
  FlowDiagramLoaded _loadedState(DiagramaDeFlujo diagram) =>
      FlowDiagramLoaded(diagram, FinancialAnalyzer.branch(diagram));

  Future<void> _onInitializeDiagram(
      InitializeDiagramEvent event, Emitter<FlowDiagramState> emit) async {
    emit(FlowDiagramLoading());
    try {
      await repository.initializeDiagram(
        periods: event.periods,
        unit: event.unit,
        tasas: event.tasas,
        valores: event.valores,
        movimientos: event.movimientos,
        descripcion: event.descripcion,
        periodoFocal: event.periodoFocal,
      );
      final diagram = await repository.getDiagram();
      emit(_loadedState(diagram));
    } catch (e) {
      emit(FlowDiagramError('Error al inicializar: $e'));
    }
  }

  Future<void> _onFetchDiagram(
      FetchDiagramEvent event, Emitter<FlowDiagramState> emit) async {
    emit(FlowDiagramLoading());
    try {
      final diagram = await repository.getDiagram();
      emit(_loadedState(diagram));
    } catch (e) {
      emit(FlowDiagramError('Error al obtener el diagrama: $e'));
    }
  }

  Future<void> _onUpdatePeriods(
      UpdatePeriodsEvent event, Emitter<FlowDiagramState> emit) async {
    emit(FlowDiagramLoading());
    try {
      await repository.updatePeriods(event.periods);
      emit(_loadedState(await repository.getDiagram()));
    } catch (e) {
      emit(FlowDiagramError('Error al actualizar periodos: $e'));
    }
  }

  Future<void> _onClearDiagram(
      ClearDiagramEvent event, Emitter<FlowDiagramState> emit) async {
    emit(FlowDiagramLoading());
    try {
      await repository.clearDiagram();
      emit(FlowDiagramInitial());
    } catch (e) {
      emit(FlowDiagramError('Error al limpiar el diagrama: $e'));
    }
  }

  Future<void> _onUpdateTasas(
      UpdateTasasEvent event, Emitter<FlowDiagramState> emit) async {
    if (state is FlowDiagramLoaded) {
      final updated = (state as FlowDiagramLoaded)
          .diagrama
          .copyWith(tasasDeInteres: event.tasas);
      emit(_loadedState(updated));
    }
  }

  Future<void> _onUpdateValores(
      UpdateValoresEvent event, Emitter<FlowDiagramState> emit) async {
    if (state is FlowDiagramLoaded) {
      final updated = (state as FlowDiagramLoaded)
          .diagrama
          .copyWith(valores: event.valores);
      emit(_loadedState(updated));
    }
  }

  Future<void> _onUpdateMovimientos(
      UpdateMovimientosEvent event, Emitter<FlowDiagramState> emit) async {
    if (state is FlowDiagramLoaded) {
      final updated = (state as FlowDiagramLoaded)
          .diagrama
          .copyWith(movimientos: event.movimientos);
      emit(_loadedState(updated));
    }
  }

  Future<void> _onUpdateDescription(
      UpdateDescriptionEvent event, Emitter<FlowDiagramState> emit) async {
    emit(FlowDiagramLoading());
    try {
      await repository.updateDescription(event.descripcion);
      emit(_loadedState(await repository.getDiagram()));
    } catch (e) {
      emit(FlowDiagramError('Error al actualizar descripción: $e'));
    }
  }

  Future<void> _onAnalyzeDiagram(
    AnalyzeDiagramEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    final diagram = state is FlowDiagramLoaded
        ? (state as FlowDiagramLoaded).diagrama
        : null;

    if (diagram == null) {
      emit(AnalysisFailure('No hay diagrama para analizar'));
      return;
    }

    emit(AnalysisInProgress());

    try {
      final result = await repository.analyzeDiagram(diagram);
      emit(AnalysisSuccess(result));
    } catch (e) {
      emit(AnalysisFailure('Error al analizar: $e'));
    }
  }

  Future<void> _onUpdateFocalPeriod(
      UpdateFocalPeriodEvent event, Emitter<FlowDiagramState> emit) async {
    emit(FlowDiagramLoading());
    try {
      await repository.updateFocalPeriod(event.periodoFocal);
      emit(_loadedState(await repository.getDiagram()));
    } catch (e) {
      emit(FlowDiagramError('Error al actualizar periodo focal: $e'));
    }
  }
}
