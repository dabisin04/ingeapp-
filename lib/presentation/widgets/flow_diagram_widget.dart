import 'package:flutter/material.dart';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';

class FlowDiagramWidget extends StatelessWidget {
  final DiagramaDeFlujo diagram;
  const FlowDiagramWidget({required this.diagram});

  @override
  Widget build(BuildContext context) {
    const double spacing = 50.0;
    final totalWidth = spacing * (diagram.cantidadDePeriodos + 1);

    return Card(
      color: Colors.grey[850],
      child: SizedBox(
        height: 350,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: totalWidth,
            padding: const EdgeInsets.all(8),
            child: CustomPaint(
              size: Size(totalWidth, 350),
              painter: _FlowPainter(diagram, spacing),
            ),
          ),
        ),
      ),
    );
  }
}

// 🔥 Función segura para formatear valores double o string:
String formatearValor(dynamic valor) {
  if (valor == null) return '';
  if (valor is double) return '\$${valor.toStringAsFixed(2)}';
  return valor.toString();
}

class _FlowPainter extends CustomPainter {
  final DiagramaDeFlujo d;
  final double spacing;
  _FlowPainter(this.d, this.spacing);

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final paintLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    final rateColors = List.generate(
      d.tasasDeInteres.length,
      (i) => HSVColor.fromAHSV(
        1,
        (i * 360.0 / d.tasasDeInteres.length) % 360,
        0.7,
        0.9,
      ).toColor(),
    );

    final focal = d.periodoFocal ?? 0;

    // 3) Movimientos
    for (final m in d.movimientos) {
      final period = m.periodo ?? focal;
      final x = period * spacing;
      final isIngreso = m.tipo == 'ingreso';
      final arrowLen = 80.0;
      final yEnd = isIngreso ? midY + arrowLen : midY - arrowLen;
      final paintMov = Paint()
        ..color = isIngreso ? Colors.greenAccent : Colors.redAccent
        ..strokeWidth = 2;

      // Si es una serie, dibujar línea horizontal
      if (m.esSerie && m.hastaPeriodo != null) {
        final endX = m.hastaPeriodo! * spacing;
        final ySerie = isIngreso ? midY + 40 : midY - 40;

        // Línea horizontal de la serie
        canvas.drawLine(Offset(x, ySerie), Offset(endX, ySerie), paintMov);

        // Líneas verticales de conexión
        canvas.drawLine(Offset(x, midY), Offset(x, ySerie), paintMov);
        canvas.drawLine(Offset(endX, midY), Offset(endX, ySerie), paintMov);

        // Flechas en los extremos
        final pathStart = Path()
          ..moveTo(x + 5, ySerie - 5)
          ..lineTo(x, ySerie)
          ..lineTo(x + 5, ySerie + 5);
        canvas.drawPath(pathStart, paintMov);

        final pathEnd = Path()
          ..moveTo(endX - 5, ySerie - 5)
          ..lineTo(endX, ySerie)
          ..lineTo(endX - 5, ySerie + 5);
        canvas.drawPath(pathEnd, paintMov);

        // Etiqueta de tipo de serie
        final tipoSerie = m.tipoSerie ?? 'vencida';
        final tp = TextPainter(
          text: TextSpan(
            text: tipoSerie[0].toUpperCase() + tipoSerie.substring(1),
            style: TextStyle(color: paintMov.color, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final lx = (x + endX) / 2 - tp.width / 2;
        tp.paint(canvas, Offset(lx, ySerie + (isIngreso ? 4 : -tp.height - 4)));
      } else {
        // Movimiento puntual normal
        canvas.drawLine(Offset(x, midY), Offset(x, yEnd), paintMov);

        final pathMov = Path()
          ..moveTo(x - 6, yEnd + (isIngreso ? -6 : 6))
          ..lineTo(x, yEnd)
          ..lineTo(x + 6, yEnd + (isIngreso ? -6 : 6));
        canvas.drawPath(pathMov, paintMov);
      }

      if (m.valor != null) {
        final valorTexto = formatearValor(m.valor);
        final tp = TextPainter(
          text: TextSpan(
            text: valorTexto,
            style: TextStyle(color: paintMov.color, fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final yLabel = isIngreso ? yEnd + 4 : yEnd - tp.height - 4;
        tp.paint(canvas, Offset(x - tp.width / 2, yLabel));
      }
    }

    // 4) Tasas de interés
    for (int i = 0; i < d.tasasDeInteres.length; i++) {
      final t = d.tasasDeInteres[i];
      final color = rateColors[i];
      final paintRate = Paint()
        ..color = color
        ..strokeWidth = 3;
      final startX = t.periodoInicio * spacing;
      final endX = t.periodoFin * spacing;
      final yRate = midY - 30 - i * 20;

      canvas.drawLine(Offset(startX, midY), Offset(startX, yRate), paintRate);
      canvas.drawLine(Offset(endX, midY), Offset(endX, yRate), paintRate);
      canvas.drawLine(Offset(startX, yRate), Offset(endX, yRate), paintRate);

      canvas.drawPath(
        Path()
          ..moveTo(endX - 5, yRate - 5)
          ..lineTo(endX, yRate)
          ..lineTo(endX - 5, yRate + 5),
        paintRate,
      );
      canvas.drawPath(
        Path()
          ..moveTo(startX + 5, yRate - 5)
          ..lineTo(startX, yRate)
          ..lineTo(startX + 5, yRate + 5),
        paintRate,
      );

      final label = '${(t.valor * 100).toStringAsFixed(2)}%';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: color, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final lx = (startX + endX) / 2 - tp.width / 2;
      tp.paint(canvas, Offset(lx, yRate - tp.height - 4));
    }

    // 5) Valores (Presente / Futuro)
    for (final v in d.valores) {
      if (v.periodo == null) continue;
      final period = v.periodo!;
      final x = period * spacing;
      final isIngreso = v.flujo == 'Ingreso';
      final arrowLen = 60.0;
      final yEnd = isIngreso ? midY + arrowLen : midY - arrowLen;
      final paintConn = Paint()
        ..color = (isIngreso ? Colors.greenAccent : Colors.redAccent)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(x, midY), Offset(x, yEnd), paintConn);

      final path = Path();
      if (isIngreso) {
        path.moveTo(x - 5, yEnd - 8);
        path.lineTo(x, yEnd);
        path.lineTo(x + 5, yEnd - 8);
      } else {
        path.moveTo(x - 5, yEnd + 8);
        path.lineTo(x, yEnd);
        path.lineTo(x + 5, yEnd + 8);
      }
      canvas.drawPath(path, paintConn);

      final letter = v.tipo == 'Presente' ? 'P' : 'F';
      final lp = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            color: paintConn.color,
            fontSize: 14,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final ly = isIngreso ? yEnd + 4 : yEnd - lp.height - 4;
      lp.paint(canvas, Offset(x + 8, ly));

      if (v.valor != null) {
        final valorTexto = formatearValor(v.valor);
        final vp = TextPainter(
          text: TextSpan(
            text: valorTexto,
            style: TextStyle(color: paintConn.color, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final vy = isIngreso ? yEnd + 4 : yEnd - vp.height - 12;
        vp.paint(canvas, Offset(x - vp.width / 2, vy));
      }
    }

    // 6) Línea base y ticks de periodos
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paintLine);
    final tickPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i <= d.cantidadDePeriodos; i++) {
      final x = i * spacing;
      canvas.drawLine(Offset(x, midY - 5), Offset(x, midY + 5), paintLine);
      tickPainter.text = TextSpan(
        text: '$i',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      );
      tickPainter.layout();
      tickPainter.paint(canvas, Offset(x - tickPainter.width / 2, midY + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
