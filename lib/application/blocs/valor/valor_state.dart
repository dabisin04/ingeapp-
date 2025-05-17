import 'package:inge_app/domain/entities/valor.dart';

abstract class ValorState {}

class ValorInitial extends ValorState {}

class ValorLoading extends ValorState {}

class ValorLoaded extends ValorState {
  final List<Valor> valores;
  ValorLoaded(this.valores);
}

class ValorPorPeriodoLoaded extends ValorState {
  final Valor valor;
  ValorPorPeriodoLoaded(this.valor);
}

class ValorUpdated extends ValorState {
  final Valor valor;
  ValorUpdated(this.valor);
}

class ValorDeleted extends ValorState {
  final int? periodo;
  final String tipo;
  final String flujo; // Nuevo campo
  ValorDeleted(this.periodo, this.tipo, this.flujo);
}

class ValorError extends ValorState {
  final String mensaje;
  ValorError(this.mensaje);
}
