import 'package:equatable/equatable.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

abstract class UnidadDeTiempoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CargarUnidadesDeTiempo extends UnidadDeTiempoEvent {}

class SeleccionarUnidadDeTiempo extends UnidadDeTiempoEvent {
  final UnidadDeTiempo unidad;

  SeleccionarUnidadDeTiempo({required this.unidad});
}
