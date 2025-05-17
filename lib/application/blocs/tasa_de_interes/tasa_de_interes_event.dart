import 'package:equatable/equatable.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';

abstract class TasaInteresEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CargarTasasInteres extends TasaInteresEvent {}

class AgregarTasaInteres extends TasaInteresEvent {
  final TasaDeInteres tasa;

  AgregarTasaInteres(this.tasa);

  @override
  List<Object?> get props => [tasa];
}

class EditarTasaInteres extends TasaInteresEvent {
  final int id;
  final TasaDeInteres tasaActualizada;

  EditarTasaInteres(this.id, this.tasaActualizada);

  @override
  List<Object?> get props => [id, tasaActualizada];
}

class EliminarTasaInteres extends TasaInteresEvent {
  final int id;

  EliminarTasaInteres(this.id);

  @override
  List<Object?> get props => [id];
}

class ObtenerTasaPorPeriodo extends TasaInteresEvent {
  final int periodo;

  ObtenerTasaPorPeriodo(this.periodo);

  @override
  List<Object?> get props => [periodo];
}
