import 'dart:convert';

class Valor {
  final dynamic valor; // ← puede ser double o String
  final String tipo;
  final int? periodo;
  final String flujo;

  Valor({
    this.valor,
    required this.tipo,
    this.periodo,
    required this.flujo,
  });

  Map<String, dynamic> toMap() => {
        'valor': valor, // ← lo guarda como esté: número o texto
        'tipo': tipo,
        'periodo': periodo,
        'flujo': flujo,
      };

  factory Valor.fromMap(Map<String, dynamic> map) => Valor(
        valor: map['valor'], // ← NO convertir
        tipo: map['tipo'] as String,
        periodo: map['periodo'] != null ? map['periodo'] as int : null,
        flujo: map['flujo'] as String,
      );

  String encode() => jsonEncode(toMap());

  static Valor decode(String source) =>
      Valor.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
