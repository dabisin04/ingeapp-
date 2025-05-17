import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/entities/valor.dart';

abstract class FlowDiagramRepository {
  Future<DiagramaDeFlujo> getDiagram();
  Future<void> initializeDiagram({
    required int periods,
    required UnidadDeTiempo unit,
    List<TasaDeInteres>? tasas,
    List<Valor>? valores,
    List<Movimiento>? movimientos,
    String? descripcion,
    int? periodoFocal,
  });
  Future<void> updatePeriods(int periods);
  Future<void> clearDiagram();
  Future<void> updateTasas(List<TasaDeInteres> tasas);
  Future<void> updateValores(List<Valor> valores);
  Future<void> updateMovimientos(List<Movimiento> movimientos);
  Future<void> updateDescription(String descripcion);
  Future<List<DiagramaDeFlujo>> getHistory();
  Future<EquationAnalysis> analyzeDiagram(DiagramaDeFlujo diagram);
  Future<void> updateFocalPeriod(int? periodoFocal);
}
