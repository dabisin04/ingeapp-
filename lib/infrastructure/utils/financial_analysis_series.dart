import 'dart:math';

import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

class FinancialAnalysisSeries {
  /// Convierte el diagrama en la ecuación ∑Ingresos − ∑Egresos = 0
  /// y resuelve la incógnita lineal (X / P / A / F / V).
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[];
    final int focal = d.periodoFocal ?? 0;

    /*───────────────────── 1. Normalizar tasas ─────────────────────*/
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

    double totalConst = 0.0; // término independiente
    double totalCoef = 0.0; // coeficiente de la incógnita
    final ecuacionSb = StringBuffer();

    /*──────────────────── Helpers ────────────────────*/
    double _getRate(int periodo, String tipoFlujo) {
      final tipoNorm = RateConversionUtils.normalizeTipo(tipoFlujo);
      final t = tasas.firstWhere(
        (e) =>
            periodo >= e.periodoInicio &&
            periodo <= e.periodoFin &&
            (RateConversionUtils.normalizeTipo(e.aplicaA) == tipoNorm ||
                RateConversionUtils.normalizeTipo(e.aplicaA) == 'todos'),
        orElse: () => throw Exception('No hay tasa para t=$periodo'),
      );
      return t.valor;
    }

    double _trasladoAFoco(int t, double i) =>
        pow(1 / (1 + i), t - focal).toDouble();

    /*──────────────────── Procesar valores puntuales ────────────────────*/
    void _accum(dynamic monto, double factor, String tipoFlujo) {
      final ingreso = RateConversionUtils.normalizeTipo(tipoFlujo) == 'ingreso';
      final valor = monto ?? 'X';

      // Patrón general de incógnita (una sola letra mayúscula)
      final variablePat = RegExp(r'([A-Z])');

      /// ¿Es algo como  "3P/2"  ó  "-0.4X"  ó  "P"?
      if (valor is String && variablePat.hasMatch(valor)) {
        final exp = valor.replaceAll(' ', '').toUpperCase();

        // Fracción   k·S / m
        final frac = RegExp(r'^([+\-]?[0-9\.]*)?([A-Z])\/([0-9\.]+)$');
        if (frac.hasMatch(exp)) {
          final m = frac.firstMatch(exp)!;
          final k = m.group(1)!.isEmpty || m.group(1) == '+'
              ? 1
              : double.parse(m.group(1)!);
          final s = m.group(
              2)!; // nombre de la variable (da igual, es la misma incógnita)
          final den = double.parse(m.group(3)!);
          final contrib = (ingreso ? 1 : -1) * k / den * factor;
          totalCoef += contrib;
          ecuacionSb.write(
              '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(6)}$s ');
          return;
        }

        // Lineal   k·S
        final lin = RegExp(r'^([+\-]?[0-9\.]*)?([A-Z])$');
        if (lin.hasMatch(exp)) {
          final m = lin.firstMatch(exp)!;
          final k = m.group(1)!.isEmpty || m.group(1) == '+'
              ? 1
              : double.parse(m.group(1)!);
          final s = m.group(2)!;
          final contrib = k * factor * (ingreso ? 1 : -1);
          totalCoef += contrib;
          ecuacionSb.write(
              '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(6)}$s ');
          return;
        }

        // Variable “pelada”
        final contrib = (ingreso ? 1 : -1) * factor;
        totalCoef += contrib;
        ecuacionSb.write(
            '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(6)}X ');
        return;
      }

      // Caso numérico
      final num montoNum =
          (valor is num) ? valor : double.parse(valor.toString());
      final contrib = montoNum * factor * (ingreso ? 1 : -1);
      totalConst += contrib;
      ecuacionSb.write(
          '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)} ');
    }

    /*──────────────────── Procesar series ────────────────────*/
    void _procesarSerie({
      required dynamic valor,
      required int desde,
      required int hasta,
      required String tipoFlujo,
      required String tipoSerie, // 'vencida' | 'anticipada'
    }) {
      final n = hasta - desde + 1;
      final i = _getRate(desde, tipoFlujo);

      // — Detectar serie pura (única en el diagrama y centrada en foco) —
      final esPura = d.movimientos.length + d.valores.length == 1 &&
          ((tipoSerie == 'vencida' && desde == focal + 1) ||
              (tipoSerie == 'anticipada' && desde == focal));

      // Factor presente de la serie
      double factorSeriePV = tipoSerie == 'anticipada'
          ? ((pow(1 + i, n) - 1) / (i * pow(1 + i, n - 1)))
          : ((pow(1 + i, n) - 1) / (i * pow(1 + i, n)));

      // Si es pura → se puede usar la versión “corta” sin traslado
      if (esPura) {
        factorSeriePV = tipoSerie == 'anticipada'
            ? ((pow(1 + i, n) - 1) / i) * (1 + i)
            : ((pow(1 + i, n) - 1) / i);
      }

      // Traslado de la serie (si no es pura) hasta el foco
      final int m = tipoSerie == 'anticipada'
          ? (desde - focal) // la 1.ª cuota está en t = desde
          : (desde - 1 - focal); // la 1.ª cuota está en t = desde
      final traslado = esPura ? 1.0 : pow(1 / (1 + i), m).toDouble();

      final factorTotal = factorSeriePV * traslado;

      _accum(valor, factorTotal, tipoFlujo);

      steps
        ..add('Serie ${tipoSerie.toUpperCase()} '
            'n=$n; desde=$desde; hasta=$hasta')
        ..add('  i=${(i * 100).toStringAsFixed(4)} %, '
            'FPV=${factorSeriePV.toStringAsFixed(6)}, '
            'traslado=${traslado.toStringAsFixed(6)}');
    }

    /*──────────────────── 2. Recorrer TODOS los flujos ────────────────────*/
    for (final v in [...d.valores, ...d.movimientos]) {
      if (v is! Valor) continue;
      final tipo = v.flujo;

      if (v.esSerie == true &&
          v.periodo != null &&
          v.hastaPeriodo != null &&
          v.tipoSerie != null) {
        _procesarSerie(
          valor: v.valor,
          desde: v.periodo!,
          hasta: v.hastaPeriodo!,
          tipoFlujo: tipo,
          tipoSerie: v.tipoSerie!.toLowerCase(),
        );
      } else if (v.periodo != null) {
        // Flujo puntual
        final i = _getRate(v.periodo!, tipo);
        final f = _trasladoAFoco(v.periodo!, i);
        _accum(v.valor, f, tipo);
        steps.add('Flujo puntual en t=${v.periodo} '
            'i=${(i * 100).toStringAsFixed(4)} %, '
            'factor=${f.toStringAsFixed(6)}');
      }
    }

    /*──────────────────── 3. Resolver ecuación ────────────────────*/
    final ecuacionFinal = '${ecuacionSb.toString()} = 0';
    final resultado = totalCoef != 0 ? -totalConst / totalCoef : 0.0;

    return EquationAnalysis(
      equation: ecuacionFinal,
      steps: steps,
      solution: resultado,
    );
  }
}
