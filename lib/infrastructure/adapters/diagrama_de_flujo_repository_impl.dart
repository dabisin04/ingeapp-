import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/infrastructure/utils/financial_analyzer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/repositories/diagrama_de_flujo_repository.dart';

class FlowDiagramAdapter implements FlowDiagramRepository {
  static const String _historyKey = 'diagram_history';
  DiagramaDeFlujo? _diagram;

  Future<void> initializeDiagram({
    required int periods,
    required UnidadDeTiempo unit,
    List<TasaDeInteres>? tasas,
    List<Valor>? valores,
    List<Movimiento>? movimientos,
    String? descripcion,
    int? periodoFocal,
  }) async {
    if (_diagram != null) {
      await _saveCurrentToHistory();
    }
    _diagram = DiagramaDeFlujo(
      id: DateTime.now().millisecondsSinceEpoch,
      nombre: _diagram?.nombre ?? 'Diagrama ${DateTime.now()}',
      descripcion: descripcion ?? _diagram?.descripcion,
      unidadDeTiempo: unit,
      cantidadDePeriodos: periods,
      periodoFocal: periodoFocal ?? _diagram?.periodoFocal,
      tasasDeInteres: tasas ?? _diagram?.tasasDeInteres ?? [],
      movimientos: movimientos ?? _diagram?.movimientos ?? [],
      valores: valores ?? _diagram?.valores ?? [],
    );
    await _saveCurrentToHistory();
  }

  @override
  Future<DiagramaDeFlujo> getDiagram() async {
    if (_diagram == null) {
      throw Exception('Diagrama no inicializado');
    }
    return _diagram!;
  }

  @override
  Future<void> updatePeriods(int periods) async {
    if (_diagram == null) throw Exception('No hay diagrama activo');
    _diagram = _diagram!.copyWith(cantidadDePeriodos: periods);
    await _saveCurrentToHistory();
  }

  @override
  Future<void> updateTasas(List<TasaDeInteres> tasas) async {
    if (_diagram == null) throw Exception('No hay diagrama activo');
    _diagram = _diagram!.copyWith(tasasDeInteres: tasas);
    await _saveCurrentToHistory();
  }

  @override
  Future<void> updateMovimientos(List<Movimiento> movimientos) async {
    if (_diagram == null) throw Exception('No hay diagrama activo');
    _diagram = _diagram!.copyWith(movimientos: movimientos);
    await _saveCurrentToHistory();
  }

  @override
  Future<void> updateValores(List<Valor> valores) async {
    if (_diagram == null) throw Exception('No hay diagrama activo');
    _diagram = _diagram!.copyWith(valores: valores);
    await _saveCurrentToHistory();
  }

  @override
  Future<void> clearDiagram() async {
    _diagram = null;
  }

  Future<void> _saveCurrentToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? <String>[];
    list.add(_diagram!.encode());
    await prefs.setStringList(_historyKey, list);
  }

  @override
  Future<List<DiagramaDeFlujo>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? <String>[];
    return list.map((s) => DiagramaDeFlujo.decode(s)).toList();
  }

  @override
  Future<void> updateDescription(String descripcion) async {
    if (_diagram == null) {
      _diagram = DiagramaDeFlujo(
        id: DateTime.now().millisecondsSinceEpoch,
        nombre: 'Diagrama ${DateTime.now()}',
        descripcion: descripcion,
        unidadDeTiempo: UnidadDeTiempo(id: 0, nombre: 'Sin unidad', valor: 0),
        cantidadDePeriodos: 0,
        periodoFocal: 0,
        tasasDeInteres: [],
        movimientos: [],
        valores: [],
      );
      await _saveCurrentToHistory();
      return;
    }
    await _saveCurrentToHistory();
    _diagram = _diagram!.copyWith(
      descripcion: descripcion,
      tasasDeInteres: [],
      movimientos: [],
      valores: [],
    );
    await _saveCurrentToHistory();
  }

  @override
  Future<EquationAnalysis> analyzeDiagram(DiagramaDeFlujo diagram) async {
    return FinancialAnalyzer.analyze(diagram);
  }

  @override
  Future<void> updateFocalPeriod(int? periodoFocal) async {
    if (_diagram != null) await _saveCurrentToHistory();
    _diagram = DiagramaDeFlujo(
      id: _diagram?.id ?? DateTime.now().millisecondsSinceEpoch,
      nombre: _diagram?.nombre ?? 'Diagrama ${DateTime.now()}',
      descripcion: _diagram?.descripcion,
      unidadDeTiempo: _diagram?.unidadDeTiempo ??
          UnidadDeTiempo(id: 0, nombre: 'Sin unidad', valor: 0),
      cantidadDePeriodos: _diagram?.cantidadDePeriodos ?? 0,
      periodoFocal: periodoFocal, // inyectamos el nullable
      tasasDeInteres: _diagram?.tasasDeInteres ?? [],
      movimientos: _diagram?.movimientos ?? [],
      valores: _diagram?.valores ?? [],
    );
    await _saveCurrentToHistory();
  }
}
