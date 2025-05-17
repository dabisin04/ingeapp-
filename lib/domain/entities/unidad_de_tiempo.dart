import 'dart:convert';

class UnidadDeTiempo {
  final int id;
  final String nombre;
  final int valor;

  UnidadDeTiempo({required this.id, required this.nombre, required this.valor});

  Map<String, dynamic> toMap() => {'id': id, 'nombre': nombre, 'valor': valor};

  factory UnidadDeTiempo.fromMap(Map<String, dynamic> map) => UnidadDeTiempo(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
        valor: map['valor'] as int,
      );

  String encode() => jsonEncode(toMap());

  static UnidadDeTiempo decode(String source) =>
      UnidadDeTiempo.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
