import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Two gentle pulses only. No flashing; respects system reduced motion.
class GentleAttention extends StatelessWidget {
  final Widget child;
  final bool enabled;
  const GentleAttention({super.key, required this.child, this.enabled = true});
  @override
  Widget build(BuildContext context) {
    if (!enabled || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2600),
      builder: (_, value, child) => Transform.scale(
        scale: 1 + 0.018 * math.sin(value * math.pi * 4),
        child: child,
      ),
      child: child,
    );
  }
}
