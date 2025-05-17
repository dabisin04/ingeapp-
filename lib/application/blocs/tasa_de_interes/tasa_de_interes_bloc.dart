import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_event.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_state.dart';
import 'package:inge_app/domain/repositories/tasa_de_interes_repository.dart';

class TasaInteresBloc extends Bloc<TasaInteresEvent, TasaInteresState> {
  final TasaInteresRepository repository;

  TasaInteresBloc({required this.repository}) : super(TasaInteresInitial()) {
    on<CargarTasasInteres>(_onCargarTasas);
    on<AgregarTasaInteres>(_onAgregarTasa);
    on<EditarTasaInteres>(_onEditarTasa);
    on<EliminarTasaInteres>(_onEliminarTasa);
    on<ObtenerTasaPorPeriodo>(_onObtenerTasaPorPeriodo);
  }

  Future<void> _onCargarTasas(
    CargarTasasInteres event,
    Emitter<TasaInteresState> emit,
  ) async {
    emit(TasaInteresLoading());
    try {
      final tasas = await repository.obtenerTasasInteres();
      emit(TasaInteresLoaded(tasas: tasas));
    } catch (e) {
      emit(TasaInteresError(mensaje: e.toString()));
    }
  }

  Future<void> _onAgregarTasa(
    AgregarTasaInteres event,
    Emitter<TasaInteresState> emit,
  ) async {
    print('▶️ [TasaInteresBloc] AgregarTasaInteres: ${event.tasa}');
    try {
      await repository.agregarTasaInteres(event.tasa);
      print('✅ [TasaInteresBloc] Tasa guardada: ${event.tasa}');
      add(CargarTasasInteres());
    } catch (e) {
      print('❌ [TasaInteresBloc] Error al agregar tasa: $e');
      emit(TasaInteresError(mensaje: e.toString()));
    }
  }

  Future<void> _onEditarTasa(
    EditarTasaInteres event,
    Emitter<TasaInteresState> emit,
  ) async {
    print(
      '▶️ [TasaInteresBloc] EditarTasaInteres: id=${event.id}, nueva=${event.tasaActualizada}',
    );
    try {
      await repository.editarTasaInteres(event.id, event.tasaActualizada);
      print('✅ [TasaInteresBloc] Tasa actualizada: ${event.tasaActualizada}');
      add(CargarTasasInteres());
    } catch (e) {
      print('❌ [TasaInteresBloc] Error al editar tasa: $e');
      emit(TasaInteresError(mensaje: e.toString()));
    }
  }

  Future<void> _onEliminarTasa(
    EliminarTasaInteres event,
    Emitter<TasaInteresState> emit,
  ) async {
    try {
      await repository.eliminarTasaInteres(event.id);
      add(CargarTasasInteres()); // Reload list of rates after deletion
    } catch (e) {
      emit(TasaInteresError(mensaje: e.toString()));
    }
  }

  Future<void> _onObtenerTasaPorPeriodo(
    ObtenerTasaPorPeriodo event,
    Emitter<TasaInteresState> emit,
  ) async {
    try {
      final tasa = await repository.obtenerTasaPorPeriodo(event.periodo);
      if (tasa != null) {
        emit(TasaInteresTasaPorPeriodo(tasa: tasa));
      } else {
        emit(
          TasaInteresError(
            mensaje: 'Tasa de interés no encontrada para el periodo.',
          ),
        );
      }
    } catch (e) {
      emit(TasaInteresError(mensaje: e.toString()));
    }
  }
}
