import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_event.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_state.dart';
import 'package:inge_app/presentation/widgets/assistant_dialog.dart';

class DescriptionSection extends StatefulWidget {
  const DescriptionSection({super.key});

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  final _controller = TextEditingController();
  bool _descriptionSaved = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<FlowDiagramBloc>().add(UpdateDescriptionEvent(text));
    setState(() {
      _descriptionSaved = true;
    });
    _controller.clear();
  }

  void _openAssistantDialog() {
    final state = context.read<FlowDiagramBloc>().state;
    if (state is FlowDiagramLoaded) {
      final currentDesc = state.diagrama.descripcion ?? '';

      if (currentDesc.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Primero debes escribir una descripción.')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AssistantDialog(description: currentDesc),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay diagrama cargado aún.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Descripción del Diagrama',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Escribe la descripción aquí...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: const Text('Aceptar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openAssistantDialog,
                    icon: const Icon(Icons.smart_toy),
                    label: const Text('Resolver con Asistente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_descriptionSaved)
              BlocBuilder<FlowDiagramBloc, FlowDiagramState>(
                buildWhen: (previous, current) => current is FlowDiagramLoaded,
                builder: (context, state) {
                  final currentDesc = state is FlowDiagramLoaded
                      ? state.diagrama.descripcion ?? ''
                      : '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Descripción guardada:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(minHeight: 60),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentDesc.isNotEmpty
                              ? currentDesc
                              : 'Aún no hay descripción.',
                          style: TextStyle(
                            fontStyle: currentDesc.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: currentDesc.isEmpty
                                ? Colors.grey[500]
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
