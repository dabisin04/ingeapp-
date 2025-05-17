// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:collection/collection.dart';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/infrastructure/utils/financial_utils.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

/// Rama «n» (hay ≥ 1 tasa **y** un flujo con `periodo == null`)
class FinancialAnalysis {
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[];

    /* ───── Validación ───────────────────────────────────────── */
    final hasRates = d.tasasDeInteres.isNotEmpty;
    final hasUnknownPeriod = d.movimientos.any((m) => m.periodo == null) ||
        d.valores.any((v) => v.periodo == null);

    if (!hasRates || !hasUnknownPeriod) {
      throw StateError('Condición no soportada para análisis-n');
    }

    /* ───── Normalizar tasas a periódica-vencida ───────────────── */
    final List<TasaDeInteres> tasasOk = d.tasasDeInteres.map((t) {
      final yaOk = t.periodicidad.id == d.unidadDeTiempo.id &&
          t.capitalizacion.id == d.unidadDeTiempo.id &&
          RateConversionUtils.normalizeTipo(t.tipo) == 'vencida';

      if (yaOk) return t;

      final rate = RateConversionUtils.periodicRateForDiagram(
        tasa: t,
        unidadObjetivo: d.unidadDeTiempo,
      );

      return TasaDeInteres(
        id: t.id,
        valor: rate,
        periodicidad: d.unidadDeTiempo,
        capitalizacion: d.unidadDeTiempo,
        tipo: 'Vencida',
        periodoInicio: t.periodoInicio,
        periodoFin: t.periodoFin,
        aplicaA: t.aplicaA,
      );
    }).toList();

    steps.add('→ Calcular n con tasas normalizadas:');
    for (final t in tasasOk) {
      steps.add(
        ' • Tramo ${t.periodoInicio}-${t.periodoFin}: ${(t.valor * 100).toStringAsFixed(4)}% (${d.unidadDeTiempo.nombre}, vencida)',
      );
    }

    /* ───── Funciones auxiliares ───────────────────────────────── */
    double _sumarTasas(int periodo, String tipoFlujo) {
      final tipoNorm = RateConversionUtils.normalizeTipo(tipoFlujo);
      final tasasAplicables = tasasOk.where((t) {
        final inRango = periodo >= t.periodoInicio && periodo <= t.periodoFin;
        final aplica = RateConversionUtils.normalizeTipo(t.aplicaA);
        return inRango && (aplica == 'todos' || aplica == tipoNorm);
      }).toList();

      if (tasasAplicables.isEmpty) {
        throw StateError(
            '❌ No se encontró tasa aplicable para t=$periodo ($tipoFlujo)');
      }

      final suma = tasasAplicables.map((t) => t.valor).reduce((a, b) => a + b);

      steps.add('🔎 Tasas en t=$periodo: '
          '${tasasAplicables.map((t) => (t.valor * 100).toStringAsFixed(4)).join('% + ')} '
          '= ${(suma * 100).toStringAsFixed(6)}%');
      return suma;
    }

    /* ───── 1) Valor presente de los flujos fechados ───────────── */
    double sumatoriaPV = 0.0;

    double _pv(double monto, int periodo, String tipoFlujo) {
      final tasa = _sumarTasas(periodo, tipoFlujo);
      final df = PeriodUtils.discountFactor(tasa, periodo);
      final ingreso = RateConversionUtils.normalizeTipo(tipoFlujo) == 'ingreso';
      final aporte = (ingreso ? 1 : -1) * monto * df;
      steps.add(
        '${ingreso ? "Ingreso" : "Egreso"} \$${monto.toStringAsFixed(2)} '
        'en t=$periodo • DF=${df.toStringAsFixed(6)} → PV=${aporte.toStringAsFixed(2)}',
      );
      return aporte;
    }

    for (final m in d.movimientos) {
      if (m.periodo != null && m.valor is double) {
        sumatoriaPV += _pv(m.valor!, m.periodo!, m.tipo);
      }
    }
    for (final v in d.valores) {
      if (v.periodo != null && v.valor is double) {
        sumatoriaPV += _pv(v.valor!, v.periodo!, v.flujo);
      }
    }
    steps.add('Sumatoria PV conocida = ${sumatoriaPV.toStringAsFixed(2)}');

    /* ───── 2) Flujo faltante ─────────────────────────────────── */
    final Movimiento? movNull =
        d.movimientos.firstWhereOrNull((m) => m.periodo == null);
    final Valor? valNull = movNull == null
        ? d.valores.firstWhereOrNull((v) => v.periodo == null)
        : null;

    if ((movNull?.valor == null && valNull?.valor == null)) {
      throw StateError('No se encontró flujo objetivo para despejar.');
    }

    final flujoValor = movNull?.valor ?? valNull!.valor!;
    final tipoFlujo = movNull?.tipo ?? valNull!.flujo;
    final ingresoObjetivo =
        RateConversionUtils.normalizeTipo(tipoFlujo) == 'ingreso';

    steps.add('🔎 Flujo objetivo (sin periodo): '
        '${ingresoObjetivo ? "Ingreso" : "Egreso"} \$${flujoValor.toStringAsFixed(2)}');

    /* ───── 3) Plantear ecuación para despejar n ───────────────── */
    final tasa = tasasOk.last.valor; // Última tasa como tasa constante
    steps.add(
        'Usando última tasa conocida: ${(tasa * 100).toStringAsFixed(4)}%');

    final ingresoSigno = ingresoObjetivo ? 1.0 : -1.0;

    final eq = '${sumatoriaPV.toStringAsFixed(2)} + '
        '${(flujoValor * ingresoSigno).toStringAsFixed(2)}*(1+${tasa.toStringAsFixed(6)})^-n = 0';
    steps.add('Ecuación planteada: $eq');

    final n = PeriodUtils.solvePeriodsForFutureValueCustom(
      pvConocido: sumatoriaPV,
      flujo: flujoValor,
      tasa: tasa,
      esIngreso: ingresoObjetivo,
    );
    steps.add(
        'n = ln(|flujo / PV|) / ln(1+i) = ${n.toStringAsFixed(4)} periodos');

    return EquationAnalysis(
      equation: eq,
      steps: steps,
      solution: n,
    );
  }
}
