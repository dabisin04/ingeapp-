import 'package:inge_app/domain/entities/valor.dart';

abstract class ValorRepository {
  Future<void> addValor(Valor valor);
  Future<List<Valor>> getValores();
  Future<void> updateValor(Valor valor);
  Future<void> deleteValor(int? periodo, String tipo, String flujo);
  Future<Valor> getValorPorPeriodo(int periodo);
}
