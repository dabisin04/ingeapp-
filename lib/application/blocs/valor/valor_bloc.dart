import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/repositories/valor_repository.dart';
import 'valor_event.dart';
import 'valor_state.dart';

class ValorBloc extends Bloc<ValorEvent, ValorState> {
  final ValorRepository repository;

  ValorBloc({required this.repository}) : super(ValorInitial()) {
    on<CargarValoresEvent>(_onCargarValores);
    on<AgregarValorEvent>(_onAgregarValor);
    on<EditarValorEvent>(_onEditarValor);
    on<EliminarValorEvent>(_onEliminarValor);
    on<ObtenerValorPorPeriodoEvent>(_onObtenerValorPorPeriodo);
  }

  Future<void> _onCargarValores(
    CargarValoresEvent e,
    Emitter<ValorState> emit,
  ) async {
    print('▶️ [ValorBloc] CargarValoresEvent');
    emit(ValorLoading());
    try {
      final list = await repository.getValores();
      print('✅ [ValorBloc] Valores cargados: ${list.length}');
      emit(ValorLoaded(list));
    } catch (ex) {
      print('❌ [ValorBloc] Error al cargar: $ex');
      emit(ValorError('Error al cargar los valores: $ex'));
    }
  }

  Future<void> _onAgregarValor(
    AgregarValorEvent e,
    Emitter<ValorState> emit,
  ) async {
    print('▶️ [ValorBloc] AgregarValorEvent: ${e.valor}');
    try {
      await repository.addValor(e.valor);
      add(CargarValoresEvent());
    } catch (ex) {
      print('❌ [ValorBloc] Error al agregar: $ex');
      emit(ValorError('Error al agregar el valor: $ex'));
    }
  }

  Future<void> _onEditarValor(
    EditarValorEvent e,
    Emitter<ValorState> emit,
  ) async {
    print('▶️ [ValorBloc] EditarValorEvent: ${e.valorActualizado}');
    try {
      await repository.updateValor(e.valorActualizado);
    } on Exception catch (ex) {
      final msg = ex.toString();
      if (msg.contains('no encontrado')) {
        print('⚠️ Valor no existente – insertando en su lugar');
        await repository.addValor(e.valorActualizado);
      } else {
        print('❌ [ValorBloc] Error al editar: $ex');
        emit(ValorError('Error al editar el valor: $ex'));
        return;
      }
    }
    add(CargarValoresEvent());
  }

  Future<void> _onEliminarValor(
    EliminarValorEvent e,
    Emitter<ValorState> emit,
  ) async {
    print(
      '▶️ [ValorBloc] EliminarValorEvent: periodo=${e.periodo}, tipo=${e.tipo}, flujo=${e.flujo}',
    );
    try {
      await repository.deleteValor(
          e.periodo, e.tipo, e.flujo); // ✅ ya acepta int?
      emit(ValorDeleted(e.periodo, e.tipo, e.flujo));
      add(CargarValoresEvent());
    } catch (ex) {
      print('❌ [ValorBloc] Error al eliminar: $ex');
      emit(ValorError('Error al eliminar el valor: $ex'));
    }
  }

  Future<void> _onObtenerValorPorPeriodo(
    ObtenerValorPorPeriodoEvent e,
    Emitter<ValorState> emit,
  ) async {
    print('▶️ [ValorBloc] ObtenerValorPorPeriodoEvent: periodo=${e.periodo}');
    try {
      final v = await repository.getValorPorPeriodo(e.periodo);
      emit(ValorPorPeriodoLoaded(v));
    } catch (ex) {
      print('❌ [ValorBloc] Error al obtener por periodo: $ex');
      emit(ValorError('Error al obtener el valor por periodo: $ex'));
    }
  }
}
