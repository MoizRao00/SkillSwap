// lib/widgets/animations/slide_animation.dart

import 'package:flutter/material.dart';

enum SlideDirection { fromTop, fromBottom, fromLeft, fromRight }

class SlideAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final SlideDirection direction;

  const SlideAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.direction = SlideDirection.fromBottom,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        double dx = 0.0;
        double dy = 0.0;

        switch (direction) {
          case SlideDirection.fromTop:
            dy = -value * 100;
            break;
          case SlideDirection.fromBottom:
            dy = value * 100;
            break;
          case SlideDirection.fromLeft:
            dx = -value * 100;
            break;
          case SlideDirection.fromRight:
            dx = value * 100;
            break;
        }

        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
      child: child,
    );
  }
}