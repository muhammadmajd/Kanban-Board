import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpi/models/task_model.dart';
import 'package:kpi/providers/kanban_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../unit_test/services/api_service_test.mocks.dart';


// Helper for initial mock data
List<TaskModel> createInitialTasks() {
  return [
    TaskModel(indicatorToMoId: 1, parentId: 10, name: 'T1', order: 1),
    TaskModel(indicatorToMoId: 2, parentId: 20, name: 'T2', order: 2),
    TaskModel(indicatorToMoId: 3, parentId: 10, name: 'T3', order: 3),
    TaskModel(indicatorToMoId: 4, parentId: 30, name: 'T4', order: 1),
    TaskModel(indicatorToMoId: 5, parentId: 20, name: 'T5', order: 1),
  ];
}


void main() {
  late MockApiService mockApi;
  late KanbanProvider provider;

  setUp(() {
    mockApi = MockApiService();
    // Initialize provider with the mock API
    provider = KanbanProvider(api: mockApi);

    // Set up a consistent initial state for internal tests
    provider.tasks.addAll(createInitialTasks());
  });



  group('KanbanProvider Widget Integration Test', () {
    testWidgets('Widget should show loading state during fetch', (WidgetTester tester) async {
      // Stub the API to delay response (simulating a long network call)
      when(mockApi.fetchTasks(
        periodStart: anyNamed('periodStart'),
        periodEnd: anyNamed('periodEnd'),
        periodKey: anyNamed('periodKey'),
        requestedMoId: anyNamed('requestedMoId'),
        authUserId: anyNamed('authUserId'),
      )).thenAnswer((_) async {
        // Wait 1 second to keep loading status active
        await Future.delayed(const Duration(seconds: 1));
        return [];
      });

      // Simple test widget that reads the loading status
      await tester.pumpWidget(
        ChangeNotifierProvider<KanbanProvider>.value(
          value: provider,
          child: Builder(
            builder: (context) {
              final kp = context.watch<KanbanProvider>();
              return MaterialApp(
                home: Scaffold(
                  body: Text(kp.loading ? 'Loading...' : 'Ready', key: const Key('status')),
                ),
              );
            },
          ),
        ),
      );

      // Start the fetch process
      provider.fetchTasks();
      await tester.pump(); // Rebuild after loading = true

      // Should show loading...
      expect(find.text('Loading...'), findsOneWidget);

      // Wait for the async stub to complete
      await tester.pump(const Duration(seconds: 2));

      // Should show Ready
      expect(find.text('Ready'), findsOneWidget);
      expect(provider.loading, isFalse);
    });
  });
}

