import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpi/providers/theme_provider.dart';
//
void main() {
  late ThemeProvider provider;

  setUp(() {
    // Initialize a fresh provider before each test
    provider = ThemeProvider();
  });

  group('ThemeProvider Unit Tests', () {
    test('Initial theme mode should be dark', () {
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);
    });

    test('setThemeMode should change theme mode and notify listeners', () {
      // Create a mock listener flag
      bool listenerCalled = false;
      provider.addListener(() {
        listenerCalled = true;
      });

      // Set to light mode
      provider.setThemeMode(ThemeMode.light);

      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, isFalse);
      expect(listenerCalled, isTrue);
    });

    test('toggleTheme should switch from dark to light and notify listeners', () {
      // Ensure initial state is dark
      expect(provider.themeMode, ThemeMode.dark);

      bool listenerCalled = false;
      provider.addListener(() {
        listenerCalled = true;
      });

      // Toggle to light
      provider.toggleTheme();

      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, isFalse);
      expect(listenerCalled, isTrue);
    });

    test('toggleTheme should switch from light to dark and notify listeners', () {
      // Set initial state to light mode first
      provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);

      bool listenerCalled = false;
      provider.addListener(() {
        listenerCalled = true;
      });

      // Toggle back to dark
      provider.toggleTheme();

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);
      expect(listenerCalled, isTrue);
    });
  });
}