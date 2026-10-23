// GENERATED FROM AGENTS.md v2.0 - DO NOT EDIT BY HAND
// Source of truth: <SKILLS>\AGENTS.md section 3
// Token log:      <SKILLS>\design\tokens-log.md
import 'package:flutter/widgets.dart';

/// The only six colors allowed in a Ti app.
class TiColors {
  const TiColors._();
  static const ink     = Color(0xFF14161C);
  static const paper   = Color(0xFFFAFAF7);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF2F6BFF);
  static const muted   = Color(0xFF8B90A0);
  static const line    = Color(0xFFE7E9EE);

  /// Dark-mode overrides.
  static const inkDark     = Color(0xFFF2F3F7);
  static const paperDark   = Color(0xFF0F1115);
  static const surfaceDark = Color(0xFF171A21);
  static const primaryDark = Color(0xFF5B87FF);
  static const lineDark    = Color(0xFF2A2E38);

  /// Only for destructive confirm buttons and field validation text.
  static const danger = Color(0xFFC8433C);
}

class TiRadius {
  const TiRadius._();
  static const double all = 16;
  static const double pill = 999;
}

class TiSpace {
  const TiSpace._();
  static const double page = 20;
  static const double card = 16;
  static const double block = 24;
  static const double gap = 8;
  static const double tapTarget = 44;
  static const double listRow = 56;
  static const double listRowTwoLine = 72;
}

class TiDuration {
  const TiDuration._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration page = Duration(milliseconds: 260);
  static const Duration max = Duration(milliseconds: 300); // hard ceiling
}

class TiShadows {
  const TiShadows._();
  static const card = [
    BoxShadow(color: Color(0x0F14161C), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const overlay = [
    BoxShadow(color: Color(0x1414161C), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

class TiType {
  const TiType._();
  static const family = 'Inter';
  static const double small = 12;
  static const double caption = 13;
  static const double body = 15;
  static const double title = 17;
  static const double headline = 22;
  static const double display = 28;
  static const double lineHeightBody = 1.5;
  static const double lineHeightTitle = 1.25;
}