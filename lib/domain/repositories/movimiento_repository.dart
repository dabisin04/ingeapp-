import 'package:inge_app/domain/entities/movimiento.dart';

abstract class MovementRepository {
  Future<List<Movimiento>> getAllMovements();
  Future<void> addMovement(Movimiento movement);
  Future<void> updateMovement(Movimiento movement);
  Future<void> deleteMovement(Movimiento movement);
}
