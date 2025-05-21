import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';

import 'financial_analysis.dart'; // ► n desconocido
import 'financial_analysis_pvfv.dart'; // ► VP / VF
import 'financial_analysis_irr.dart'; // ► IRR (con / sin foco)
import 'financial_analysis_series.dart'; // ► Series puras / diferidas
import 'financial_analysis_single_unknown.dart'; // ► 1 incógnita X
import 'financial_analysis_multiple_unknowns.dart'; // ► >1 incógnita X
import 'financial_analysis_two_unknowns_balance.dart'; // ► Serie + saldo (2 incógn.)

class FinancialAnalyzer {
  /* ───────── DEBUG opcional ───────── */
  static void debugPrintDiagramaDeFlujo(DiagramaDeFlujo d) {
    print('════════ DIAGRAMA ════════');
    print(
        'UT:${d.unidadDeTiempo.nombre}  n:${d.cantidadDePeriodos}  foco:${d.periodoFocal}');
    print('── Tasas');
    for (var t in d.tasasDeInteres) {
      print(
          ' • ${t.periodoInicio}-${t.periodoFin}: ${(t.valor * 100).toStringAsFixed(3)}% '
          '(${t.tipo}, ${t.aplicaA})');
    }
    print('── Valores');
    for (var v in d.valores) {
      print(' • ${v.tipo} ${v.flujo}  t=${v.periodo}  \$${v.valor} '
          '${v.esSerie == true ? "(serie ${v.tipoSerie})" : ""}');
    }
    print('── Movimientos');
    for (var m in d.movimientos) {
      print(' • ${m.tipo}  t=${m.periodo}  \$${m.valor} '
          '${m.esSerie == true ? "(serie ${m.tipoSerie})" : ""}');
    }
    print('══════════════════════════');
  }

  /* ───────── FORMATOS JSON ESPERADOS ───────── */
  static Map<String, String> getJsonFormats() {
    return {
      'SERIE-SALDO': '''
{
  "unidadDeTiempo": {"id": "mes", "nombre": "Mensual"},
  "cantidadDePeriodos": 12,
  "periodoFocal": 0,
  "tasasDeInteres": [
    {
      "id": "t1",
      "valor": 0.01,
      "periodicidad": {"id": "mes", "nombre": "Mensual"},
      "capitalizacion": {"id": "mes", "nombre": "Mensual"},
      "tipo": "Vencida",
      "periodoInicio": 0,
      "periodoFin": 12,
      "aplicaA": "todos"
    }
  ],
  "valores": [
    {
      "tipo": "P",
      "flujo": "egreso",
      "periodo": 0,
      "valor": "P",
      "esSerie": false
    },
    {
      "tipo": "A",
      "flujo": "ingreso",
      "periodo": 1,
      "hastaPeriodo": 12,
      "valor": 100,
      "esSerie": true,
      "tipoSerie": "vencida"
    },
    {
      "tipo": "F",
      "flujo": "ingreso",
      "periodo": 6,
      "valor": 500,
      "esSerie": false
    }
  ],
  "movimientos": []
}''',
      'SERIES': '''
{
  "unidadDeTiempo": {"id": "mes", "nombre": "Mensual"},
  "cantidadDePeriodos": 12,
  "periodoFocal": 0,
  "tasasDeInteres": [
    {
      "id": "t1",
      "valor": 0.01,
      "periodicidad": {"id": "mes", "nombre": "Mensual"},
      "capitalizacion": {"id": "mes", "nombre": "Mensual"},
      "tipo": "Vencida",
      "periodoInicio": 0,
      "periodoFin": 12,
      "aplicaA": "todos"
    }
  ],
  "valores": [
    {
      "tipo": "A",
      "flujo": "ingreso",
      "periodo": 1,
      "hastaPeriodo": 12,
      "valor": 100,
      "esSerie": true,
      "tipoSerie": "vencida"
    }
  ],
  "movimientos": []
}''',
      'X-MULTI': '''
{
  "unidadDeTiempo": {"id": "mes", "nombre": "Mensual"},
  "cantidadDePeriodos": 12,
  "periodoFocal": 0,
  "tasasDeInteres": [
    {
      "id": "t1",
      "valor": 0.01,
      "periodicidad": {"id": "mes", "nombre": "Mensual"},
      "capitalizacion": {"id": "mes", "nombre": "Mensual"},
      "tipo": "Vencida",
      "periodoInicio": 0,
      "periodoFin": 12,
      "aplicaA": "todos"
    }
  ],
  "valores": [
    {
      "tipo": "X",
      "flujo": "ingreso",
      "periodo": 0,
      "valor": "X",
      "esSerie": false
    },
    {
      "tipo": "Y",
      "flujo": "egreso",
      "periodo": 6,
      "valor": "2X",
      "esSerie": false
    }
  ],
  "movimientos": []
}''',
      'X-SINGLE': '''
{
  "unidadDeTiempo": {"id": "mes", "nombre": "Mensual"},
  "cantidadDePeriodos": 12,
  "periodoFocal": 0,
  "tasasDeInteres": [
    {
      "id": "t1",
      "valor": 0.01,
      "periodicidad": {"id": "mes", "nombre": "Mensual"},
      "capitalizacion": {"id": "mes", "nombre": "Mensual"},
      "tipo": "Vencida",
      "periodoInicio": 0,
      "periodoFin": 12,
      "aplicaA": "todos"
    }
  ],
  "valores": [
    {
      "tipo": "X",
      "flujo": "ingreso",
      "periodo": 0,
      "valor": "X",
      "esSerie": false
    }
  ],
  "movimientos": [
    {
      "tipo": "egreso",
      "periodo": 6,
      "valor": 500,
      "esSerie": false
    }
  ]
}''',
      'UNKNOWN-N': '''
{
  "unidadDeTiempo": {"id": "mes", "nombre": "Mensual"},
  "cantidadDePeriodos": 12,
  "periodoFocal": 0,
  "tasasDeInteres": [
    {
      "id": "t1",
      "valor": 0.01,
      "periodicidad": {"id": "mes", "nombre": "Mensual"},
      "capitalizacion": {"id": "mes", "nombre": "Mensual"},
      "tipo": "Vencida",
      "periodoInicio": 0,
      "periodoFin": 12,
      "aplicaA": "todos"
    }
  ],
  "valores": [
    {
      "tipo": "F",
      "flujo": "ingreso",
      "periodo": null,
      "valor": 1000,
      "esSerie": false
    }
  ],
  "movimientos": [
    {
      "tipo": "egreso",
      "periodo": 0,
      "valor": 500,
      "esSerie": false
    }
  ]
}''',
      'PVFV': '''
{
  "unidadDeTiempo": {"id": "mes", "nombre": "Mensual"},
  "cantidadDePeriodos": 12,
  "periodoFocal": 0,
  "tasasDeInteres": [
    {
      "id": "t1",
      "valor": 0.01,
      "periodicidad": {"id": "mes", "nombre": "Mensual"},
      "capitalizacion": {"id": "mes", "nombre": "Mensual"},
      "tipo": "Vencida",
      "periodoInicio": 0,
      "periodoFin": 12,
      "aplicaA": "todos"
    }
  ],
  "valores": [
    {
      "tipo": "P",
      "flujo": "egreso",
      "periodo": 0,
      "valor": null,
      "esSerie": false
    }
  ],
  "movimientos": [
    {
      "tipo": "ingreso",
      "periodo": 12,
      "valor": 1000,
      "esSerie": false
    }
  ]
}''',
      'IRR-FOCAL': '''
{
  "unidadDeTiempo": {"id": "mes", "nombre": "Mensual"},
  "cantidadDePeriodos": 12,
  "periodoFocal": 6,
  "tasasDeInteres": [
    {
      "id": "t1",
      "valor": 0.01,
      "periodicidad": {"id": "mes", "nombre": "Mensual"},
      "capitalizacion": {"id": "mes", "nombre": "Mensual"},
      "tipo": "Vencida",
      "periodoInicio": 0,
      "periodoFin": 12,
      "aplicaA": "todos"
    }
  ],
  "valores": [],
  "movimientos": [
    {
      "tipo": "egreso",
      "periodo": 0,
      "valor": 1000,
      "esSerie": false
    },
    {
      "tipo": "ingreso",
      "periodo": 6,
      "valor": 500,
      "esSerie": false
    },
    {
      "tipo": "ingreso",
      "periodo": 12,
      "valor": 600,
      "esSerie": false
    }
  ]
}''',
      'IRR-SIMPLE': '''
{
  "unidadDeTiempo": {"id": "mes", "nombre": "Mensual"},
  "cantidadDePeriodos": 12,
  "periodoFocal": 0,
  "tasasDeInteres": [
    {
      "id": "t1",
      "valor": 0.01,
      "periodicidad": {"id": "mes", "nombre": "Mensual"},
      "capitalizacion": {"id": "mes", "nombre": "Mensual"},
      "tipo": "Vencida",
      "periodoInicio": 0,
      "periodoFin": 12,
      "aplicaA": "todos"
    }
  ],
  "valores": [],
  "movimientos": [
    {
      "tipo": "egreso",
      "periodo": 0,
      "valor": 1000,
      "esSerie": false
    },
    {
      "tipo": "ingreso",
      "periodo": 12,
      "valor": 1200,
      "esSerie": false
    }
  ]
}'''
    };
  }

  static int _countX(DiagramaDeFlujo d) {
    int c = 0;
    for (final dynamic v in [...d.valores, ...d.movimientos]) {
      final val = v.valor;
      if (val is String && val.toUpperCase().contains('X')) c++;
    }
    return c;
  }

  static String branch(DiagramaDeFlujo d) {
    final hasRates = d.tasasDeInteres.isNotEmpty;
    final xCount = _countX(d);
    final hasUnknownPeriodValue =
        d.valores.any((v) => v.periodo == null && v.valor != null) ||
            d.movimientos.any((m) => m.periodo == null && m.valor != null);

    // --- PV/FV ---
    final valoresNull = d.valores.where((v) => v.valor == null).toList();
    final valoresX = d.valores
        .where((v) =>
            v.valor is String &&
            (v.valor as String).toUpperCase().contains('X'))
        .toList();
    final hasPVFVUnknown = (valoresNull.length + valoresX.length) == 1;
    bool pvfvPosOk = false;
    if (hasPVFVUnknown) {
      final u = valoresNull.isNotEmpty ? valoresNull.first : valoresX.first;
      final periods = [
        ...d.valores.map((v) => v.periodo),
        ...d.movimientos.map((m) => m.periodo)
      ].whereType<int>().toList();
      if (periods.isNotEmpty) {
        final maxP = periods.reduce((a, b) => a > b ? a : b);
        pvfvPosOk = (u.periodo == 0 || u.periodo == maxP);
      }
    }

    // ✅ 1. Detectar caso de serie + saldo (tiene prioridad máxima)
    if (FinancialAnalysisTwoUnknownsBalance.isCandidate(d)) {
      return 'SERIE-SALDO';
    }

    // ✅ 2. Series normales
    final hasSeries = d.valores.any((v) => v.esSerie == true) ||
        d.movimientos.any((m) => m.esSerie == true);
    if (hasSeries) return 'SERIES';

    // ✅ 3. Multi-X
    if (hasRates && xCount > 1) return 'X-MULTI';

    // ✅ 4. Single-X
    if (hasRates && xCount == 1) return 'X-SINGLE';

    // ✅ 5. Periodos desconocidos
    if (hasRates && hasUnknownPeriodValue) return 'UNKNOWN-N';

    // ✅ 6. VP/VF
    if (hasRates && hasPVFVUnknown && pvfvPosOk) return 'PVFV';

    // ✅ 7. IRR
    if (hasRates) return 'IRR-FOCAL';
    return 'IRR-SIMPLE';
  }

  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    debugPrintDiagramaDeFlujo(d);

    switch (branch(d)) {
      case 'SERIE-SALDO':
        return FinancialAnalysisTwoUnknownsBalance.analyze(d);

      case 'SERIES':
        return FinancialAnalysisSeries.analyze(d);

      case 'X-MULTI':
        return FinancialAnalysisUnknown.analyze(d);

      case 'X-SINGLE':
        return FinancialAnalysisSingleUnknown.analyze(d);

      case 'UNKNOWN-N':
        return FinancialAnalysis.analyze(d);

      case 'PVFV':
        return FinancialAnalysisPVFV.analyze(d);

      case 'IRR-FOCAL':
        return FinancialAnalysisIRR.analyze(d);

      case 'IRR-SIMPLE':
      default:
        return FinancialAnalysisIRR.analyze(d);
    }
  }
}
