import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/repositories/movimiento_repository.dart';

class MovementAdapter implements MovementRepository {
  final List<Movimiento> _movements = [];

  @override
  Future<List<Movimiento>> getAllMovements() async {
    return _movements;
  }

  @override
  Future<void> addMovement(Movimiento movement) async {
    _movements.add(movement);
  }

  @override
  Future<void> updateMovement(Movimiento movement) async {
    final index = _movements.indexWhere((m) => m.id == movement.id);
    if (index != -1) {
      _movements[index] = movement;
    } else {
      throw Exception('Movimiento con ID ${movement.id} no encontrado');
    }
  }

  @override
  Future<void> deleteMovement(Movimiento movement) async {
    _movements.removeWhere((m) => m.id == movement.id);
  }
}
