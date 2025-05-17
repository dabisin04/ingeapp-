import 'dart:convert';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/valor.dart';

class DiagramaDeFlujo {
  final int id;
  final String nombre;
  final String? descripcion;
  final UnidadDeTiempo unidadDeTiempo;
  final int cantidadDePeriodos;
  final int? periodoFocal;
  final List<TasaDeInteres> tasasDeInteres;
  final List<Movimiento> movimientos;
  final List<Valor> valores;

  DiagramaDeFlujo({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.unidadDeTiempo,
    required this.cantidadDePeriodos,
    this.periodoFocal,
    required this.tasasDeInteres,
    required this.movimientos,
    required this.valores,
  });

  DiagramaDeFlujo copyWith({
    String? nombre,
    String? descripcion,
    int? cantidadDePeriodos,
    int? periodoFocal,
    List<TasaDeInteres>? tasasDeInteres,
    List<Movimiento>? movimientos,
    List<Valor>? valores,
  }) =>
      DiagramaDeFlujo(
        id: id,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        unidadDeTiempo: unidadDeTiempo,
        cantidadDePeriodos: cantidadDePeriodos ?? this.cantidadDePeriodos,
        periodoFocal: periodoFocal ?? this.periodoFocal,
        tasasDeInteres: tasasDeInteres ?? this.tasasDeInteres,
        movimientos: movimientos ?? this.movimientos,
        valores: valores ?? this.valores,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'unidadDeTiempo': unidadDeTiempo.toMap(),
        'cantidadDePeriodos': cantidadDePeriodos,
        'periodoFocal': periodoFocal,
        'tasasDeInteres': tasasDeInteres.map((t) => t.toMap()).toList(),
        'movimientos': movimientos.map((m) => m.toMap()).toList(),
        'valores': valores.map((v) => v.toMap()).toList(),
      };

  String encode() => jsonEncode(toMap());

  static DiagramaDeFlujo decode(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return DiagramaDeFlujo(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      unidadDeTiempo: UnidadDeTiempo.fromMap(
        map['unidadDeTiempo'] as Map<String, dynamic>,
      ),
      cantidadDePeriodos: map['cantidadDePeriodos'] as int,
      periodoFocal:
          map['periodoFocal'] != null ? map['periodoFocal'] as int : null,
      tasasDeInteres: (map['tasasDeInteres'] as List)
          .map((e) => TasaDeInteres.fromMap(e as Map<String, dynamic>))
          .toList(),
      movimientos: (map['movimientos'] as List)
          .map((e) => Movimiento.fromMap(e as Map<String, dynamic>))
          .toList(),
      valores: (map['valores'] as List)
          .map((e) => Valor.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
