import 'package:equatable/equatable.dart';
import 'package:inge_app/domain/entities/movimiento.dart';

abstract class MovimientoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CargarMovimientos extends MovimientoEvent {}

class AgregarMovimiento extends MovimientoEvent {
  final Movimiento movimiento;

  AgregarMovimiento(this.movimiento);

  @override
  List<Object?> get props => [movimiento];
}

class EditarMovimiento extends MovimientoEvent {
  final Movimiento movimiento;

  EditarMovimiento(this.movimiento);

  @override
  List<Object?> get props => [movimiento];
}

class EliminarMovimiento extends MovimientoEvent {
  final Movimiento movimiento;

  EliminarMovimiento(this.movimiento);

  @override
  List<Object?> get props => [movimiento];
}
