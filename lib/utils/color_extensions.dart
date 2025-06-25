import 'package:flutter/material.dart';

/// Extensions for the Color class to enhance functionality
extension ColorExtensions on Color {
  /// Creates a new color with the specified alpha, or the current alpha if not provided
  Color withValues({int? alpha, int? red, int? green, int? blue}) {
    return Color.fromARGB(
      alpha ?? a.toInt(),
      red ?? r.toInt(),
      green ?? g.toInt(),
      blue ?? b.toInt(),
    );
  }

  /// Create a lighter version of this color
  Color lighter([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    
    return hslLight.toColor();
  }

  /// Create a darker version of this color
  Color darker([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    
    return hslDark.toColor();
  }
  
  /// Returns whether the color is light or dark
  bool get isLight => computeLuminance() > 0.5;
}
