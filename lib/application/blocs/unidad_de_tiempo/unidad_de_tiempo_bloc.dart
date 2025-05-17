import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/repositories/unidad_de_tiempo_repository.dart';
import 'unidad_de_tiempo_event.dart';
import 'unidad_de_tiempo_state.dart';

class UnidadDeTiempoBloc
    extends Bloc<UnidadDeTiempoEvent, UnidadDeTiempoState> {
  final UnidadDeTiempoRepository repository;

  UnidadDeTiempoBloc({required this.repository})
    : super(UnidadDeTiempoInitial()) {
    on<CargarUnidadesDeTiempo>(_onCargarUnidades);
    on<SeleccionarUnidadDeTiempo>(_onSeleccionarUnidad);
  }

  Future<void> _onCargarUnidades(
    CargarUnidadesDeTiempo event,
    Emitter<UnidadDeTiempoState> emit,
  ) async {
    emit(UnidadDeTiempoLoading());
    try {
      final unidades = await repository.obtenerUnidadesDeTiempo();
      emit(UnidadDeTiempoLoaded(unidades: unidades));
    } catch (e) {
      emit(UnidadDeTiempoError(mensaje: e.toString()));
    }
  }

  Future<void> _onSeleccionarUnidad(
    SeleccionarUnidadDeTiempo event,
    Emitter<UnidadDeTiempoState> emit,
  ) async {
    if (state is UnidadDeTiempoLoaded) {
      emit(
        (state as UnidadDeTiempoLoaded).copyWith(seleccionada: event.unidad),
      );
    }
  }
}
