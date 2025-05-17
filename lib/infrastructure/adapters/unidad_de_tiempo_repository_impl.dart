import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/repositories/unidad_de_tiempo_repository.dart';

class UnidadDeTiempoAdapter implements UnidadDeTiempoRepository {
  final List<UnidadDeTiempo> _unidadesDeTiempo = [
    UnidadDeTiempo(id: 1, nombre: 'Diaria', valor: 360),
    UnidadDeTiempo(id: 2, nombre: 'Semanal', valor: 48),
    UnidadDeTiempo(id: 3, nombre: 'Quincenal', valor: 24),
    UnidadDeTiempo(id: 4, nombre: 'Mensual', valor: 12),
    UnidadDeTiempo(id: 5, nombre: 'Bimestral', valor: 6),
    UnidadDeTiempo(id: 6, nombre: 'Trimestral', valor: 4),
    UnidadDeTiempo(id: 7, nombre: 'Cuatrimestral', valor: 3),
    UnidadDeTiempo(id: 8, nombre: 'Semestral', valor: 2),
    UnidadDeTiempo(id: 9, nombre: 'Anual', valor: 1),
  ];

  @override
  Future<List<UnidadDeTiempo>> obtenerUnidadesDeTiempo() async {
    return _unidadesDeTiempo;
  }

  @override
  Future<UnidadDeTiempo> obtenerUnidadDeTiempoPorId(int id) async {
    try {
      return _unidadesDeTiempo.firstWhere((unidad) => unidad.id == id);
    } catch (_) {
      throw Exception('Unidad de tiempo con ID $id no encontrada');
    }
  }

  @override
  Future<String> obtenerNombrePorId(int id) async {
    try {
      return _unidadesDeTiempo.firstWhere((unidad) => unidad.id == id).nombre;
    } catch (_) {
      throw Exception('Nombre de unidad de tiempo con ID $id no encontrado');
    }
  }

  @override
  Future<int> obtenerValorPorId(int id) async {
    try {
      return _unidadesDeTiempo.firstWhere((unidad) => unidad.id == id).valor;
    } catch (_) {
      throw Exception('Valor de unidad de tiempo con ID $id no encontrado');
    }
  }
}
