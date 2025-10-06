


import 'package:flutter/material.dart';
import 'package:kpi/providers/kanban_provider.dart';
import 'package:kpi/providers/theme_provider.dart';
import 'package:kpi/screen/kanban_board_screen.dart';
import 'package:kpi/services/api_service.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(

      providers: [
        /// Theme Provider
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        /// KanbanProvider
        ChangeNotifierProvider(
          create: (_) => KanbanProvider(
            api: ApiService(token: '5c3964b8e3ee4755f2cc0febb851e2f8'),
          )..fetchTasks(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Kanban',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
              useMaterial3: true,
              // Настройки режима светлой темы
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
              useMaterial3: true,
              // Настройки режима тёмной темы
              cardTheme: CardTheme(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              colorScheme: ColorScheme.dark(
                primary: Colors.black45,
                secondary: Colors.green.shade300,
               // background: const Color(0xFF121212),
                surface: const Color(0xFF1E1E1E),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const KanbanBoardScreen(),
          );
        },
      ),
    );
  }
}




