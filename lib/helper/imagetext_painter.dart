// Custom Painter for drawing the image
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ImageTextPainter extends CustomPainter {
  final ui.Image? image;

  ImageTextPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      // Calculate the offset to center the image within the given size
      final double scale = size.width / image!.width;
      final double scaledHeight = image!.height * scale;
      final Offset offset = Offset(
        (size.width - image!.width * scale) / 2,
        (size.height - scaledHeight) / 2,
      );
      canvas.scale(scale);
      canvas.drawImage(image!, offset, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
