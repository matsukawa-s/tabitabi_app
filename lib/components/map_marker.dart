import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> getBytesFromCanvas(int width, int height, int order) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()..color = Colors.orange;
  final Radius radius = Radius.circular(0.0);
  canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble()),
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      ),
      paint);
  TextPainter Painter = TextPainter(textDirection: TextDirection.ltr);

  Painter.text = TextSpan(
    text: order.toString(),
    style: TextStyle(fontSize: 40.0, color: Colors.white),
  );
  Painter.layout();
  Painter.paint(canvas, Offset((width * 0.5) - Painter.width * 0.5, (height * 0.5) - Painter.height * 0.5));
  final img = await pictureRecorder.endRecording().toImage(width, height);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data.buffer.asUint8List();
}