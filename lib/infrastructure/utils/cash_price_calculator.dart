import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

class FinancialAnalysisCashPrice {
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[];

    // --------------- Validaciones iniciales ---------------
    if (d.tasasDeInteres.isEmpty) {
      throw StateError('Se necesita al menos una tasa de interés.');
    }
    if (d.periodoFocal == null) {
      throw StateError('No se definió el periodo focal.');
    }
    final int focal = d.periodoFocal!;

    // --------------- Normalización de tasas ---------------
    final tasasOk = d.tasasDeInteres.map((t) {
      final yaOk = t.periodicidad.id == d.unidadDeTiempo.id &&
          t.capitalizacion.id == d.unidadDeTiempo.id &&
          t.tipo.toLowerCase() == 'vencida';

      if (yaOk) return t;

      final nuevaRate = RateConversionUtils.periodicRateForDiagram(
        tasa: t,
        unidadObjetivo: d.unidadDeTiempo,
      );

      return TasaDeInteres(
        id: t.id,
        valor: nuevaRate,
        periodicidad: d.unidadDeTiempo,
        capitalizacion: d.unidadDeTiempo,
        tipo: 'Vencida',
        periodoInicio: t.periodoInicio,
        periodoFin: t.periodoFin,
        aplicaA: t.aplicaA,
      );
    }).toList();

    steps.add('🌟 Tasas normalizadas:');
    for (final t in tasasOk) {
      steps.add(
          ' • ${t.periodoInicio}-${t.periodoFin}: ${(t.valor * 100).toStringAsFixed(6)}% para ${t.aplicaA}');
    }

    // --------------- Obtención de tasa aplicable para un periodo específico ---------------
    double _getRateForPeriod(int periodo, String tipoFlujo) {
      final tipoNormalized = RateConversionUtils.normalizeTipo(tipoFlujo);
      final tasasAplicables = tasasOk.where((t) {
        final inRango = periodo >= t.periodoInicio && periodo <= t.periodoFin;
        final aplicaNormalized = RateConversionUtils.normalizeTipo(t.aplicaA);
        return inRango &&
            (aplicaNormalized == tipoNormalized || aplicaNormalized == 'todos');
      }).toList();

      if (tasasAplicables.isEmpty) {
        throw StateError(
            '❌ No se encontró tasa aplicable para t=$periodo ($tipoFlujo)');
      }

      return tasasAplicables.first.valor;
    }

    // --------------- Cálculo del factor de descuento/capitalización ---------------
    double _factor(int p, String tipoFlujo) {
      if (p == focal) return 1.0;

      double factor = 1.0;
      final sentido = p > focal ? 1 : -1;
      int actual = focal;
      final target = p;

      while (actual != target) {
        final tasaActual = _getRateForPeriod(actual, tipoFlujo);
        factor *= (sentido > 0) ? 1 / (1 + tasaActual) : (1 + tasaActual);
        actual += sentido;
      }

      return factor;
    }

    // --------------- Procesar valores y flujos ---------------
    double coefX = 0.0;
    double constante = 0.0;
    final ecuacion = <String>[];

    // Procesamos cada valor de los movimientos y valores
    for (final m in d.movimientos) {
      if (m.valor != null) {
        final fac = _factor(m.periodo!, m.tipo);
        final contrib = (m.tipo == 'ingreso' ? 1 : -1) * m.valor * fac;
        constante += contrib;
        ecuacion.add(
            '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)}');
      }
    }

    // Procesamos los valores (como el down payment o final payment)
    for (final v in d.valores) {
      if (v.valor != null) {
        final fac = _factor(v.periodo!, v.flujo);
        final contrib = (v.flujo == 'ingreso' ? 1 : -1) * v.valor * fac;
        constante += contrib;
        ecuacion.add(
            '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)}');
      }
    }

    // --------------- Resolver la ecuación ---------------
    final ecuacionFinal = ecuacion.join(' ');
    if (coefX == 0) {
      throw StateError('No hay incógnita X en el problema.');
    }
    final X = -constante / coefX;

    return EquationAnalysis(
      equation: '$ecuacionFinal = 0',
      steps: steps,
      solution: X,
    );
  }
}
