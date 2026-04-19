import 'package:flutter/material.dart';

class BackgroundOrb extends StatelessWidget {
  const BackgroundOrb({
    super.key,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.color,
  });

  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.55,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  color.withOpacity(0.55),
                  color.withOpacity(0.18),
                  Colors.transparent,
                ],
                stops: const <double>[0.0, 0.42, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}