import 'package:flutter/material.dart';

/// Renders canonical English learner content with LTR direction even when the
/// surrounding application chrome is RTL.
class CareerSpeakLearningText extends StatelessWidget {
  const CareerSpeakLearningText(
    this.data, {
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    super.key,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        data,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}
