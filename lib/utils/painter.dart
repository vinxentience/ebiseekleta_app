import 'package:flutter/material.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> outputs;
  final Size imageSize;

  BoundingBoxPainter(this.outputs, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    for (var output in outputs) {
      final box = output['box'];
      final left = box[0];
      final top = box[1];
      final right = box[2];
      final bottom = box[3];

      // get percentage of left
      final leftPercent = left / imageSize.width;
      final topPercent = top / imageSize.height;
      final rightPercent = right / imageSize.width;
      final bottomPercent = bottom / imageSize.height;

      final rect = Rect.fromLTRB(
        leftPercent * size.width,
        topPercent * size.height,
        rightPercent * size.width,
        bottomPercent * size.height,
      );

      canvas.drawRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: output['tag'],
          style: const TextStyle(
            color: Colors.red,
            fontSize: 11.0,
            backgroundColor: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          rect.left + 1,
          rect.top + 1,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.outputs != outputs ||
        oldDelegate.outputs.isEmpty != outputs.isEmpty;
  }
}
