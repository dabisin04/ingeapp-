import 'dart:math';

import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

class FinancialAnalysisTwoUnknownsBalance {
  /*────────────────────  DETECCIÓN  ────────────────────*/
  static bool isCandidate(DiagramaDeFlujo d) {
    final series = <dynamic>[
      ...d.valores,
      ...d.movimientos,
    ].where((u) => (u as dynamic).esSerie == true).toList();
    if (series.length != 1) return false;

    final pFlowsT0 = <dynamic>[
      ...d.valores,
      ...d.movimientos,
    ].where((u) {
      final dyn = u as dynamic;
      return (dyn.periodo ?? 0) == 0 &&
          dyn.valor is String &&
          (dyn.valor as String).toUpperCase().contains('P');
    }).toList();
    if (pFlowsT0.isEmpty) return false;

    final saldoNum = <dynamic>[
      ...d.valores,
      ...d.movimientos,
    ].where((u) {
      final dyn = u as dynamic;
      return dyn.esSerie != true && dyn.valor is num && (dyn.periodo ?? 0) > 0;
    }).toList();
    if (saldoNum.length != 1) return false;

    return true;
  }

  /*────────────────────  ANÁLISIS  ────────────────────*/
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    if (!isCandidate(d)) {
      throw StateError('No es patrón serie-saldo con dos incógnitas.');
    }

    // 1) Serie uniforme
    final serie = (<dynamic>[
      ...d.valores,
      ...d.movimientos,
    ]).firstWhere((u) => (u as dynamic).esSerie == true);

    // 2) Flujos “P” en t=0
    final pFlowsT0 = (<dynamic>[
      ...d.valores,
      ...d.movimientos,
    ]).where((u) {
      final dyn = u as dynamic;
      return (dyn.periodo ?? 0) == 0 &&
          dyn.valor is String &&
          (dyn.valor as String).toUpperCase().contains('P');
    }).toList();

    // 3) Saldo numérico en t>0
    final saldo = (<dynamic>[
      ...d.valores,
      ...d.movimientos,
    ]).firstWhere((u) {
      final dyn = u as dynamic;
      return dyn.esSerie != true && dyn.valor is num && (dyn.periodo ?? 0) > 0;
    });

    // 4) α = suma(signo * coef) de cada flujo P en t=0
    double _coefSign(dynamic u) {
      final dyn = u as dynamic;
      // Extraer coeficiente numérico de "P"
      final txt = (dyn.valor as String)
          .toUpperCase()
          .replaceAll('%', '')
          .replaceAll(' ', '');
      final m = RegExp(r'^([+\-]?[0-9]*\.?[0-9]+)?P$').firstMatch(txt);
      final coef = (m != null && m.group(1)?.isNotEmpty == true)
          ? double.parse(m.group(1)!)
          : 1.0;

      // Determinar si es ingreso o egreso:
      // Valor tiene 'flujo', Movimiento solo 'tipo'
      String flujoStr;
      try {
        flujoStr = (dyn as dynamic).flujo as String;
      } catch (_) {
        flujoStr = (dyn as dynamic).tipo as String;
      }

      final tipoNorm = RateConversionUtils.normalizeTipo(flujoStr);
      return tipoNorm == 'ingreso' ? coef : -coef;
    }

    final alpha = pFlowsT0.map(_coefSign).fold<double>(0, (sum, c) => sum + c);

    // 5) Tasa periódica y conteo de periodos
    final i = RateConversionUtils.periodicRateForDiagram(
      tasa: d.tasasDeInteres.first,
      unidadObjetivo: d.unidadDeTiempo,
    );
    final start = (serie as dynamic).periodo as int;
    final end = (serie as dynamic).hastaPeriodo as int;
    final nTotal = end - start + 1;
    final k = (saldo as dynamic).periodo as int;
    final nRest = nTotal - k;

    // 6) Factores PV ordinarios
    double _pv(int n) => (pow(1 + i, n) - 1) / (i * pow(1 + i, n));
    final fpvTotal = _pv(nTotal);
    final fpvRest = _pv(nRest);

    // 7) Resolver sistema 2×2:
    //    E2) A = saldo / fpvRest
    final A = ((saldo as dynamic).valor as num) / fpvRest;
    //    E1) α·P = A·fpvTotal  →  P = (A·fpvTotal) / α
    final P = (A * fpvTotal) / alpha;

    return EquationAnalysis(
      equation:
          'E1) ${alpha.toStringAsFixed(3)}·P = A × ${fpvTotal.toStringAsFixed(6)}\n'
          'E2) saldo = A × ${fpvRest.toStringAsFixed(6)}',
      steps: [
        'α = ${alpha.toStringAsFixed(3)}',
        'i = ${(i * 100).toStringAsFixed(3)} %',
        'serie t=$start→$end (n=$nTotal), k=$k, faltan=$nRest',
        'A = \$${A.toStringAsFixed(2)}',
        'P = \$${P.toStringAsFixed(2)}',
      ],
      solution: P,
    );
  }
}
