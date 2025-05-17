import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/infrastructure/utils/financial_analyzer.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';

class DeepSeekAssistant {
  static const _apiKey = 'sk-b0463bec7c144306ab996cab146cdfb9';
  static const _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  static Future<
      ({
        DiagramaDeFlujo diagram,
        String explanation,
        EquationAnalysis solution
      })> solveWithDescription(String description) async {
    print('🛠️ Iniciando asistente DeepSeek con descripción: $description');
    final codeFiles = await _loadCodeFiles();
    print('📚 Archivos cargados exitosamente.');
    final systemPrompt = _buildSystemPrompt(codeFiles);
    print(
        '🧠 System Prompt construido correctamente (longitud=${systemPrompt.length} caracteres).');

    final messages = [
      {
        "role": "system",
        "content": systemPrompt,
      },
      {
        "role": "user",
        "content": '''
Basándote en la siguiente descripción:

**Descripción:**
$description

**Instrucciones:**
1. Analiza el tipo de caso (VP/VF, X, n, IRR).
2. Explica paso a paso la resolución de forma clara, incluyendo:
   - Identificación del tipo de problema.
   - Definición de variables.
   - Planteamiento de la ecuación.
   - Cálculo de factores de descuento o capitalización.
   - Resolución para la incógnita.
3. Luego escribe SOLO el JSON compatible con esta clase Dart, encerrándolo entre etiquetas [JSON] y [/JSON], SIN EXPLICACIÓN EXTRA dentro de esas etiquetas. Asegúrate de que el JSON sea válido y cumpla con el formato exacto de la clase DiagramaDeFlujo:
$_diagramaDeFlujoModel

**Notas importantes:**
- Usa únicamente las unidades de tiempo válidas proporcionadas en el system prompt.
- Asegúrate de que los valores numéricos (como tasas y valores) sean números, no cadenas, a menos que representen una expresión (como "0.2*X").
- No incluyas comentarios ni explicaciones dentro del bloque [JSON][/JSON].
- Si el JSON no es válido, el proceso fallará, así que verifica que esté correctamente formado.
- **CRUCIAL**: El JSON DEBE estar encerrado entre [JSON] y [/JSON]. Si no está encerrado en estas etiquetas, la respuesta será rechazada. Por ejemplo:
  [JSON]
  {"id": 1, "nombre": "Ejemplo", "descripcion": "Descripción", "unidadDeTiempo": {"id": 4, "nombre": "Mensual", "valor": 12}, "cantidadDePeriodos": 20, "periodoFocal": 0, "tasasDeInteres": [], "movimientos": [], "valores": []}
  [/JSON]
''',
      }
    ];

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "deepseek-chat",
        "temperature": 0.2,
        "messages": messages,
      }),
    );

    if (response.statusCode == 200) {
      print('📡 Respuesta recibida de DeepSeek (status 200).');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['choices'][0]['message']['content'] as String;

      print('📥 Contenido recibido:\n$content');

      // Buscar el JSON entre [JSON] y [/JSON], ignorando whitespace y newlines
      final regex = RegExp(
        r'\[JSON\]\s*(.*?)\s*\[/JSON\]',
        dotAll: true,
        multiLine: true,
      );
      var match = regex.firstMatch(content);

      String diagramJsonRaw;

      if (match == null) {
        print(
            '⚠️ No se encontró bloque [JSON] válido, intentando buscar JSON plano...');
        // Fallback: Try to find a plain JSON object in the response
        final jsonRegex = RegExp(
          r'\{[\s\S]*\}',
          dotAll: true,
          multiLine: true,
        );
        final jsonMatch = jsonRegex.firstMatch(content);

        if (jsonMatch == null) {
          print('❌ No se encontró ningún JSON válido en la respuesta.');
          throw Exception(
              'No se encontró bloque [JSON] válido ni JSON plano en la respuesta.\nContenido recibido:\n$content');
        }

        diagramJsonRaw = jsonMatch.group(0)!.trim();
        print('🧩 JSON plano extraído:\n$diagramJsonRaw');
      } else {
        diagramJsonRaw = match.group(1)!.trim();
        print('🧩 JSON extraído (desde bloque [JSON]):\n$diagramJsonRaw');
      }

      // Validar y limpiar el JSON antes de parsearlo
      String diagramJson;
      try {
        jsonDecode(diagramJsonRaw);
        diagramJson = diagramJsonRaw;
      } catch (e) {
        print('⚠️ JSON inválido detectado, intentando limpiar...');
        diagramJson = diagramJsonRaw
            .replaceAll(RegExp(r',\s*}'), '}') // Eliminar comas finales
            .replaceAll(
                RegExp(r',\s*]'), ']') // Eliminar comas finales en arrays
            .trim();
        try {
          jsonDecode(diagramJson);
        } catch (e) {
          print('❌ Error al limpiar JSON: $e');
          throw Exception(
              'El JSON extraído no es válido.\nJSON extraído:\n$diagramJson\nError: $e');
        }
      }

      print('✅ JSON limpio:\n$diagramJson');

      // Extraer la explicación (todo el contenido excepto el JSON)
      final explanation = match != null
          ? content.replaceFirst(regex, '').trim()
          : content
              .replaceFirst(RegExp(r'\{[\s\S]*\}', dotAll: true), '')
              .trim();

      // Parsear JSON a DiagramaDeFlujo
      final diagrama = _parseDiagram(diagramJson);

      // Analizar y resolver localmente
      final solucion = FinancialAnalyzer.analyze(diagrama);

      print('✅ Análisis completo realizado.');
      print('📜 Ecuación: ${solucion.equation}');
      print('🧮 Solución: ${solucion.solution}');

      return (explanation: explanation, diagram: diagrama, solution: solucion);
    } else {
      print('❌ Error al invocar DeepSeek: ${response.body}');
      throw Exception('Error al invocar DeepSeek: ${response.body}');
    }
  }

  static Future<Map<String, String>> _loadCodeFiles() async {
    const basePath = 'lib/infrastructure/utils/';
    const files = [
      'financial_analysis.dart',
      'financial_analysis_pvfv.dart',
      'financial_analysis_single_unknown.dart',
      'financial_analysis_multiple_unknowns.dart',
      'financial_analysis_irr.dart',
      'financial_analyzer.dart',
      'financial_utils.dart',
      'irr_utils.dart',
      'rate_conversor.dart',
      'string_extensions.dart',
    ];

    final Map<String, String> contents = {};
    for (final file in files) {
      print('📂 Cargando archivo: $basePath$file');
      final path = basePath + file;
      final content = await rootBundle.loadString(path);
      contents[file] = content;
    }
    return contents;
  }

  static String _buildSystemPrompt(Map<String, String> files) {
    final buffer = StringBuffer();
    buffer.writeln('Eres un experto en ingeniería económica.');
    buffer
        .writeln('Tu tarea es analizar descripciones financieras y producir:');
    buffer.writeln('1. Una explicación clara del procedimiento paso a paso.');
    buffer.writeln(
        '2. Un objeto DiagramaDeFlujo en formato JSON limpio y válido, encerrado entre [JSON] y [/JSON].');
    buffer.writeln('Reglas estrictas para el JSON:');
    buffer.writeln(
        '- No incluyas comentarios ni explicaciones dentro del bloque [JSON][/JSON].');
    buffer.writeln(
        '- Asegúrate de que los valores numéricos (como tasas y montos) sean números, no cadenas, a menos que representen una expresión (como "0.2*X").');
    buffer.writeln(
        '- Verifica que el JSON sea sintácticamente correcto antes de incluirlo.');

    buffer
        .writeln('\n🧩 IMPORTANTE: Usa sólo estas unidades de tiempo válidas:');
    buffer.writeln('[');
    buffer.writeln('  { "id": 1, "nombre": "Diaria", "valor": 360 },');
    buffer.writeln('  { "id": 2, "nombre": "Semanal", "valor": 48 },');
    buffer.writeln('  { "id": 3, "nombre": "Quincenal", "valor": 24 },');
    buffer.writeln('  { "id": 4, "nombre": "Mensual", "valor": 12 },');
    buffer.writeln('  { "id": 5, "nombre": "Bimestral", "valor": 6 },');
    buffer.writeln('  { "id": 6, "nombre": "Trimestral", "valor": 4 },');
    buffer.writeln('  { "id": 7, "nombre": "Cuatrimestral", "valor": 3 },');
    buffer.writeln('  { "id": 8, "nombre": "Semestral", "valor": 2 },');
    buffer.writeln('  { "id": 9, "nombre": "Anual", "valor": 1 }');
    buffer.writeln(']');

    buffer.writeln('\n🔒 Cualquier unidad fuera de esta lista será inválida.');

    files.forEach((name, content) {
      buffer.writeln('\n--- Archivo: $name ---\n```\n$content\n```');
    });

    return buffer.toString();
  }

  static DiagramaDeFlujo _parseDiagram(String diagramJson) {
    try {
      final map = jsonDecode(diagramJson) as Map<String, dynamic>;
      final diagrama = DiagramaDeFlujo(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
        descripcion: map['descripcion'] as String?,
        unidadDeTiempo: UnidadDeTiempo.fromMap(map['unidadDeTiempo']),
        cantidadDePeriodos: map['cantidadDePeriodos'] as int,
        periodoFocal: map['periodoFocal'] as int?,
        tasasDeInteres: (map['tasasDeInteres'] as List)
            .map((e) => TasaDeInteres.fromMap(e))
            .toList(),
        movimientos: (map['movimientos'] as List)
            .map((e) => Movimiento.fromMap(e))
            .toList(),
        valores: (map['valores'] as List).map((e) => Valor.fromMap(e)).toList(),
      );

      print('✅ DiagramaDeFlujo parseado correctamente.');
      print('Movimientos:');
      for (var m in diagrama.movimientos) {
        print('  - valor: ${m.valor} (type: ${m.valor.runtimeType})');
      }
      print('Valores:');
      for (var v in diagrama.valores) {
        print('  - valor: ${v.valor} (type: ${v.valor.runtimeType})');
      }

      return diagrama;
    } catch (e) {
      print('❌ Error parseando el DiagramaDeFlujo: $e');
      print('JSON problemático:\n$diagramJson');
      throw Exception('Error parseando el DiagramaDeFlujo: $e');
    }
  }

  static const String _diagramaDeFlujoModel = '''
DiagramaDeFlujo {
  id: int,
  nombre: String,
  descripcion: String?,
  unidadDeTiempo: UnidadDeTiempo { id: int, nombre: String, valor: int },
  cantidadDePeriodos: int,
  periodoFocal: int?,
  tasasDeInteres: List<TasaDeInteres> {
    id: int,
    valor: double,
    periodicidad: UnidadDeTiempo,
    capitalizacion: UnidadDeTiempo,
    tipo: String,
    periodoInicio: int,
    periodoFin: int,
    aplicaA: String,
  },
  movimientos: List<Movimiento> {
    id: int,
    tipo: String,
    periodo: int?,
    valor: double | String,
  },
  valores: List<Valor> {
    id: int,
    tipo: String,
    flujo: String,
    periodo: int?,
    valor: double | String,
  }
}
''';
}
