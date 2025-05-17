import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/entities/valor.dart';

abstract class FlowDiagramEvent {}

class InitializeDiagramEvent extends FlowDiagramEvent {
  final int periods;
  final UnidadDeTiempo unit;
  final List<TasaDeInteres>? tasas;
  final List<Valor>? valores;
  final List<Movimiento>? movimientos;
  final String? descripcion;
  final int? periodoFocal;

  InitializeDiagramEvent({
    required this.periods,
    required this.unit,
    this.tasas,
    this.valores,
    this.movimientos,
    this.descripcion,
    this.periodoFocal,
  });
}

class FetchDiagramEvent extends FlowDiagramEvent {}

class UpdatePeriodsEvent extends FlowDiagramEvent {
  final int periods;

  UpdatePeriodsEvent({required this.periods});
}

class ClearDiagramEvent extends FlowDiagramEvent {}

class UpdateTasasEvent extends FlowDiagramEvent {
  final List<TasaDeInteres> tasas;
  UpdateTasasEvent(this.tasas);
}

class UpdateValoresEvent extends FlowDiagramEvent {
  final List<Valor> valores;
  UpdateValoresEvent(this.valores);
}

class UpdateMovimientosEvent extends FlowDiagramEvent {
  final List<Movimiento> movimientos;
  UpdateMovimientosEvent(this.movimientos);
}

class UpdateDescriptionEvent extends FlowDiagramEvent {
  final String descripcion;

  UpdateDescriptionEvent(this.descripcion);
}

class AnalyzeDiagramEvent extends FlowDiagramEvent {}

class UpdateFocalPeriodEvent extends FlowDiagramEvent {
  final int? periodoFocal;
  UpdateFocalPeriodEvent(this.periodoFocal);
}
