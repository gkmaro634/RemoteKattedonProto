import 'package:flutter/material.dart';

Rect calcGengeRect({
  required Size canvasSize,
  required double imageWidth,
  required double imageHeight,
  required int shakingFrames,
}) {
  const baseWidth = 400.0;

  final aspectRatio = imageHeight / imageWidth;
  final baseHeight = baseWidth * aspectRatio;

  final shakeAmount = shakingFrames;
  final scale = 1 + shakeAmount * 0.02;
  final drawWidth = baseWidth * scale; //+ (shakeAmount * 8);
  final drawHeight = baseHeight * scale; // - (shakeAmount * 4);

  return Rect.fromCenter(
    center: Offset(
      canvasSize.width / 2,
      canvasSize.height / 2,
    ),
    width: drawWidth,
    height: drawHeight,
  );
}
