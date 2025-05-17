import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';

import 'financial_analysis.dart';
import 'financial_analysis_pvfv.dart';
import 'financial_analysis_irr.dart';
import 'financial_analysis_multiple_unknowns.dart';
import 'financial_analysis_single_unknown.dart';

class FinancialAnalyzer {
  /* ────────────────── Función de Debug ─────────────────────── */

  static void debugPrintDiagramaDeFlujo(DiagramaDeFlujo d) {
    print('═════════════════════════════════════════════════════════');
    print('📋 Diagrama recibido:');
    print('Unidad de Tiempo: ${d.unidadDeTiempo.nombre}');
    print('Cantidad de Periodos: ${d.cantidadDePeriodos}');
    print('Periodo Focal: ${d.periodoFocal}');
    print('── Tasas de Interés ──');
    for (final t in d.tasasDeInteres) {
      print('• Desde ${t.periodoInicio} hasta ${t.periodoFin} => '
          'Valor: ${(t.valor * 100).toStringAsFixed(6)}% '
          '(Tipo: ${t.tipo}, Aplica: ${t.aplicaA}) '
          '[Periodicidad: ${t.periodicidad.nombre}, Capitalización: ${t.capitalizacion.nombre}]');
    }
    print('── Valores ──');
    for (final v in d.valores) {
      print('• Tipo: ${v.tipo}, Flujo: ${v.flujo}, '
          'Periodo: ${v.periodo?.toString() ?? "null"}, '
          'Valor: ${v.valor}');
    }
    print('── Movimientos ──');
    for (final m in d.movimientos) {
      print('• Tipo: ${m.tipo}, '
          'Periodo: ${m.periodo?.toString() ?? "null"}, '
          'Valor: ${m.valor}');
    }
    print('═════════════════════════════════════════════════════════');
  }

  /* ────────────────── Selección de rama ─────────────────────── */

  static String branch(DiagramaDeFlujo d) {
    final hasRates = d.tasasDeInteres.isNotEmpty;

    // Detectar incógnitas (strings containing "X")
    final xCount = detectarIncognitas(d);

    // Detectar flujos con periodo desconocido
    final hasUnknownPeriodWithValue =
        d.movimientos.any((m) => m.periodo == null && m.valor != null) ||
            d.valores.any((v) => v.periodo == null && v.valor != null);

    // Detectar valores nulos o "X" para PV/FV
    final valoresNull = d.valores.where((v) => v.valor == null).toList();
    final valoresX = d.valores
        .where((v) =>
            v.valor is String &&
            (v.valor as String).trim().toUpperCase().contains('X'))
        .toList();
    final hasPVFVUnknown = (valoresNull.length + valoresX.length == 1);
    bool isPVFVPositionValid = false;
    if (hasPVFVUnknown) {
      final unknown =
          valoresNull.isNotEmpty ? valoresNull.first : valoresX.first;
      final periods = <int?>[];
      periods
          .addAll(d.movimientos.map((m) => m.periodo).where((p) => p != null));
      periods.addAll(d.valores.map((v) => v.periodo).where((p) => p != null));
      if (periods.isNotEmpty) {
        final maxPeriod = periods.cast<int>().reduce((a, b) => a > b ? a : b);
        isPVFVPositionValid =
            unknown.periodo == 0 || unknown.periodo == maxPeriod;
      }
    }

    // IRR: No rates provided (rate is the unknown)
    if (!hasRates) {
      return 'IRR simple';
    }

    // Period (n): At least one cash flow with unknown period and known value
    if (hasRates && hasUnknownPeriodWithValue) {
      return 'Periodos (n)';
    }

    // PV/FV: Exactly one unknown (null or "X") at t=0 or t=maxPeriod
    if (hasRates && hasPVFVUnknown && isPVFVPositionValid) {
      return 'VP / VF';
    }

    // Single Unknown: Exactly one occurrence of "X"
    if (hasRates && xCount == 1) {
      return 'Valor desconocido (X) - Una incógnita';
    }

    // Multiple Unknowns: More than one occurrence of "X"
    if (hasRates && xCount > 1) {
      return 'Valor desconocido (X) - Múltiples incógnitas';
    }

    // Default case when rates are provided but no unknowns
    if (hasRates) {
      return 'Cálculo de NPV con periodo focal';
    }

    throw StateError(
        'No se pudo determinar el tipo de análisis para el diagrama proporcionado.');
  }

  /* ──────────────────── Ejecución de análisis ────────────────── */

  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    // Debug output
    debugPrintDiagramaDeFlujo(d);

    final hasRates = d.tasasDeInteres.isNotEmpty;

    // Detectar incógnitas
    final xCount = detectarIncognitas(d);

    // Detectar flujos con periodo desconocido
    final hasUnknownPeriodWithValue =
        d.movimientos.any((m) => m.periodo == null && m.valor != null) ||
            d.valores.any((v) => v.periodo == null && v.valor != null);

    // Detectar valores nulos o "X" para PV/FV
    final valoresNull = d.valores.where((v) => v.valor == null).toList();
    final valoresX = d.valores
        .where((v) =>
            v.valor is String &&
            (v.valor as String).trim().toUpperCase().contains('X'))
        .toList();
    final hasPVFVUnknown = (valoresNull.length + valoresX.length == 1);
    bool isPVFVPositionValid = false;
    if (hasPVFVUnknown) {
      final unknown =
          valoresNull.isNotEmpty ? valoresNull.first : valoresX.first;
      final periods = <int?>[];
      periods
          .addAll(d.movimientos.map((m) => m.periodo).where((p) => p != null));
      periods.addAll(d.valores.map((v) => v.periodo).where((p) => p != null));
      if (periods.isNotEmpty) {
        final maxPeriod = periods.cast<int>().reduce((a, b) => a > b ? a : b);
        isPVFVPositionValid =
            unknown.periodo == 0 || unknown.periodo == maxPeriod;
      }
    }

    // IRR: No rates provided
    if (!hasRates) {
      return FinancialAnalysisIRR.analyze(d);
    }

    // Period (n): At least one cash flow with unknown period and known value
    if (hasRates && hasUnknownPeriodWithValue) {
      return FinancialAnalysis.analyze(d);
    }

    // PV/FV: Exactly one unknown (null or "X") at t=0 or t=maxPeriod
    if (hasRates && hasPVFVUnknown && isPVFVPositionValid) {
      return FinancialAnalysisPVFV.analyze(d);
    }

    // Single Unknown: Exactly one occurrence of "X"
    if (hasRates && xCount == 1) {
      return FinancialAnalysisSingleUnknown.analyze(d);
    }

    // Multiple Unknowns: More than one occurrence of "X"
    if (hasRates && xCount > 1) {
      return FinancialAnalysisUnknown.analyze(d);
    }

    // Default: Calculate NPV with focal period (no unknowns)
    if (hasRates) {
      // Since we don't have a specific class for this, we can use FinancialAnalysisPVFV
      // with no unknowns to compute NPV at the focal period
      return FinancialAnalysisPVFV.analyze(d);
    }

    throw StateError(
        'No se pudo determinar el tipo de análisis para el diagrama proporcionado.');
  }

  /* ──────────────────── Función para detectar incógnitas ────────────────── */

  static int detectarIncognitas(DiagramaDeFlujo d) {
    int xCount = 0;

    // Revisamos todos los valores y movimientos buscando "X" en cualquier forma
    final allValores = <dynamic>[
      ...d.movimientos.map((m) => m.valor),
      ...d.valores.map((v) => v.valor),
    ];

    for (final valor in allValores) {
      if (valor != null &&
          valor is String &&
          valor.toString().toUpperCase().contains('X')) {
        xCount++;
      }
    }

    return xCount;
  }
}
