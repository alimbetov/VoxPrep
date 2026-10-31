import 'package:flutter/material.dart';

abstract final class CareerSpeakMotion {
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 180);
  static const Duration navigation = Duration(milliseconds: 220);
  static const Duration emphasized = Duration(milliseconds: 300);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;

  static bool reduceMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  static Duration duration(BuildContext context, Duration preferred) {
    return reduceMotion(context) ? instant : preferred;
  }

  static Widget routeTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Widget child,
    bool hierarchical = false,
  }) {
    if (reduceMotion(context)) return child;

    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final sign = direction == TextDirection.rtl ? -1.0 : 1.0;
    final offset = hierarchical ? 0.04 : 0.018;
    final curved = CurvedAnimation(
      parent: animation,
      curve: standardCurve,
      reverseCurve: standardCurve.flipped,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(sign * offset, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
