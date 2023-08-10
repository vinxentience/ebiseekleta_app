import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

bool isPlayed = false;

class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> outputs;
  final Size imageSize;

  BoundingBoxPainter(this.outputs, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    AudioPlayer? player = AudioPlayer();
    String scale;
    double scaleDb;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white;

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

      //get Scale
      double bbW = right - left;
      double bbH = bottom - top;
      scaleDb = (getObjectScale(bbW, bbH, imageSize.width, imageSize.height));
      scale = scaleDb.toStringAsFixed(3);
      canvas.drawRect(rect, paint);

      //alert
      void _play() {
        player.play(AssetSource('danger.mp3'));
        player.setVolume(1);

        player.stop();
      }

      if (scaleDb < 0.6) {
        if (!isPlayed) {
          _play();
          isPlayed = true;
        }
      } else {
        player.stop();
        isPlayed = false;
      }

      final textPainter = TextPainter(
        text: scaleDb < 0.6
            ? TextSpan(
                text: "detected: ${output['tag']} | scale: $scale",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11.0,
                  backgroundColor: Colors.white,
                ),
              )
            : TextSpan(
                text:
                    "detected: ${output['tag']} | scale: $scale (WARNING TOO CLOSE)",
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
          rect.left + 2,
          rect.top + 2,
        ),
      );
    }
  }

  double getObjectScale(bbW, bbH, oW, oH) {
    double scaleWidth = bbW / oW;
    double scaleHeight = bbH / oH;
    return (scaleWidth + scaleHeight) / 2;
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.outputs != outputs ||
        oldDelegate.outputs.isEmpty != outputs.isEmpty;
  }
}
