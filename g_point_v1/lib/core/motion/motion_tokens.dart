import 'package:flutter/animation.dart';

abstract final class MotionTokens {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 240);
  static const page = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 420);

  static const standardCurve = Curves.easeOutCubic;
  static const emphasizedCurve = Curves.easeOutQuart;
}
