import 'package:flutter/material.dart';

class LogoText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const LogoText({
    required this.text,
    required this.style,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback:
          (bounds) => gradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
      child: Text(
        text,
        style: style.copyWith(
          color: Colors.white,
        ), // color must be set to enable shader
        textAlign: TextAlign.center,
      ),
    );
  }
}
