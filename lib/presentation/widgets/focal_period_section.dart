import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_event.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_state.dart';

class FocalPeriodSection extends StatefulWidget {
  const FocalPeriodSection({Key? key}) : super(key: key);
  @override
  State<FocalPeriodSection> createState() => _FocalPeriodSectionState();
}

class _FocalPeriodSectionState extends State<FocalPeriodSection> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlowDiagramBloc, FlowDiagramState>(
      buildWhen: (prev, cur) => cur is FlowDiagramLoaded,
      builder: (context, state) {
        final int? currentFocal =
            (state is FlowDiagramLoaded) ? state.diagrama.periodoFocal : null;
        _ctrl.text = currentFocal?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Periodo Focal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Periodo Focal (opcional)',
                          hintText: 'Deja vacío para resolver n',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        final txt = _ctrl.text.trim();
                        final int? val = txt.isEmpty ? null : int.tryParse(txt);
                        context
                            .read<FlowDiagramBloc>()
                            .add(UpdateFocalPeriodEvent(val));
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Fijar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
