import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/infrastructure/utils/irr_utils.dart';

class FinancialAnalysisIRR {
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[];
    final focal = d.periodoFocal ?? 0;

    final movs = d.movimientos
        .where((m) => m.periodo != null && m.valor is double)
        .toList();
    final vals =
        d.valores.where((v) => v.periodo != null && v.valor is double).toList();

    final terms = <String>[];

    for (var m in movs) {
      final period = m.periodo!;
      final n = focal - period;
      final sign = m.tipo == 'ingreso' ? '+' : '-';
      final value = (m.valor as double).toStringAsFixed(2);
      final exponent = n == 0 ? '' : '^${n > 0 ? n : '(${n})'}';
      terms.add('$sign$value*(1+i)$exponent');
    }

    for (var v in vals) {
      final period = v.periodo!;
      final n = focal - period;
      final sign = v.flujo == 'ingreso' ? '+' : '-';
      final value = (v.valor as double).toStringAsFixed(2);
      final exponent = n == 0 ? '' : '^${n > 0 ? n : '(${n})'}';
      terms.add('$sign$value*(1+i)$exponent');
    }

    final eq = '${terms.join(" ")} = 0';

    final rate = IRRUtils.solveIRR(
      movs: movs,
      vals: vals,
      focalPeriod: focal,
    );

    return EquationAnalysis(
      equation: eq,
      steps: steps,
      solution: rate,
    );
  }
}
