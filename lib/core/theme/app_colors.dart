import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0A3D8F);
  static const Color primaryDark = Color(0xFF07275C);
  static const Color primaryLight = Color(0xFF1453B8);
  static const Color secondary = Color(0xFF1FAE6B);
  static const Color accentGreen = Color(0xFF1FAE6B);
  static const Color accentGold = Color(0xFFF3B23D);

  static const Color lightBackground = Color(0xFFF7F8FC);
  static const Color darkBackground = Color(0xFF07111F);
  static const Color lightText = Colors.black;
  static const Color darkText = Colors.white;
  static const Color mutedLight = Color(0xFF4A4A4A);
  static const Color mutedDark = Color(0xFFB8C0D4);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF122033);
  static const Color borderLight = Color(0xFFD7DCE8);
  static const Color borderDark = Color(0xFF2A3654);
  static const Color cardBorder = Color(0xFFD7DCE8);

  static const BorderSide cardBorderSide = BorderSide(color: cardBorder, width: 1.2);
  static const Color success = Color(0xFF1FAE6B);
  static const Color error = Color(0xFFE1483F);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primary],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryDark, primary],
  );

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color text(BuildContext context) =>
      isDark(context) ? darkText : lightText;

  static Color muted(BuildContext context) =>
      isDark(context) ? mutedDark : mutedLight;

  static Color card(BuildContext context) =>
      isDark(context) ? cardDark : cardLight;

  static Color page(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color border(BuildContext context) =>
      isDark(context) ? borderDark : borderLight;

  static Color onPrimary(BuildContext context) => Colors.white;

  /// Primary brand color for icons on light surfaces (tiles, cards, fields).
  static Color brandIcon(BuildContext context) => primary;

  /// Icons on hero / app bar / drawer gradient.
  static const Color brandIconOnHero = Colors.white;

  static Color brandIconMuted(BuildContext context) =>
      primary.withValues(alpha: 0.35);
}

class AppRadii {
  AppRadii._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double pill = 100;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppShadows {
  AppShadows._();
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}
