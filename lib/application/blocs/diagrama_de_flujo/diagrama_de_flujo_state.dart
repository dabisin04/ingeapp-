import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';

abstract class FlowDiagramState {}

class FlowDiagramInitial extends FlowDiagramState {}

class FlowDiagramLoading extends FlowDiagramState {}

class FlowDiagramLoaded extends FlowDiagramState {
  final DiagramaDeFlujo diagrama;
  final String branch;
  FlowDiagramLoaded(this.diagrama, this.branch);
}

class FlowDiagramError extends FlowDiagramState {
  final String message;

  FlowDiagramError(this.message);
}

class AnalysisInProgress extends FlowDiagramState {}

class AnalysisSuccess extends FlowDiagramState {
  final EquationAnalysis analysis;
  AnalysisSuccess(this.analysis);
}

class AnalysisFailure extends FlowDiagramState {
  final String error;
  AnalysisFailure(this.error);
}
