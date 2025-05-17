import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/domain/repositories/valor_repository.dart';

class ValorAdapter implements ValorRepository {
  final List<Valor> _valores = [];

  @override
  Future<void> addValor(Valor valor) async {
    print(
      '⬆️ [ValorAdapter] addValor: periodo=${valor.periodo}, tipo=${valor.tipo}, flujo=${valor.flujo}, valor=${valor.valor}',
    );
    _valores.add(valor);
  }

  @override
  Future<List<Valor>> getValores() async {
    print('📦 [ValorAdapter] getValores → ${_valores.length} registros');
    return _valores;
  }

  @override
  Future<void> updateValor(Valor valor) async {
    print(
      '🔄 [ValorAdapter] upsertValor: periodo=${valor.periodo}, '
      'tipo=${valor.tipo}, flujo=${valor.flujo}, valor=${valor.valor}',
    );

    final index = _valores.indexWhere(
      (v) =>
          v.periodo == valor.periodo &&
          v.tipo == valor.tipo &&
          v.flujo == valor.flujo,
    );

    if (index != -1) {
      // Si existe, actualiza
      _valores[index] = valor;
      print('   ↪️ Registro existente actualizado.');
    } else {
      // Si no existe, lo agrega
      _valores.add(valor);
      print('   ➕ Registro no encontrado, insertado como nuevo.');
    }
  }

  @override
  Future<void> deleteValor(int? periodo, String tipo, String flujo) async {
    _valores.removeWhere((v) {
      if (periodo != null) {
        // Si viene periodo, compara periodo + tipo + flujo
        return v.periodo == periodo && v.tipo == tipo && v.flujo == flujo;
      } else {
        // Si no viene periodo, compara solo tipo + flujo
        return v.tipo == tipo && v.flujo == flujo;
      }
    });
  }

  @override
  Future<Valor> getValorPorPeriodo(int periodo) async {
    print('🔍 [ValorAdapter] getValorPorPeriodo: periodo=$periodo');
    try {
      return _valores.firstWhere((v) => v.periodo == periodo);
    } catch (_) {
      throw Exception('Valor no encontrado para el periodo $periodo');
    }
  }
}
