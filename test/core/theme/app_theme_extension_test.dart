import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppThemeExtension', () {
    test('dark theme exposes semantic tokens', () {
      final theme = AppTheme.darkTheme;
      final tokens = theme.extension<AppThemeExtension>();

      expect(tokens, isNotNull);
      expect(tokens!.surfaceBase, isNot(equals(tokens.surfaceRaised)));
      expect(tokens.textPrimary.opacity, greaterThan(0.9));
      expect(tokens.statusError, isA<Color>());
      expect(tokens.ctaPrimary, isA<Color>());
    });

    test('lerp keeps semantic fields available', () {
      final lerped = AppThemeExtension.light.lerp(AppThemeExtension.dark, 0.5)
          as AppThemeExtension;
      expect(lerped.surfaceBase, isA<Color>());
      expect(lerped.statusInfo, isA<Color>());
      expect(lerped.densityCompact, greaterThan(0));
    });
  });
}
