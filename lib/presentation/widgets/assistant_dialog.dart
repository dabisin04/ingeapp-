import 'package:flutter/material.dart';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/infrastructure/services/deepseek_assistant.dart';
import 'package:inge_app/presentation/widgets/flow_diagram_widget.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';

class AssistantDialog extends StatefulWidget {
  final String description;
  const AssistantDialog({super.key, required this.description});

  @override
  State<AssistantDialog> createState() => _AssistantDialogState();
}

class _AssistantDialogState extends State<AssistantDialog> {
  String? _explanation;
  DiagramaDeFlujo? _diagram;
  EquationAnalysis? _solution;
  bool _loading = true;
  String? _error;
  String? _rawResponse;

  @override
  void initState() {
    super.initState();
    _fetchAssistantResponse();
  }

  Future<void> _fetchAssistantResponse() async {
    setState(() {
      _loading = true;
      _error = null;
      _rawResponse = null;
    });
    try {
      final result =
          await DeepSeekAssistant.solveWithDescription(widget.description);
      setState(() {
        _explanation = result.explanation;
        _diagram = result.diagram;
        _solution = result.solution;
        _loading = false;
      });
    } catch (e) {
      print('❌ Raw error response: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
        // Extract raw response if available, otherwise use the full error message
        if (e.toString().contains('Contenido recibido:')) {
          final regex = RegExp(r'Contenido recibido:\n(.*)', dotAll: true);
          final match = regex.firstMatch(e.toString());
          _rawResponse = match?.group(1) ?? e.toString();
        } else {
          _rawResponse = e.toString();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.90,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Asistente de Resolución',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '❌ Error al procesar la solicitud:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '📥 Respuesta cruda recibida:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _rawResponse ??
                                      'No hay respuesta disponible.',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.center,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reintentar'),
                                  onPressed: _fetchAssistantResponse,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🧠 Explicación:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _explanation ??
                                    'No hay explicación disponible.',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '📈 Diagrama generado:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _diagram != null
                                  ? FlowDiagramWidget(diagram: _diagram!)
                                  : const Text(
                                      'No se pudo generar el diagrama.',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                              const SizedBox(height: 16),
                              const Text(
                                '🧮 Resolución técnica:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _solution != null
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ecuación planteada:\n${_solution!.equation}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Pasos:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (_solution!.steps.isNotEmpty)
                                          ..._solution!.steps.map(
                                            (s) => Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                                bottom: 4,
                                              ),
                                              child: Text(
                                                '• $s',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ),
                                          )
                                        else
                                          const Text(
                                            'No se proporcionaron pasos.',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Resultado: ${_solution!.solution.toStringAsFixed(6)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'No se pudo calcular la solución.',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
