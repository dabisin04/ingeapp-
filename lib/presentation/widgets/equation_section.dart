import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_event.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_state.dart';
import 'package:inge_app/infrastructure/utils/financial_analyzer.dart';

class AnalysisSection extends StatelessWidget {
  const AnalysisSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlowDiagramBloc, FlowDiagramState>(
      builder: (context, state) {
        String? branch;
        if (state is FlowDiagramLoaded) {
          branch = FinancialAnalyzer.branch(state.diagrama);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (branch != null) ...[
              Text('Rama a usar: $branch',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
            ],

            /// pedimos el análisis al BLoC
            ElevatedButton(
              onPressed: () =>
                  context.read<FlowDiagramBloc>().add(AnalyzeDiagramEvent()),
              child: const Text('Analizar Proceso'),
            ),
            const SizedBox(height: 12),

            if (state is AnalysisInProgress)
              const Center(child: CircularProgressIndicator()),

            if (state is AnalysisFailure)
              Text('Error: ${state.error}',
                  style: const TextStyle(color: Colors.red)),

            if (state is AnalysisSuccess) ...[
              // Ecuación de valor
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  children: [
                    Math.tex(
                      state.analysis.equation,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Resultado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Builder(
                  builder: (_) {
                    final eq = state.analysis.equation;
                    final isN = eq.contains('^n');
                    return Text(
                      isN
                          ? 'Solución: n = ${state.analysis.solution.toStringAsFixed(2)} periodos'
                          : (state.analysis.equation.contains('(1+i)')
                              ? 'Solución: i = ${(state.analysis.solution * 100).toStringAsFixed(4)}%'
                              : 'Solución: X = \$${state.analysis.solution.toStringAsFixed(2)}'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
