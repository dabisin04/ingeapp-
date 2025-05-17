import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

class FinancialAnalysisSingleUnknown {
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[];

    // Validations
    if (d.tasasDeInteres.isEmpty) {
      throw StateError('Se necesita al menos una tasa de interés.');
    }
    if (d.periodoFocal == null) {
      throw StateError('No se definió el periodo focal.');
    }
    final int focal = d.periodoFocal!;

    // Normalize rates (ensure they are effective periodic rates)
    final tasasOk = d.tasasDeInteres.map((t) {
      final yaOk = t.periodicidad.id == d.unidadDeTiempo.id &&
          t.capitalizacion.id == d.unidadDeTiempo.id &&
          t.tipo.toLowerCase() == 'vencida';
      if (yaOk) return t;

      final nuevaRate = RateConversionUtils.periodicRateForDiagram(
        tasa: t,
        unidadObjetivo: d.unidadDeTiempo,
      );

      return t.copyWith(
        valor: nuevaRate,
        periodicidad: d.unidadDeTiempo,
        capitalizacion: d.unidadDeTiempo,
        tipo: 'Vencida',
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

    // Get the applicable rate for a specific period
    double _getRate(int periodo, String tipoFlujo) {
      final tipoNormalized = RateConversionUtils.normalizeTipo(tipoFlujo);
      final tasasAplicables = tasasOk.where((t) {
        final inRango = periodo >= t.periodoInicio && periodo <= t.periodoFin;
        final aplicaNormalized = RateConversionUtils.normalizeTipo(t.aplicaA);
        return inRango &&
            (aplicaNormalized == tipoNormalized || aplicaNormalized == 'todos');
      }).toList();

      if (tasasAplicables.isEmpty) {
        throw StateError(
            'No se encontró tasa aplicable para t=$periodo ($tipoFlujo)');
      }

      return tasasAplicables.first.valor;
    }

    // Calculate the discount or compounding factor from period p to focal
    double _factor(int p, String tipoFlujo) {
      if (p == focal) return 1.0;

      double factor = 1.0;
      final sentido = p > focal
          ? 1
          : -1; // If p > focal, discount back; if p < focal, compound forward
      int actual = focal;
      final target = p;

      while (actual != target) {
        final tasaActual = _getRate(actual, tipoFlujo);
        factor *= (sentido > 0)
            ? 1 / (1 + tasaActual) // Discounting back to focal
            : (1 + tasaActual); // Compounding forward to focal
        actual += sentido;
      }

      return factor;
    }

    // Parse expressions containing X (e.g., "X", "0.2X", "X/5")
    double? _parseXFactor(String valor) {
      final clean = valor.toUpperCase().replaceAll(' ', '');
      if (clean == 'X') return 1.0;
      if (RegExp(r'^[\d.]+X$').hasMatch(clean)) {
        return double.parse(clean.replaceAll('X', ''));
      }
      if (RegExp(r'^[\d.]*X/[\d.]+$').hasMatch(clean)) {
        final parts = clean.split('/');
        final num = parts[0].replaceAll('X', '');
        final numerator = num.isEmpty ? 1.0 : double.parse(num);
        final denominator = double.parse(parts[1]);
        return numerator / denominator;
      }
      return null;
    }

    // Process a cash flow (either a constant or an expression with X)
    void _procesar(dynamic valor, int? periodo, String tipoFlujo) {
      final ingreso = RateConversionUtils.normalizeTipo(tipoFlujo) == 'ingreso';
      final signo = ingreso ? 1.0 : -1.0;
      double factor = 1.0;
      if (periodo != null) factor = _factor(periodo, tipoFlujo);

      if (valor is double) {
        final contrib = signo * valor * factor;
        constante += contrib;
        ecuacion.add(
            '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)}');
      } else if (valor is String) {
        final xFactor = _parseXFactor(valor);
        if (xFactor != null) {
          final contrib = signo * xFactor * factor;
          coefX += contrib;
          ecuacion.add(
              '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(6)}X');
        } else {
          final num = double.tryParse(valor);
          if (num != null) {
            final contrib = signo * num * factor;
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

    // Verify exactly one X in the diagram
    final todosValores = <dynamic>[
      ...d.movimientos.map((m) => m.valor),
      ...d.valores.map((v) => v.valor),
    ];

    final incognitaX = todosValores
        .where((valor) => valor is String && valor.toUpperCase().contains('X'))
        .toList();

    if (incognitaX.length != 1) {
      throw StateError(
          'Se esperaba exactamente una incógnita "X". Encontradas: ${incognitaX.length}.');
    }

    // Process all cash flows
    for (final m in d.movimientos) {
      if (m.valor != null) _procesar(m.valor, m.periodo, m.tipo);
    }

    for (final v in d.valores) {
      if (v.valor != null) _procesar(v.valor, v.periodo, v.flujo);
    }

    // Construct and solve the equation
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
