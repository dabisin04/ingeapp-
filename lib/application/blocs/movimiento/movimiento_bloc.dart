import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/repositories/movimiento_repository.dart';
import 'movimiento_event.dart';
import 'movimiento_state.dart';

class MovimientoBloc extends Bloc<MovimientoEvent, MovimientoState> {
  final MovementRepository repository;

  MovimientoBloc({required this.repository}) : super(MovimientoInitial()) {
    on<CargarMovimientos>(_onCargarMovimientos);
    on<AgregarMovimiento>(_onAgregarMovimiento);
    on<EditarMovimiento>(_onEditarMovimiento);
    on<EliminarMovimiento>(_onEliminarMovimiento);
  }

  Future<void> _onCargarMovimientos(
    CargarMovimientos event,
    Emitter<MovimientoState> emit,
  ) async {
    emit(MovimientoLoading());
    try {
      final movimientos = await repository.getAllMovements();
      emit(MovimientoLoaded(movimientos: movimientos));
    } catch (e) {
      emit(MovimientoError(mensaje: e.toString()));
    }
  }

  Future<void> _onAgregarMovimiento(
    AgregarMovimiento event,
    Emitter<MovimientoState> emit,
  ) async {
    try {
      await repository.addMovement(event.movimiento);
      add(CargarMovimientos()); // Reload list of movements after adding
    } catch (e) {
      emit(MovimientoError(mensaje: e.toString()));
    }
  }

  Future<void> _onEditarMovimiento(
    EditarMovimiento event,
    Emitter<MovimientoState> emit,
  ) async {
    try {
      await repository.updateMovement(event.movimiento);
      add(CargarMovimientos());
    } catch (e) {
      emit(MovimientoError(mensaje: e.toString()));
    }
  }

  Future<void> _onEliminarMovimiento(
    EliminarMovimiento event,
    Emitter<MovimientoState> emit,
  ) async {
    try {
      await repository.deleteMovement(event.movimiento);
      add(CargarMovimientos());
    } catch (e) {
      emit(MovimientoError(mensaje: e.toString()));
    }
  }
}
