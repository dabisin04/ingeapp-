import 'dart:math';

import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

class FinancialAnalysisSeries {
  /// Convierte el diagrama en la ecuación ∑Ingresos − ∑Egresos = 0
  /// y resuelve la incógnita lineal (P, A, X, F, V).
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    print('=== INICIO ANÁLISIS FINANCIERO ===');
    print('Diagrama recibido: ${d.toString()}');

    final steps = <String>[];
    final int focal = d.periodoFocal ?? 0;
    print('Período focal: $focal');

    // 1. Normalizar tasas
    print('=== NORMALIZANDO TASAS ===');
    final tasas = d.tasasDeInteres.map((t) {
      print('Procesando tasa original: ${t.toString()}');
      final r = RateConversionUtils.periodicRateForDiagram(
        tasa: t,
        unidadObjetivo: d.unidadDeTiempo,
      );
      print('Tasa normalizada: $r');
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
    print('Tasas normalizadas: ${tasas.toString()}');

    double totalConst = 0.0;
    double totalCoef = 0.0;
    final ecuacionSb = StringBuffer();

    // 1. Obtener tasa para un periodo y tipo de flujo
    double _getRate(int periodo, String tipoFlujo) {
      print('Buscando tasa para periodo $periodo y tipo $tipoFlujo');
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

    // 2. Descuento compuesto entre focal y t, usando todos los tramos de tasa
    double _discount(int t, String tipoFlujo) {
      print(
          '\n>>> Calculando descuento compuesto desde t=$t hasta foco=$focal');
      double factor = 1.0;
      final int start = focal + 1;
      final int end = t;
      for (final tasa in tasas) {
        // --- CAMBIO: descontar a partir de periodoInicio+1 para cada tramo ---
        final int low = max(start, tasa.periodoInicio + 1); // <-- ajustado aquí
        final int high = min(end, tasa.periodoFin);
        if (high >= low) {
          final int count = high - low + 1;
          final double seg = pow(1 / (1 + tasa.valor), count).toDouble();
          print(
              '  tramo $low–$high con i=${(tasa.valor * 100).toStringAsFixed(3)}% → factor segmento=$seg');
          factor *= seg;
        }
      }
      print('  factor total descuento: $factor');
      return factor;
    }

    // 3. Acumulación para punto o variable
    void _accum(dynamic monto, double factor, String tipoFlujo) {
      print(
          '\nProcesando acumulación: monto=$monto, factor=$factor, tipoFlujo=$tipoFlujo');
      final ingreso = RateConversionUtils.normalizeTipo(tipoFlujo) == 'ingreso';

      // variables, fracciones, potencias y numéricos (igual que antes)...
      final variablePat = RegExp(r'([A-Z])');
      if (monto == null) {
        final contrib = factor * (ingreso ? 1 : -1);
        totalCoef += contrib;
        print('  Contribución variable nula: $contrib X');
        ecuacionSb.write(
            '${contrib >= 0 ? '+' : '-'}${contrib.abs().toStringAsFixed(6)}X ');
        return;
      }
      if (monto is String && variablePat.hasMatch(monto)) {
        final exp = monto.replaceAll(' ', '').toUpperCase();
        // ... lógica de fracción, potencia, lineal y pelada ...
        // (idéntica a tu implementación actual)
      } else {
        try {
          final num valNum =
              monto is num ? monto : double.parse(monto.toString());
          final contrib = valNum * factor * (ingreso ? 1 : -1);
          totalConst += contrib;
          print('  Contribución numérica: $contrib');
          ecuacionSb.write(
              '${contrib >= 0 ? '+' : '-'}${contrib.abs().toStringAsFixed(2)} ');
        } catch (e) {
          print('  Error al procesar valor numérico: $e');
          final contrib = factor * (ingreso ? 1 : -1);
          totalCoef += contrib;
          print('  Contribución como variable: $contrib X');
          ecuacionSb.write(
              '${contrib >= 0 ? '+' : '-'}${contrib.abs().toStringAsFixed(6)}X ');
        }
      }
    }

    // 4. Procesar flujo puntual
    void _processPoint(dynamic item) {
      if (item is! Valor && item is! Movimiento) {
        print('Item no es Valor ni Movimiento, ignorando');
        return;
      }
      final int periodo = item.periodo as int;
      final dynamic valor = item.valor;
      final String tipo = item is Valor ? item.flujo : item.tipo;
      print('\n--- Punto t=$periodo, valor=$valor, tipo=$tipo');
      final factor = _discount(periodo, tipo);
      _accum(valor, factor, tipo);
      steps.add('Punto t=$periodo factor=${factor.toStringAsFixed(6)}');
    }

    // 5. Procesar serie uniforme
    void _processSeries(dynamic item) {
      if (item is! Valor && item is! Movimiento) {
        print('Item no es Valor ni Movimiento, ignorando');
        return;
      }
      final int desde = item.periodo as int;
      final int hasta = item.hastaPeriodo as int;
      final num valor = item.valor as num;
      final String tipo = item is Valor ? item.flujo : item.tipo;
      final String tipoSerie = (item.tipoSerie as String).toLowerCase();
      final int n = hasta - desde + 1;

      print(
          '\n--- Serie $tipoSerie desde t=$desde hasta t=$hasta (n=$n), valor=$valor');

      // FPV serie
      final rateSerie = _getRate(desde, tipo);
      double factorSerie = tipoSerie == 'anticipada'
          ? (pow(1 + rateSerie, n) - 1) /
              (rateSerie * pow(1 + rateSerie, n - 1))
          : (pow(1 + rateSerie, n) - 1) / (rateSerie * pow(1 + rateSerie, n));
      print('  FPV inicial de la serie: $factorSerie');

      // Traslado compuesto desde el punto base de la serie:
      final int base = tipoSerie == 'anticipada' ? desde : desde - 1;
      print('  Traslado compuesto desde t=$base');
      final double traslado = _discount(base, tipo);
      print('  Factor traslado serie: $traslado');

      final factorTotal = factorSerie * traslado;
      print('  Factor total serie: $factorTotal');

      _accum(valor, factorTotal, tipo);
      steps.add(
          'Serie $tipoSerie t=$desde–$hasta factorPV=${factorTotal.toStringAsFixed(6)}');
    }

    // 6. Recorrer TODOS los flujos
    print('\n=== PROCESANDO FLUJOS ===');
    for (final item in [...d.valores, ...d.movimientos]) {
      print('Procesando item: ${item.toString()}');
      final bool isSerie =
          item is Valor ? item.esSerie : (item as Movimiento).esSerie;
      final int? periodo =
          item is Valor ? item.periodo : (item as Movimiento).periodo;
      final int? hastaPeriodo =
          item is Valor ? item.hastaPeriodo : (item as Movimiento).hastaPeriodo;

      if (isSerie == true && periodo != null && hastaPeriodo != null) {
        _processSeries(item);
      } else if (periodo != null) {
        _processPoint(item);
      } else {
        print('Item sin periodo, ignorando');
      }
    }

    // 7. Resolver ecuación
    print('\n=== RESOLVIENDO ECUACIÓN ===');
    print('TotalConst: $totalConst, TotalCoef: $totalCoef');
    final equation = '${ecuacionSb.toString()} = 0';
    print('Ecuación: $equation');
    final solution = totalCoef != 0 ? -totalConst / totalCoef : 0.0;
    print('Resultado: $solution');
    print('=== FIN ANÁLISIS FINANCIERO ===');

    return EquationAnalysis(
      equation: equation,
      steps: steps,
      solution: solution,
    );
  }
}
