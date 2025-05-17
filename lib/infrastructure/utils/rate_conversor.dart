import 'dart:math';

import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

/// Conversión de tasas entre diferentes periodicidades
/// y entre nominal / efectiva / anticipada – vencida.
class RateConversionUtils {
  /// Devuelve la tasa **periódica vencida** (decimal) expresada
  /// en la [unidadObjetivo] del diagrama.
  static double periodicRateForDiagram({
    required TasaDeInteres tasa,
    required UnidadDeTiempo unidadObjetivo,
  }) {
    // Early Exit
    final bool yaEsPeriodica =
        tasa.periodicidad.id == tasa.capitalizacion.id; // i_p
    final bool coincideUnidad =
        tasa.periodicidad.id == unidadObjetivo.id; // misma unidad
    final bool esVencida = tasa.tipo.toLowerCase() == 'vencida';

    if (yaEsPeriodica && coincideUnidad && esVencida) {
      return tasa.valor; // ¡no hay nada que convertir!
    }

    // 1) Nominal → periódica (si periodicidad ≠ capitalización)
    double iPerOrig;
    final bool esNominal = !yaEsPeriodica;
    final int nOrig = tasa.capitalizacion.valor; // m original/año
    iPerOrig = esNominal ? tasa.valor / nOrig : tasa.valor;

    // 2) Anticipada → vencida
    if (!esVencida) {
      iPerOrig = iPerOrig / (1 - iPerOrig);
    }

    // 3) Periódica → efectiva anual
    final iEffAnnual = pow(1 + iPerOrig, nOrig).toDouble() - 1;

    // 4) Efectiva anual → nominal anual destino
    final int nTar = unidadObjetivo.valor;
    final iNomTar = nTar * (pow(1 + iEffAnnual, 1 / nTar).toDouble() - 1);

    // 5) Nominal destino → periódica destino (vencida)
    final iPerTar = iNomTar / nTar;
    return iPerTar;
  }

  /// Conversión detallada (para depuración).
  ///
  /// Devuelve la tasa periódica resultante **y** una lista de pasos.
  static ({double rate, List<String> steps}) detailedConversion({
    required TasaDeInteres tasa,
    required UnidadDeTiempo unidadObjetivo,
  }) {
    final steps = <String>[];

    //Early exit con explicación
    final bool yaEsPeriodica = tasa.periodicidad.id == tasa.capitalizacion.id;
    final bool coincideUnidad = tasa.periodicidad.id == unidadObjetivo.id;
    final bool esVencida = tasa.tipo.toLowerCase() == 'vencida';

    if (yaEsPeriodica && coincideUnidad && esVencida) {
      steps.add('La tasa ya es periódica-vencida en la unidad objetivo '
          '(${unidadObjetivo.nombre}). No se realiza conversión.');
      return (rate: tasa.valor, steps: steps);
    }

    steps.add('Origen  : ${tasa.periodicidad.nombre} | '
        '${tasa.capitalizacion.nombre} | ${tasa.tipo}');
    steps.add('Destino : ${unidadObjetivo.nombre} (periódica vencida)');

    // 1) Nominal → periódica (si aplica)
    final bool esNominal = tasa.periodicidad.id != tasa.capitalizacion.id;
    final int nOrig = tasa.capitalizacion.valor;
    double iPerOrig;
    if (esNominal) {
      iPerOrig = tasa.valor / nOrig;
      steps.add('Nominal→Periódica: '
          '${tasa.valor.toStringAsFixed(6)}/$nOrig = '
          '${iPerOrig.toStringAsFixed(6)}');
    } else {
      iPerOrig = tasa.valor;
      steps.add('La tasa ya es periódica: ${iPerOrig.toStringAsFixed(6)}');
    }

    // 2) Anticipada → vencida
    if (!esVencida) {
      final old = iPerOrig;
      iPerOrig = iPerOrig / (1 - iPerOrig);
      steps.add('Anticipada→Vencida: $old/(1-$old) = '
          '${iPerOrig.toStringAsFixed(6)}');
    }

    // 3) Periódica → efectiva anual
    final iEffAnnual = pow(1 + iPerOrig, nOrig).toDouble() - 1;
    steps.add('Efectiva anual: (1+${iPerOrig.toStringAsFixed(6)})^$nOrig-1 = '
        '${iEffAnnual.toStringAsFixed(6)}');

    // 4) Efectiva anual → nominal anual destino
    final int nTar = unidadObjetivo.valor;
    final iNomTar = nTar * (pow(1 + iEffAnnual, 1 / nTar).toDouble() - 1);
    steps.add('Nominal destino: $nTar*((1+E)^(1/$nTar)-1) = '
        '${iNomTar.toStringAsFixed(6)}');

    // 5) Nominal → periódica destino
    final iPerTar = iNomTar / nTar;
    steps.add('Periódica destino: '
        '${iNomTar.toStringAsFixed(6)}/$nTar = ${iPerTar.toStringAsFixed(6)}');

    return (rate: iPerTar, steps: steps);
  }

  /// Normaliza el tipo de flujo ("ingreso", "egreso" o "todos").
  ///
  /// - Si contiene "ingreso" devuelve "ingreso".
  /// - Si contiene "egreso" devuelve "egreso".
  /// - Si contiene "todos" devuelve "todos".
  /// - En otro caso, devuelve el string en minúscula.
  static String normalizeTipo(String tipo) {
    final lower = tipo.trim().toLowerCase();
    if (lower.contains('ingreso')) {
      return 'ingreso';
    }
    if (lower.contains('egreso')) {
      return 'egreso';
    }
    if (lower.contains('todos')) {
      return 'todos';
    }
    return lower;
  }
}
