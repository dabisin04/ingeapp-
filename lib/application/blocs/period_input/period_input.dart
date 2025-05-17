import 'package:flutter_bloc/flutter_bloc.dart';

class PeriodInputCubit extends Cubit<int> {
  PeriodInputCubit() : super(0);
  void update(int periods) => emit(periods);
}
