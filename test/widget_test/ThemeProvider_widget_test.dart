import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';




class ThemeProvider with ChangeNotifier {
  // Режим по умолчанию
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}


// =========================================================================
//  WIDGET TEST SETUP (ThemeTestWidget)
//
// This is a dummy widget used to prove the provider notifies widgets correctly.
// =========================================================================

class ThemeTestWidget extends StatelessWidget {
  const ThemeTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider to rebuild when themeMode changes
    final themeProvider = context.watch<ThemeProvider>();

    // Get the current background color based on the theme
    final color = themeProvider.isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: color,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the current theme status
            Text(
              themeProvider.isDarkMode ? 'Dark Mode Active' : 'Light Mode Active',
              key: const Key('theme_status'),
              style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
            ),

            // Button to trigger the toggleTheme action
            ElevatedButton(
              key: const Key('theme_toggle_button'),
              onPressed: themeProvider.toggleTheme,
              child: const Text('Toggle Theme'),
            ),
          ],
        ),
      ),
    );
  }
}


// =========================================================================
//  THE ACTUAL TESTS
// =========================================================================

void main() {
  late ThemeProvider provider;

  setUp(() {
    // Initialize a fresh provider before each test
    provider = ThemeProvider();
  });

  // -----------------------------------------------------------------------
  // UNIT TESTS: Testing the internal logic of ThemeProvider
  // -----------------------------------------------------------------------

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
  });

  // -----------------------------------------------------------------------
  // WIDGET TESTS: Testing how widgets react to ThemeProvider changes
  // -----------------------------------------------------------------------

  group('ThemeProvider Widget Test', () {
    testWidgets('Widget should react to theme toggle', (WidgetTester tester) async {
      final provider = ThemeProvider();

      // 1. Wrap the test widget with the ChangeNotifierProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ThemeTestWidget(),
          ),
        ),
      );

      // --- Initial State Verification (Dark Mode) ---

      final statusFinder = find.byKey(const Key('theme_status'));
      final toggleButtonFinder = find.byKey(const Key('theme_toggle_button'));

      // Initial state should show 'Dark Mode Active'
      expect(statusFinder, findsOneWidget);
      expect(find.text('Dark Mode Active'), findsOneWidget);

      // --- Toggle to Light Mode ---

      // Find and tap the toggle button
      await tester.tap(toggleButtonFinder);

      // Rebuild the widget tree
      await tester.pump();

      // New state should be Light Mode
      expect(provider.isDarkMode, isFalse);
      expect(find.text('Light Mode Active'), findsOneWidget);
      expect(find.text('Dark Mode Active'), findsNothing); // Ensure old text is gone

      // --- Toggle back to Dark Mode ---

      // Find and tap the toggle button again
      await tester.tap(toggleButtonFinder);

      // Rebuild the widget tree
      await tester.pump();

      // New state should be Dark Mode again
      expect(provider.isDarkMode, isTrue);
      expect(find.text('Dark Mode Active'), findsOneWidget);
      expect(find.text('Light Mode Active'), findsNothing);
    });
  });
}