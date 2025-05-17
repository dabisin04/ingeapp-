import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

class FinancialAnalysisUnknown {
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

    double coefX = 0.0;
    double constante = 0.0;
    final ecuacion = <String>[];

    // --------------- Obtención de tasa aplicable para un period específico ---------------
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

    // --------------- Procesar valores sin period ---------------
    void _procesarValorSinPeriodo(dynamic valor, String tipoFlujo) {
      final ingreso = RateConversionUtils.normalizeTipo(tipoFlujo) == 'ingreso';
      if (valor == null) return;

      if (valor is double) {
        final contrib = ingreso ? valor : -valor;
        constante += contrib;
        ecuacion.add(
            '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)}');
      } else if (valor is String) {
        final texto = valor.trim().toUpperCase();
        if (texto == 'X') {
          coefX += ingreso ? 1 : -1;
          ecuacion.add('${ingreso ? '+' : '-'} 1.000000X');
        } else if (RegExp(r'^\d*\.?\d+\*?X$').hasMatch(texto)) {
          final factorStr = texto.replaceAll('*', '').replaceAll('X', '');
          final factor = double.parse(factorStr);
          coefX += ingreso ? factor : -factor;
          ecuacion.add('${ingreso ? '+' : '-'} ${factor.toStringAsFixed(6)}X');
        } else if (texto.contains('/')) {
          final partes = texto.split('/');
          final numStr = partes[0].trim();
          final den = double.parse(partes[1].trim());

          if (numStr.contains('X')) {
            final coefStr = numStr.replaceAll('X', '').trim();
            final coef = coefStr.isEmpty ? 1.0 : double.parse(coefStr);
            final factor = coef / den;
            coefX += ingreso ? factor : -factor;
            ecuacion
                .add('${ingreso ? '+' : '-'} ${factor.toStringAsFixed(6)}X');
          } else {
            final num = double.parse(numStr);
            final factor = num / den;
            constante += ingreso ? factor : -factor;
            ecuacion.add('${ingreso ? '+' : '-'} ${factor.toStringAsFixed(2)}');
          }
        }
      }
    }

    // --------------- Procesar valores con factor ---------------
    void _procesarValorConFactor(dynamic valor, double fac, String tipoFlujo) {
      final ingreso = RateConversionUtils.normalizeTipo(tipoFlujo) == 'ingreso';
      if (valor == null) return;

      if (valor is double) {
        final contrib = (ingreso ? 1 : -1) * valor * fac;
        constante += contrib;
        ecuacion.add(
            '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)}');
      } else if (valor is String) {
        final texto = valor.trim().toUpperCase();
        if (texto == 'X') {
          coefX += (ingreso ? 1 : -1) * fac;
          ecuacion.add('${ingreso ? '+' : '-'} ${fac.toStringAsFixed(6)}X');
        } else if (RegExp(r'^\d*\.?\d+\*?X$').hasMatch(texto)) {
          final coef =
              double.parse(texto.replaceAll('*', '').replaceAll('X', ''));
          coefX += (ingreso ? coef : -coef) * fac;
          ecuacion.add(
              '${ingreso ? '+' : '-'} ${(coef * fac).toStringAsFixed(6)}X');
        } else if (texto.contains('/')) {
          final partes = texto.split('/');
          final numStr = partes[0].trim();
          final den = double.parse(partes[1].trim());

          if (numStr.contains('X')) {
            final coefStr = numStr.replaceAll('X', '').trim();
            final coef = coefStr.isEmpty ? 1.0 : double.parse(coefStr);
            final factorX = coef / den;
            coefX += (ingreso ? factorX : -factorX) * fac;
            ecuacion.add(
                '${ingreso ? '+' : '-'} ${(factorX * fac).toStringAsFixed(6)}X');
          } else {
            final num = double.parse(numStr);
            final factorNum = num / den;
            constante += (ingreso ? factorNum : -factorNum) * fac;
            ecuacion.add(
                '${ingreso ? '+' : '-'} ${(factorNum * fac).toStringAsFixed(2)}');
          }
        } else {
          final num = double.tryParse(texto);
          if (num != null) {
            final contrib = (ingreso ? 1 : -1) * num * fac;
            constante += contrib;
            ecuacion.add(
                '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)}');
          } else {
            throw Exception('Unexpected valor format: $valor');
          }
        }
      } else {
        throw Exception('Unexpected valor type: ${valor.runtimeType}');
      }
    }

    // --------------- Dispatcher de cada flujo ---------------
    void _procesar(dynamic valor, int? periodo, String tipoFlujo) {
      if (periodo == null) {
        _procesarValorSinPeriodo(valor, tipoFlujo);
      } else {
        final fac = _factor(periodo, tipoFlujo);
        _procesarValorConFactor(valor, fac, tipoFlujo);
      }
    }

    // --------------- Procesar movimientos y valores ---------------
    for (final m in d.movimientos) {
      if (m.valor != null) {
        _procesar(m.valor, m.periodo, m.tipo);
      }
    }
    for (final v in d.valores) {
      if (v.valor != null) {
        _procesar(v.valor, v.periodo, v.flujo);
      }
    }

    // --------------- Construir y resolver la ecuación ---------------
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
