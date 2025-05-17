import 'dart:convert';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

const String kAplicaTodos = 'Todos';
const String kAplicaIngresos = 'Ingresos';
const String kAplicaEgresos = 'Egresos';

class TasaDeInteres {
  final int id;
  final double valor;
  final UnidadDeTiempo periodicidad;
  final UnidadDeTiempo capitalizacion;
  final String tipo;
  final int periodoInicio; // Periodo de inicio de la tasa
  final int periodoFin; // Periodo de fin de la tasa
  final String
      aplicaA; // Aplica a: 'Todos los movimientos', 'Ingresos', 'Egresos'

  TasaDeInteres({
    required this.id,
    required this.valor,
    required this.periodicidad,
    required this.capitalizacion,
    required this.tipo,
    required this.periodoInicio,
    required this.periodoFin,
    this.aplicaA = kAplicaTodos,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'valor': valor,
        'periodicidad': periodicidad.toMap(),
        'capitalizacion': capitalizacion.toMap(),
        'tipo': tipo,
        'periodoInicio': periodoInicio,
        'periodoFin': periodoFin,
        'aplicaA': aplicaA,
      };

  factory TasaDeInteres.fromMap(Map<String, dynamic> map) => TasaDeInteres(
        id: map['id'] as int,
        valor: (map['valor'] as num).toDouble(),
        periodicidad:
            UnidadDeTiempo.fromMap(map['periodicidad'] as Map<String, dynamic>),
        capitalizacion: UnidadDeTiempo.fromMap(
            map['capitalizacion'] as Map<String, dynamic>),
        tipo: map['tipo'] as String,
        periodoInicio: map['periodoInicio'] as int,
        periodoFin: map['periodoFin'] as int,
        aplicaA: (map['aplicaA'] as String?) ?? kAplicaTodos,
      );

  String encode() => jsonEncode(toMap());

  static TasaDeInteres decode(String source) =>
      TasaDeInteres.fromMap(jsonDecode(source) as Map<String, dynamic>);

  // Método copyWith para crear una copia modificada
  TasaDeInteres copyWith({
    int? id,
    double? valor,
    UnidadDeTiempo? periodicidad,
    UnidadDeTiempo? capitalizacion,
    String? tipo,
    int? periodoInicio,
    int? periodoFin,
    String? aplicaA,
  }) {
    return TasaDeInteres(
      id: id ?? this.id,
      valor: valor ?? this.valor,
      periodicidad: periodicidad ?? this.periodicidad,
      capitalizacion: capitalizacion ?? this.capitalizacion,
      tipo: tipo ?? this.tipo,
      periodoInicio: periodoInicio ?? this.periodoInicio,
      periodoFin: periodoFin ?? this.periodoFin,
      aplicaA: aplicaA ?? this.aplicaA,
    );
  }
}
