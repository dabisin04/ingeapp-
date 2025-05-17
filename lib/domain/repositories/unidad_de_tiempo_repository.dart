import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

abstract class UnidadDeTiempoRepository {
  Future<List<UnidadDeTiempo>> obtenerUnidadesDeTiempo();
  Future<UnidadDeTiempo> obtenerUnidadDeTiempoPorId(int id);
  Future<String> obtenerNombrePorId(int id);
  Future<int> obtenerValorPorId(int id);
}
