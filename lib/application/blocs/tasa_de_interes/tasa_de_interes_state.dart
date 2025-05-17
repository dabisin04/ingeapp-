import 'package:equatable/equatable.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';

abstract class TasaInteresState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TasaInteresInitial extends TasaInteresState {}

class TasaInteresLoading extends TasaInteresState {}

class TasaInteresLoaded extends TasaInteresState {
  final List<TasaDeInteres> tasas;

  TasaInteresLoaded({required this.tasas});

  @override
  List<Object?> get props => [tasas];
}

class TasaInteresError extends TasaInteresState {
  final String mensaje;

  TasaInteresError({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}

class TasaInteresTasaPorPeriodo extends TasaInteresState {
  final TasaDeInteres tasa;

  TasaInteresTasaPorPeriodo({required this.tasa});

  @override
  List<Object?> get props => [tasa];
}
