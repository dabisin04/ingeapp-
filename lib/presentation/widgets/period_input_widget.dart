import 'package:flutter/material.dart';

class PeriodInputWidget extends StatefulWidget {
  final void Function(int periods) onSubmit;
  PeriodInputWidget({required this.onSubmit});

  @override
  _PeriodInputWidgetState createState() => _PeriodInputWidgetState();
}

class _PeriodInputWidgetState extends State<PeriodInputWidget> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Cantidad de periodos',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                final p = int.tryParse(_controller.text);
                if (p != null && p > 0) {
                  widget.onSubmit(p);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ingrese un número válido')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
