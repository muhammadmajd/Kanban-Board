import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class KAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KAppBar({
    super.key, required this.title,
  });
final String title;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Text(
            title,
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : Theme.of(context).colorScheme.onPrimary,
            ),
          );
        },
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 0,
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
              tooltip: themeProvider.isDarkMode
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
            );
          },
        ),
      ],
    );
  }
}