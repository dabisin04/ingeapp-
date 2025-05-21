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

    for (var m in movs) {
      final p = m.periodo ?? focalPeriod;
      final c = m.valor ?? 0.0;
      final n = focalPeriod - p;
      final moved = pow(1 + rate, n) * c;
      net += (m.tipo == 'ingreso' ? 1 : -1) * moved;
    }

    for (var v in vals) {
      final p = v.periodo ?? focalPeriod;
      final c = v.valor ?? 0.0;
      final n = focalPeriod - p;
      final moved = pow(1 + rate, n) * c;
      net += (v.flujo == 'ingreso' ? 1 : -1) * moved;
    }

    return net;
  }

  static double netPresentValue(
    List<Movimiento> movs,
    List<Valor> vals,
    double rate,
  ) {
    double npv = 0.0;

    for (var m in movs) {
      final p = m.periodo ?? 0;
      final c = m.valor ?? 0.0;
      final moved = c / pow(1 + rate, p);
      npv += (m.tipo == 'ingreso' ? 1 : -1) * moved;
    }

    for (var v in vals) {
      final p = v.periodo ?? 0;
      final c = v.valor ?? 0.0;
      final moved = c / pow(1 + rate, p);
      npv += (v.flujo == 'ingreso' ? 1 : -1) * moved;
    }

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

    for (int i = 0; i < maxIter; i++) {
      final f = netValueAtFocal(movs, vals, rate, focalPeriod);
      final df = _derivative(movs, vals, rate, focalPeriod);

      if (df == 0) {
        break;
      }

      final next = rate - f / df;

      if ((next - rate).abs() < tol) {
        rate = next;
        break;
      }
      rate = next;
    }

    return rate;
  }

  static double _derivative(
    List<Movimiento> movs,
    List<Valor> vals,
    double rate,
    int focalPeriod,
  ) {
    double d = 0.0;

    for (var m in movs) {
      final p = m.periodo ?? focalPeriod;
      final c = m.valor ?? 0.0;
      final n = focalPeriod - p;
      if (n == 0) continue;
      final term = c * n * pow(1 + rate, n - 1);
      d += (m.tipo == 'ingreso' ? 1 : -1) * term;
    }

    for (var v in vals) {
      final p = v.periodo ?? focalPeriod;
      final c = v.valor ?? 0.0;
      final n = focalPeriod - p;
      if (n == 0) continue;
      final term = c * n * pow(1 + rate, n - 1);
      d += (v.flujo == 'ingreso' ? 1 : -1) * term;
    }

    return d;
  }
}
