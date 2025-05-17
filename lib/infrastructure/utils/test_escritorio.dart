import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/infrastructure/utils/financial_analyzer.dart';

void main() {
  // Unidad de tiempo: semestre
  final unidadMeses = UnidadDeTiempo(id: 4, nombre: 'Mensual', valor: 12);

  final unidadSemestres = UnidadDeTiempo(id: 8, nombre: 'Semestral', valor: 2);

  final unidadAnual = UnidadDeTiempo(id: 9, nombre: 'Anual', valor: 1);

  // Tasa de interés para el diagrama
  final tasa = TasaDeInteres(
    id: 1,
    valor: 0.102,
    periodicidad: unidadAnual,
    capitalizacion: unidadSemestres,
    tipo: 'anticipada',
    periodoInicio: 0,
    periodoFin: 12,
    aplicaA: 'todos',
  );

  // Flujos (todos menos el egreso incógnita en t=0)
  final movimientos = <Movimiento>[
    // Inflows (green arrows)
    Movimiento(id: 1, tipo: 'ingreso', valor: 350.0, periodo: 6), // $350 at t=0
    Movimiento(
        id: 2, tipo: 'ingreso', valor: 300.0, periodo: 12), // $300 at t=3
    Movimiento(
        id: 3, tipo: 'ingreso', valor: 300.0, periodo: 20), // $300 at t=6
    Movimiento(id: 4, tipo: 'ingreso', valor: 85.0, periodo: 24), // $85 at t=8
    Movimiento(
        id: 5, tipo: 'ingreso', valor: 250.0, periodo: 32), // $250 at t=11

    // Outflows (red arrows)
    Movimiento(id: 6, tipo: 'egreso', valor: 200.0, periodo: 3), // $200 at t=12
    Movimiento(id: 7, tipo: 'egreso', valor: 50.0, periodo: 11), // $50 at t=13
    Movimiento(
        id: 8, tipo: 'egreso', valor: 150.0, periodo: 13), // $150 at t=20
    Movimiento(
        id: 9, tipo: 'egreso', valor: 500.0, periodo: 26), // $500 at t=24
    Movimiento(id: 10, tipo: 'egreso', valor: 440.0, periodo: 32),
  ];

  // Valor incógnita en t=0
  final valores = <Valor>[
    Valor(valor: null, tipo: 'Presente', periodo: 0, flujo: 'ingreso'),
  ];

  final diagrama = DiagramaDeFlujo(
    id: 1,
    nombre: 'Prueba Valor Presente',
    unidadDeTiempo: unidadMeses,
    cantidadDePeriodos: 32,
    periodoFocal: 0,
    tasasDeInteres: [tasa],
    movimientos: movimientos,
    valores: valores,
  );

  // Análisis con el motor de la app
  final resultado = FinancialAnalyzer.analyze(diagrama);

  print('Ecuación de valor presente:');
  print(resultado.equation);
  print('\nValor presente calculado por la app:');
  print('VP = ${resultado.solution.toStringAsFixed(6)}');

  // Comparación con el valor correcto
  const double valorCorrecto = 384729.89;
  final error =
      ((resultado.solution - valorCorrecto).abs() / valorCorrecto.abs()) * 100;
  print('\nValor correcto: $valorCorrecto');
  print('Porcentaje de error: ${error.toStringAsFixed(4)}%');
}
