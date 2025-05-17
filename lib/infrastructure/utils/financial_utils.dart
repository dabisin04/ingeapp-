import 'dart:math';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';

class PeriodUtils {
  /// Calcula factor de descuento simple
  static double discountFactor(double rate, int periods) =>
      pow(1 + rate, -periods).toDouble();

  /// Calcula factor de descuento basado en tasas por tramos
  static double discountFactorPiecewise(List<TasaDeInteres> tasas, int period) {
    final tramo = tasas.firstWhere(
      (t) => period >= t.periodoInicio && period <= t.periodoFin,
      orElse: () => throw StateError(
          'El periodo $period no está cubierto por ninguna tasa.'),
    );
    return pow(1 + tramo.valor, -period).toDouble();
  }

  /// Resuelve n en el caso clásico: FV conocido a partir de PV
  static double solvePeriodsForFutureValue({
    required double presentValue,
    required double futureValue,
    required double rate,
  }) =>
      log(futureValue / presentValue) / log(1 + rate);

  /// Resuelve n en el caso de flujo combinado: PV total + FV faltante
  static double solvePeriodsForFutureValueCustom({
    required double pvConocido,
    required double flujo,
    required double tasa,
    required bool esIngreso,
  }) {
    final signo = esIngreso ? 1.0 : -1.0;
    final numerador = flujo * signo;
    final denominador = -pvConocido;

    if (numerador == 0 || denominador == 0) {
      throw StateError('Numerador o denominador inválido para resolver n.');
    }

    final razon = numerador / denominador;

    if (razon <= 0) {
      throw StateError('Relación negativa o nula entre flujo y PV.');
    }

    return log(razon) / log(1 + tasa);
  }
}
