import 'package:equatable/equatable.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

abstract class UnidadDeTiempoState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UnidadDeTiempoInitial extends UnidadDeTiempoState {}

class UnidadDeTiempoLoading extends UnidadDeTiempoState {}

class UnidadDeTiempoLoaded extends UnidadDeTiempoState {
  final List<UnidadDeTiempo> unidades;
  final UnidadDeTiempo? seleccionada;

  UnidadDeTiempoLoaded({required this.unidades, this.seleccionada});

  UnidadDeTiempoLoaded copyWith({
    List<UnidadDeTiempo>? unidades,
    UnidadDeTiempo? seleccionada,
  }) {
    return UnidadDeTiempoLoaded(
      unidades: unidades ?? this.unidades,
      seleccionada: seleccionada ?? this.seleccionada,
    );
  }

  @override
  List<Object?> get props => [unidades, seleccionada];
}

class UnidadDeTiempoError extends UnidadDeTiempoState {
  final String mensaje;

  UnidadDeTiempoError({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}
