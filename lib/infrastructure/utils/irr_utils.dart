import 'dart:math';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/valor.dart';

class IRRUtils {
  static double netValueAtFocal(
    List<Movimiento> movs,
    List<Valor> vals,
    double rate,
    int focalPeriod,
  ) {
    double net = 0.0;
    print(
        '--- Calcular netValueAtFocal con tasa ${rate.toStringAsFixed(6)} en t=$focalPeriod ---');

    for (var m in movs) {
      final p = m.periodo ?? focalPeriod;
      final c = m.valor ?? 0.0;
      final n = focalPeriod - p;
      final moved = pow(1 + rate, n) * c;
      final sign = m.tipo == 'ingreso' ? '+' : '-';
      net += (m.tipo == 'ingreso' ? 1 : -1) * moved;
      print(
          'Movimiento $sign$c * (1 + i)^$n = ${moved.toStringAsFixed(4)}  → net=$net');
    }

    for (var v in vals) {
      final p = v.periodo ?? focalPeriod;
      final c = v.valor ?? 0.0;
      final n = focalPeriod - p;
      final moved = pow(1 + rate, n) * c;
      final sign = v.flujo == 'ingreso' ? '+' : '-';
      net += (v.flujo == 'ingreso' ? 1 : -1) * moved;
      print(
          'Valor     $sign$c * (1 + i)^$n = ${moved.toStringAsFixed(4)}  → net=$net');
    }

    print('--- Resultado neto total: ${net.toStringAsFixed(4)} ---\n');
    return net;
  }

  static double netPresentValue(
    List<Movimiento> movs,
    List<Valor> vals,
    double rate,
  ) {
    double npv = 0.0;
    print('--- Calcular NPV en t=0 con tasa ${rate.toStringAsFixed(6)} ---');

    for (var m in movs) {
      final p = m.periodo ?? 0;
      final c = m.valor ?? 0.0;
      final moved = c / pow(1 + rate, p);
      final sign = m.tipo == 'ingreso' ? '+' : '-';
      npv += (m.tipo == 'ingreso' ? 1 : -1) * moved;
      print(
          'Movimiento $sign$c / (1 + i)^$p = ${moved.toStringAsFixed(4)} → npv=$npv');
    }

    for (var v in vals) {
      final p = v.periodo ?? 0;
      final c = v.valor ?? 0.0;
      final moved = c / pow(1 + rate, p);
      final sign = v.flujo == 'ingreso' ? '+' : '-';
      npv += (v.flujo == 'ingreso' ? 1 : -1) * moved;
      print(
          'Valor     $sign$c / (1 + i)^$p = ${moved.toStringAsFixed(4)} → npv=$npv');
    }

    print('--- Resultado NPV total: ${npv.toStringAsFixed(4)} ---\n');
    return npv;
  }

  static double solveIRR({
    required List<Movimiento> movs,
    required List<Valor> vals,
    required int focalPeriod,
    double guess = 0.1,
    double tol = 1e-8,
    int maxIter = 100,
  }) {
    double rate = guess;
    print('\n=== Iniciar cálculo de IRR con Newton-Raphson ===');
    print('Guess inicial: ${(rate * 100).toStringAsFixed(4)}%\n');

    for (int i = 0; i < maxIter; i++) {
      final f = netValueAtFocal(movs, vals, rate, focalPeriod);
      final df = _derivative(movs, vals, rate, focalPeriod);

      if (df == 0) {
        print('❌ Derivada nula. Detenido en iteración $i');
        break;
      }

      final next = rate - f / df;
      print(
          'Iter $i → f=${f.toStringAsFixed(6)}, df=${df.toStringAsFixed(6)} → next=${(next * 100).toStringAsFixed(6)}%');

      if ((next - rate).abs() < tol) {
        print('✅ Convergencia alcanzada en iteración $i\n');
        rate = next;
        break;
      }
      rate = next;
    }

    print('=== Resultado final IRR: ${(rate * 100).toStringAsFixed(6)}% ===\n');
    return rate;
  }

  static double _derivative(
    List<Movimiento> movs,
    List<Valor> vals,
    double rate,
    int focalPeriod,
  ) {
    double d = 0.0;
    print('→ Derivada en tasa ${rate.toStringAsFixed(6)}');

    for (var m in movs) {
      final p = m.periodo ?? focalPeriod;
      final c = m.valor ?? 0.0;
      final n = focalPeriod - p;
      if (n == 0) continue;
      final term = c * n * pow(1 + rate, n - 1);
      d += (m.tipo == 'ingreso' ? 1 : -1) * term;
      print(
          'Movimiento ${m.tipo} → $c*$n*(1+i)^${n - 1} = ${term.toStringAsFixed(6)}');
    }

    for (var v in vals) {
      final p = v.periodo ?? focalPeriod;
      final c = v.valor ?? 0.0;
      final n = focalPeriod - p;
      if (n == 0) continue;
      final term = c * n * pow(1 + rate, n - 1);
      d += (v.flujo == 'ingreso' ? 1 : -1) * term;
      print(
          'Valor ${v.flujo} → $c*$n*(1+i)^${n - 1} = ${term.toStringAsFixed(6)}');
    }

    print('Resultado derivada: ${d.toStringAsFixed(6)}\n');
    return d;
  }
}
