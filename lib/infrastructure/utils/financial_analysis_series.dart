import 'dart:math';

import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

class FinancialAnalysisSeries {
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[];
    final int focal = d.periodoFocal ?? 0;

    // ─── Paso 1: Normalizar tasas ───
    final tasas = d.tasasDeInteres.map((t) {
      final r = RateConversionUtils.periodicRateForDiagram(
        tasa: t,
        unidadObjetivo: d.unidadDeTiempo,
      );
      return TasaDeInteres(
        id: t.id,
        valor: r,
        periodicidad: d.unidadDeTiempo,
        capitalizacion: d.unidadDeTiempo,
        tipo: 'Vencida',
        periodoInicio: t.periodoInicio,
        periodoFin: t.periodoFin,
        aplicaA: t.aplicaA,
      );
    }).toList();

    double total = 0.0;
    double coefX = 0.0;
    final ecuacion = <String>[];

    double _getRate(int periodo, String tipo) {
      final tipoNorm = RateConversionUtils.normalizeTipo(tipo);
      final t = tasas.firstWhere(
        (e) =>
            periodo >= e.periodoInicio &&
            periodo <= e.periodoFin &&
            (RateConversionUtils.normalizeTipo(e.aplicaA) == tipoNorm ||
                RateConversionUtils.normalizeTipo(e.aplicaA) == 'todos'),
        orElse: () => throw Exception("No hay tasa para t=$periodo"),
      );
      return t.valor;
    }

    double _factorToFocal(int t, double i) {
      return pow(1 / (1 + i), t - focal).toDouble();
    }

    void _procesarValor(dynamic valor, double factor, String tipo) {
      final ingreso = RateConversionUtils.normalizeTipo(tipo) == 'ingreso';
      if (valor == null) return;

      if (valor is String && valor.toUpperCase().contains('X')) {
        final exp = valor.toUpperCase().replaceAll(' ', '');

        // Potencia de X (solo X^2 soportado de momento)
        final potenciaX = RegExp(r'^([0-9\.]*)X\^([0-9]+)$');
        if (potenciaX.hasMatch(exp)) {
          final match = potenciaX.firstMatch(exp)!;
          final coef = _extraerCoeficiente(match.group(1) ?? '');
          final potencia = int.parse(match.group(2)!);
          final contrib = (ingreso ? 1 : -1) * coef * factor;
          coefX += contrib;
          ecuacion.add(
              '${ingreso ? '+' : '-'} ${contrib.toStringAsFixed(6)}X^$potencia');
          return;
        }

        // Fracción (e.g. 3X/2 o X/4)
        final fraccionX = RegExp(r'^([0-9\.]*)?X/([0-9\.]+)$');
        if (fraccionX.hasMatch(exp)) {
          final match = fraccionX.firstMatch(exp)!;
          final numerador = _extraerCoeficiente(match.group(1) ?? '');
          final denominador = double.parse(match.group(2)!);
          final contrib = (ingreso ? 1 : -1) * numerador / denominador * factor;
          coefX += contrib;
          ecuacion.add('${ingreso ? '+' : '-'} ${contrib.toStringAsFixed(6)}X');
          return;
        }

        // Término lineal (e.g. 3X, -X)
        final termX = RegExp(r'^([-\+]?[0-9\.]*)?X$');
        if (termX.hasMatch(exp)) {
          final match = termX.firstMatch(exp)!;
          final coef = _extraerCoeficiente(match.group(1) ?? '');
          final contrib = coef * factor * (ingreso ? 1 : -1);
          coefX += contrib;
          ecuacion.add(
              '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(6)}X');
          return;
        }

        throw Exception('❌ Formato no reconocido para X: "$valor"');
      }

      // Caso numérico normal
      final numero = (valor is num)
          ? valor.toDouble()
          : double.tryParse(valor.toString()) ?? 0.0;
      final contrib = numero * factor * (ingreso ? 1 : -1);
      total += contrib;
      ecuacion.add(
          "${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)}");
    }

    void _procesarSerie({
      required dynamic valor,
      required int desde,
      required int hasta,
      required String tipo,
      required String tipoSerie,
    }) {
      final n = hasta - desde + 1;
      final i = _getRate(desde, tipo);
      final factorSerie = (pow(1 + i, n) - 1) /
          (i * (tipoSerie == 'anticipada' ? pow(1 + i, n - 1) : pow(1 + i, n)));
      final traslado = pow(1 / (1 + i),
          tipoSerie == 'anticipada' ? desde - focal : desde - 1 - focal);
      final factorTotal = factorSerie * traslado;
      _procesarValor(valor, factorTotal, tipo);

      steps.add(
          "Serie ${tipoSerie.toUpperCase()} de $n pagos desde t=$desde hasta t=$hasta");
      steps.add(
          "→ i = ${(i * 100).toStringAsFixed(4)}%, factor = ${factorSerie.toStringAsFixed(6)}, traslado = ${(traslado).toStringAsFixed(6)}");
    }

    // ─── Paso 2: Procesar flujos ───
    // Procesar valores (no pueden ser series)
    for (final v in d.valores) {
      if (v.periodo != null) {
        final i = _getRate(v.periodo!, v.tipo);
        final f = _factorToFocal(v.periodo!, i);
        _procesarValor(v.valor, f, v.flujo);
        steps.add(
            "Flujo puntual en t=${v.periodo}, i=${(i * 100).toStringAsFixed(4)}%, factor=${f.toStringAsFixed(6)}");
      }
    }

    // Procesar movimientos (pueden ser series)
    for (final m in d.movimientos) {
      if (m.esSerie) {
        if (m.periodo != null &&
            m.hastaPeriodo != null &&
            m.tipoSerie != null) {
          _procesarSerie(
            valor: m.valor,
            desde: m.periodo!,
            hasta: m.hastaPeriodo!,
            tipo: m.tipo,
            tipoSerie: m.tipoSerie!.toLowerCase(),
          );
        }
      } else {
        if (m.periodo != null) {
          final i = _getRate(m.periodo!, m.tipo);
          final f = _factorToFocal(m.periodo!, i);
          _procesarValor(m.valor, f, m.tipo);
          steps.add(
              "Flujo puntual en t=${m.periodo}, i=${(i * 100).toStringAsFixed(4)}%, factor=${f.toStringAsFixed(6)}");
        }
      }
    }

    // ─── Paso 3: Resolver ───
    final String ecuacionFinal = ecuacion.join(' ');
    final double? resultadoX = coefX != 0 ? -total / coefX : null;

    return EquationAnalysis(
      equation: '$ecuacionFinal = 0',
      steps: steps,
      solution: resultadoX ?? 0.0,
    );
  }

  static double _extraerCoeficiente(String valor) {
    final expr =
        valor.toUpperCase().replaceAll('X', '').replaceAll('*', '').trim();
    if (expr.isEmpty) return 1.0;
    return double.tryParse(expr) ?? 1.0;
  }
}
