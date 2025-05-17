import 'package:inge_app/domain/entities/valor.dart';

abstract class ValorEvent {}

class CargarValoresEvent extends ValorEvent {}

class AgregarValorEvent extends ValorEvent {
  final Valor valor;
  AgregarValorEvent(this.valor);
}

class EditarValorEvent extends ValorEvent {
  final Valor valorActualizado;
  EditarValorEvent(this.valorActualizado);
}

class EliminarValorEvent extends ValorEvent {
  final int? periodo;
  final String tipo;
  final String flujo;
  EliminarValorEvent(this.periodo, this.tipo, this.flujo);
}

class ObtenerValorPorPeriodoEvent extends ValorEvent {
  final int periodo;
  ObtenerValorPorPeriodoEvent(this.periodo);
}
