import 'dart:convert';

/// Clase que representa un valor financiero en un diagrama de flujo.
///
/// Un valor puede ser:
/// - Un flujo puntual (esSerie = false)
/// - Una serie de pagos (esSerie = true)
///
/// Los tipos de flujo permitidos son:
/// - 'ingreso': Representa un ingreso de dinero
/// - 'egreso': Representa un egreso de dinero
class Valor {
  /// El valor numérico del flujo
  final dynamic valor;

  /// El tipo de valor (ej: 'constante', 'variable')
  final String tipo;

  /// El período en que ocurre el flujo
  final int? periodo;

  /// El tipo de flujo ('ingreso' o 'egreso')
  final String flujo;

  /// Indica si el valor es parte de una serie
  final bool esSerie;

  /// El tipo de serie si esSerie es true ('anticipada' o 'vencida')
  final String? tipoSerie;

  /// El período final si esSerie es true
  final int? hastaPeriodo;

  Valor({
    this.valor,
    required this.tipo,
    this.periodo,
    required this.flujo,
    this.esSerie = false,
    this.tipoSerie,
    this.hastaPeriodo,
  }) {
    // Validaciones
    if (flujo != 'ingreso' && flujo != 'egreso') {
      throw ArgumentError('El tipo de flujo debe ser "ingreso" o "egreso"');
    }

    if (esSerie) {
      if (tipoSerie == null) {
        throw ArgumentError('tipoSerie es requerido cuando esSerie es true');
      }
      if (tipoSerie != 'anticipada' && tipoSerie != 'vencida') {
        throw ArgumentError('tipoSerie debe ser "anticipada" o "vencida"');
      }
      if (hastaPeriodo == null) {
        throw ArgumentError('hastaPeriodo es requerido cuando esSerie es true');
      }
      if (periodo == null) {
        throw ArgumentError('periodo es requerido cuando esSerie es true');
      }
      if (hastaPeriodo! <= periodo!) {
        throw ArgumentError('hastaPeriodo debe ser mayor que periodo');
      }
    }
  }

  Map<String, dynamic> toMap() => {
        'valor': valor,
        'tipo': tipo,
        'periodo': periodo,
        'flujo': flujo,
        'esSerie': esSerie,
        'tipoSerie': tipoSerie,
        'hastaPeriodo': hastaPeriodo,
      };

  factory Valor.fromMap(Map<String, dynamic> map) => Valor(
        valor: map['valor'],
        tipo: map['tipo'] as String,
        periodo: map['periodo'] != null ? map['periodo'] as int : null,
        flujo: map['flujo'] as String,
        esSerie: map['esSerie'] ?? false,
        tipoSerie: map['tipoSerie'],
        hastaPeriodo: map['hastaPeriodo'],
      );

  String encode() => jsonEncode(toMap());

  static Valor decode(String source) =>
      Valor.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
