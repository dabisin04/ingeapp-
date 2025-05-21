import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
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
  String _displayedExplanation = '';
  int _currentCharIndex = 0;
  Timer? _typingTimer;
  DiagramaDeFlujo? _diagram;
  EquationAnalysis? _solution;
  bool _loading = true;
  String? _error;
  String? _rawResponse;
  StreamSubscription? _subscription;

  String _cleanExplanation(String? text) {
    if (text == null) return '';

    // Extraer y formatear fórmulas matemáticas
    final formulaPattern = RegExp(r'\$\$\$(.*?)\$\$\$');
    String cleaned = text;

    // Reemplazar fórmulas con marcadores temporales
    final formulas = <String>[];
    cleaned = cleaned.replaceAllMapped(formulaPattern, (match) {
      formulas.add(match.group(1)!);
      return '{{FORMULA_${formulas.length - 1}}}';
    });

    // Limpiar el resto del texto
    cleaned = cleaned
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'\*'), '')
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'^- ', multiLine: true), '• ')
        .replaceAll(RegExp(r'\\frac'), 'fracción')
        .replaceAll(RegExp(r'\\\\'), '\n')
        .replaceAll(RegExp(r'\\\['), '')
        .replaceAll(RegExp(r'\\\]'), '')
        .replaceAll(RegExp(r'\\\('), '')
        .replaceAll(RegExp(r'\\\)'), '');

    // Convertir títulos a mayúsculas
    cleaned = cleaned.replaceAllMapped(
      RegExp(
          r'^(Análisis y Resolución:|Identificación del tipo de problema:|Definición de variables:|Planteamiento de la ecuación:|Resolución para la incógnita:|Diagrama de Flujo en JSON:)',
          caseSensitive: false,
          multiLine: true),
      (match) => '\n${match[0]!.toUpperCase()}\n',
    );

    // Restaurar fórmulas con formato mejorado
    for (var i = 0; i < formulas.length; i++) {
      cleaned = cleaned.replaceAll(
        '{{FORMULA_$i}}',
        '\n\$\$\$\n${formulas[i]}\n\$\$\$\n',
      );
    }

    return cleaned;
  }

  void _startTypingEffect(String fullText) {
    _typingTimer?.cancel();
    setState(() {
      _displayedExplanation = '';
      _currentCharIndex = 0;
    });

    _typingTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (_currentCharIndex < fullText.length) {
        setState(() {
          _displayedExplanation += fullText[_currentCharIndex];
          _currentCharIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAssistantResponse();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAssistantResponse() async {
    setState(() {
      _loading = true;
      _error = null;
      _rawResponse = null;
      _explanation = null;
      _diagram = null;
      _solution = null;
    });

    _subscription?.cancel();
    _subscription =
        DeepSeekAssistant.solveWithDescription(widget.description).listen(
      (result) {
        print('\n=== RESPUESTA DEL ASISTENTE ===');
        if (result.diagram != null) {
          print('Diagrama en JSON:');
          print(const JsonEncoder.withIndent('  ')
              .convert(result.diagram!.toMap()));
        }
        if (result.solution != null) {
          print('\nSolución:');
          print('Ecuación: ${result.solution!.equation}');
          print('Pasos:');
          for (final step in result.solution!.steps) {
            print('  • $step');
          }
          print('Resultado: ${result.solution!.solution}');
        }
        print('===============================\n');

        setState(() {
          _explanation = result.explanation;
          _diagram = result.diagram;
          _solution = result.solution;
          _error = result.error;
          _rawResponse = result.rawResponse;
          _loading = false;
        });
        if (result.explanation != null) {
          _startTypingEffect(_cleanExplanation(result.explanation));
        }
      },
      onError: (error) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      },
    );
  }

  Widget _buildFormulaDisplay(String formula) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fórmula:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formula,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'monospace',
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationText(String text) {
    final parts = text.split(RegExp(r'\$\$\$'));
    final widgets = <Widget>[];

    for (var i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // Texto normal
        widgets.add(Text(
          parts[i],
          style: const TextStyle(fontSize: 14),
        ));
      } else {
        // Fórmula
        widgets.add(_buildFormulaDisplay(parts[i]));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            _explanation ?? 'Procesando...',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
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
                              if (_rawResponse != null) ...[
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
                                    color: Colors.grey[100],
                                  ),
                                  child: SelectableText(
                                    _rawResponse!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
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
                              _buildExplanationText(_displayedExplanation),
                              const SizedBox(height: 16),
                              if (_diagram != null) ...[
                                const Text(
                                  '📈 Diagrama generado:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FlowDiagramWidget(diagram: _diagram!),
                              ],
                              const SizedBox(height: 16),
                              if (_solution != null) ...[
                                const Text(
                                  '🧮 Resolución técnica:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            style:
                                                const TextStyle(fontSize: 14),
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
                                ),
                              ],
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
