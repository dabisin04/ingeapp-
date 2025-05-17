import 'dart:math';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

class FinancialAnalysisPVFV {
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[];

    /* ── 1) Validaciones ─────────────────────────────────────── */
    if (d.tasasDeInteres.isEmpty) {
      throw StateError('Se necesita al menos una tasa de interés.');
    }

    // Determinar el periodo máximo del diagrama
    final periods = <int?>[];
    periods.addAll(d.movimientos.map((m) => m.periodo).where((p) => p != null));
    periods.addAll(d.valores.map((v) => v.periodo).where((p) => p != null));
    if (periods.isEmpty) {
      throw StateError('El diagrama debe tener al menos un periodo definido.');
    }
    final int maxPeriod = periods.cast<int>().reduce((a, b) => a > b ? a : b);

    // Validar periodo focal
    final int focal = d.periodoFocal ?? 0;
    if (focal != 0 && focal != maxPeriod && focal != d.cantidadDePeriodos) {
      throw StateError(
        'El periodo focal debe ser 0 (para Valor Presente) o $maxPeriod/$d.cantidadDePeriodos (para Valor Futuro).',
      );
    }
    final bool isPresentValue = focal == 0;

    // Buscar una incógnita (opcional): valor nulo o "X"
    final valoresNull = d.valores.where((v) => v.valor == null).toList();
    final valoresX = d.valores
        .where((v) =>
            v.valor is String &&
            (v.valor as String).trim().toUpperCase() == 'X')
        .toList();
    final hasUnknown = valoresNull.length + valoresX.length == 1;
    if (valoresNull.length + valoresX.length > 1) {
      throw StateError(
        'No puede haber más de una incógnita (valor=null o "X").',
      );
    }
    final Valor? valorInc = hasUnknown
        ? (valoresNull.isNotEmpty ? valoresNull.single : valoresX.single)
        : null;

    // Validar que la incógnita esté en t=0 o t=maxPeriod
    if (hasUnknown) {
      final unknownPeriod = valorInc!.periodo;
      if (unknownPeriod != 0 && unknownPeriod != maxPeriod) {
        throw StateError(
          'La incógnita debe estar en t=0 o t=$maxPeriod para calcular Valor Presente o Futuro.',
        );
      }
    }

    /* ── 2) Normalizar tasas a periódica efectiva ────────────── */
    final tasa = d.tasasDeInteres.first;
    final conversionResult = RateConversionUtils.detailedConversion(
      tasa: tasa,
      unidadObjetivo: d.unidadDeTiempo,
    );
    final effectiveRate = conversionResult.rate;
    steps.addAll(conversionResult.steps);
    steps.add(
        'Tasa efectiva ${d.unidadDeTiempo.nombre}: ${(effectiveRate * 100).toStringAsFixed(6)}%');

    /* ── 3) Calcular PV y FV ─────────────────────────────── */
    double pvInflows = 0.0, pvOutflows = 0.0;
    double fvInflows = 0.0, fvOutflows = 0.0;
    String pvEquation = '';

    // Función para calcular el factor de descuento (PV) o capitalización (FV)
    double _pvFactor(int periodo) {
      final n = periodo; // Desde t hasta 0
      return 1 / pow(1 + effectiveRate, n);
    }

    double _fvFactor(int periodo) {
      final n = focal - periodo; // Desde t hasta el periodo focal
      return pow(1 + effectiveRate, n).toDouble();
    }

    // Procesar los movimientos
    for (final m in d.movimientos) {
      if (m.periodo == null || m.valor == null) continue;
      final sign =
          (RateConversionUtils.normalizeTipo(m.tipo) == 'ingreso') ? -1 : 1;
      final amount = (m.valor as double);
      final pvContribution = amount * _pvFactor(m.periodo!);
      final fvContribution = amount * _fvFactor(m.periodo!);
      print(
          "fvContribution: $fvContribution, amount: $amount, n=${m.periodo}, _fvFactor: ${_fvFactor(m.periodo!)}");
      if (isPresentValue) {
        pvEquation += (sign > 0 ? ' + ' : ' - ') +
            '${amount.toStringAsFixed(2)}/(1+${effectiveRate.toStringAsFixed(6)})^${m.periodo}';
      }
      if (sign > 0) {
        pvInflows += pvContribution;
        fvInflows += fvContribution;
      } else {
        pvOutflows += pvContribution.abs();
        fvOutflows += fvContribution.abs();
      }
    }

    // Procesar los valores conocidos
    for (final v in d.valores) {
      if (v == valorInc || v.periodo == null || v.valor == null) continue;
      final sign =
          (RateConversionUtils.normalizeTipo(v.flujo) == 'ingreso') ? 1 : -1;
      final amount = (v.valor as double);
      final pvContribution = amount * _pvFactor(v.periodo!);
      final fvContribution = amount * _fvFactor(v.periodo!);
      if (isPresentValue) {
        pvEquation += (sign > 0 ? ' + ' : ' - ') +
            '${amount.toStringAsFixed(2)}/(1+${effectiveRate.toStringAsFixed(6)})^${v.periodo}';
      }
      if (sign > 0) {
        pvInflows += pvContribution;
        fvInflows += fvContribution;
      } else {
        pvOutflows += pvContribution.abs();
        fvOutflows += fvContribution.abs();
      }
    }

    // Calcular PV y FV totales sin la incógnita
    final pv = pvInflows - pvOutflows;
    final fv = fvInflows - fvOutflows;
    steps.add('PV (t=0, sin X): ${pv.toStringAsFixed(6)}');
    steps.add('FV (t=$focal, sin X): ${fv.toStringAsFixed(6)}');

    // Verificar la relación PV-FV
    final pvToFv = pv * pow(1 + effectiveRate, focal);
    steps.add(
        'Verificación: PV * (1+i)^$focal = ${pvToFv.toStringAsFixed(6)} (debe igualar FV)');

    /* ── 4) Calcular Valor en el periodo focal y Despejar incógnita ──────── */
    double result;
    String equation;
    if (hasUnknown) {
      final targetSign =
          (RateConversionUtils.normalizeTipo(valorInc!.flujo) == 'ingreso')
              ? 1
              : -1;
      final period = valorInc.periodo!;
      double factor;
      double targetValue;
      if (isPresentValue) {
        factor = _pvFactor(period);
        targetValue = 0 - pv; // Queremos que PV total sea 0
        // Añadir la incógnita a la ecuación
        pvEquation = 'X' + pvEquation + ' = 0';
        equation = pvEquation;
      } else {
        factor = _fvFactor(period);
        targetValue = 0 - fv; // Queremos que FV total sea 0
        equation = 'X = ${targetValue / (targetSign * factor)}';
      }
      final X = targetValue / (targetSign * factor);
      result = X;
    } else {
      result = isPresentValue ? pv : fv;
      equation =
          '${isPresentValue ? "PV" : "FV"} = ${result.toStringAsFixed(6)}';
    }

    return EquationAnalysis(equation: equation, steps: steps, solution: result);
  }
}
