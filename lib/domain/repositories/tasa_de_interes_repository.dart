import 'package:inge_app/domain/entities/tasa_de_interes.dart';

abstract class TasaInteresRepository {
  Future<void> agregarTasaInteres(TasaDeInteres tasa);
  Future<void> editarTasaInteres(int id, TasaDeInteres tasaActualizada);
  Future<void> eliminarTasaInteres(int id);
  Future<List<TasaDeInteres>> obtenerTasasInteres();
  Future<TasaDeInteres?> obtenerTasaPorPeriodo(int periodo);
}
