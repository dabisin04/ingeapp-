import 'dart:convert';

class Movimiento {
  final int id;
  final dynamic valor;
  final String tipo;
  final int? periodo;

  // Nuevos campos
  final bool esSerie;
  final String? tipoSerie;
  final int? hastaPeriodo;

  Movimiento({
    required this.id,
    this.valor,
    required this.tipo,
    this.periodo,
    this.esSerie = false,
    this.tipoSerie,
    this.hastaPeriodo,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'valor': valor,
        'tipo': tipo,
        'periodo': periodo,
        'esSerie': esSerie,
        'tipoSerie': tipoSerie,
        'hastaPeriodo': hastaPeriodo,
      };

  factory Movimiento.fromMap(Map<String, dynamic> map) => Movimiento(
        id: map['id'] as int,
        valor: map['valor'],
        tipo: map['tipo'] as String,
        periodo: map['periodo'] != null ? map['periodo'] as int : null,
        esSerie: map['esSerie'] ?? false,
        tipoSerie: map['tipoSerie'],
        hastaPeriodo: map['hastaPeriodo'],
      );

  String encode() => jsonEncode(toMap());

  static Movimiento decode(String source) =>
      Movimiento.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
