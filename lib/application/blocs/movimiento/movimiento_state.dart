import 'package:equatable/equatable.dart';
import 'package:inge_app/domain/entities/movimiento.dart';

abstract class MovimientoState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MovimientoInitial extends MovimientoState {}

class MovimientoLoading extends MovimientoState {}

class MovimientoLoaded extends MovimientoState {
  final List<Movimiento> movimientos;

  MovimientoLoaded({required this.movimientos});

  @override
  List<Object?> get props => [movimientos];
}

class MovimientoError extends MovimientoState {
  final String mensaje;

  MovimientoError({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}
