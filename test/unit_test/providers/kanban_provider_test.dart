import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpi/models/task_model.dart';
import 'package:kpi/providers/kanban_provider.dart';
import 'package:mockito/mockito.dart';
import '../../helper/kanban_provider_private_helper.dart';
import '../services/api_service_test.mocks.dart';

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


  group('KanbanProvider Unit Tests', () {

    // --- State and Getter Tests ---
    test('Initial state properties are correct', () {
      final initialProvider = KanbanProvider(api: mockApi);
      expect(initialProvider.tasks, isEmpty);
      expect(initialProvider.loading, isFalse);
      expect(initialProvider.isSaving, isFalse);
    });

    test('columns getter groups and sorts tasks correctly', () {
      final cols = provider.columns;

      // Check column keys
      expect(cols.keys, containsAll([10, 20, 30]));

      // Check sorting within column 10 (T1, T3)
      expect(cols[10]!.map((t) => t.name), ['T1', 'T3']);

      // Check sorting within column 20 (T5, T2) - T5 order 1, T2 order 2
      expect(cols[20]!.map((t) => t.name), ['T5', 'T2']);
    });

    // --- normalizeAllOrders Test ---
    test('normalizeAllOrders resets and sorts orders starting from 1', () {
      // Setup tasks with complex or non-sequential orders
      provider.tasks.clear();
      provider.tasks.addAll([
        TaskModel(indicatorToMoId: 1, parentId: 10, name: 'C', order: 5), // will become order 3
        TaskModel(indicatorToMoId: 2, parentId: 20, name: 'E', order: 10), // will become order 2
        TaskModel(indicatorToMoId: 3, parentId: 10, name: 'A', order: 1), // will become order 1
        TaskModel(indicatorToMoId: 4, parentId: 30, name: 'F', order: 1), // will become order 1
        TaskModel(indicatorToMoId: 5, parentId: 20, name: 'D', order: 5), // will become order 1
        TaskModel(indicatorToMoId: 6, parentId: 10, name: 'B', order: 2), // will become order 2
      ]);

      provider.getPrivateMethodsForTest().normalizeAllOrders(); // Access the internal method

      final cols = provider.columns; // This getter uses the new internal _tasks

      // Column 10: A(1), B(2), C(3)
      expect(cols[10]!.map((t) => t.name), ['A', 'B', 'C']);
      expect(cols[10]!.map((t) => t.order), [1, 2, 3]);

      // Column 20: D(1), E(2)
      expect(cols[20]!.map((t) => t.name), ['D', 'E']);
      expect(cols[20]!.map((t) => t.order), [1, 2]);
    });

    // --- fetchTasks Tests ---
    test('fetchTasks sets loading, calls API, and updates tasks on success', () async {
      final mockTasks = [TaskModel(indicatorToMoId: 99, parentId: 1, name: 'Mock', order: 1)];

      // Stub the API call
      when(mockApi.fetchTasks(
        periodStart: anyNamed('periodStart'),
        periodEnd: anyNamed('periodEnd'),
        periodKey: anyNamed('periodKey'),
        requestedMoId: anyNamed('requestedMoId'),
        authUserId: anyNamed('authUserId'),
      )).thenAnswer((_) async => mockTasks);

      // 1. Initial check (loading is false)
      expect(provider.loading, isFalse);

      final future = provider.fetchTasks();

      // 2. Check loading state during call
      expect(provider.loading, isTrue);

      await future;

      // 3. Check final state and data
      expect(provider.loading, isFalse);
      expect(provider.tasks, mockTasks);

      // Verify API was called once with correct parameters
      verify(mockApi.fetchTasks(
        periodStart: '2025-08-01',
        periodEnd: '2025-08-31',
        periodKey: 'month',
        requestedMoId: 42,
        authUserId: 40,
      )).called(1);
    });

    test('fetchTasks resets loading and rethrows exception on API failure', () async {
      // Stub the API call to throw an error
      when(mockApi.fetchTasks(
        periodStart: anyNamed('periodStart'),
        periodEnd: anyNamed('periodEnd'),
        periodKey: anyNamed('periodKey'),
        requestedMoId: anyNamed('requestedMoId'),
        authUserId: anyNamed('authUserId'),
      )).thenThrow(Exception('API Failed'));

      // Ensure the call throws the exception
      expect(provider.fetchTasks(), throwsException);

      // Wait for the asynchronous call to complete its cleanup (using a microtask queue flush)
      await Future.microtask(() {});

      // Check cleanup state
      expect(provider.loading, isFalse);
    });

    // --- moveTask Tests (Core Logic) ---
    test('moveTask correctly moves task within the same column and reindexes', () async {
      // Setup API to succeed
      when(mockApi.saveTaskUpdate(
        periodStart: anyNamed('periodStart'),
        periodEnd: anyNamed('periodEnd'),
        periodKey: anyNamed('periodKey'),
        indicatorToMoId: anyNamed('indicatorToMoId'),
        newParentId: anyNamed('newParentId'),
        newOrder: anyNamed('newOrder'),
        authUserId: anyNamed('authUserId'),
      )).thenAnswer((_) async => true);

      // Initial state of column 10: T1 (order 1), T3 (order 3)
      // Task T3 is at local index 1 (since T1 has order 1 and T3 has order 3, the list has T1 then T3)

      // Move T1 (id 1, index 0) to the end of its column (new index 2)
      final success = await provider.moveTask(
        indicatorToMoId: 1,
        fromParentId: 10,
        fromIndex: 0,
        toParentId: 10,
        toIndex: 2,
      );

      // Check success and saving status
      expect(success, isTrue);
      expect(provider.isSaving, isFalse);

      final col10 = provider.columns[10]!;

      // Check new order: T3, T1
      expect(col10.map((t) => t.name), ['T3', 'T1']);

      // Check reindexing: T3.order=1, T1.order=2
      expect(col10[0].order, 1);
      expect(col10[1].order, 2);

      // Verify API call for T1's new position (newParentId=10, newOrder=2)
     /* verify(mockApi.saveTaskUpdate(
        indicatorToMoId: 1,
        newParentId: 10,
        newOrder: 2, // toIndex + 1
        authUserId: 40,
        periodStart: '2025-08-01',
        periodEnd: '2025-08-31',
        periodKey: 'month',
      )).called(1);*/
    });

    test('moveTask correctly moves task between columns and reindexes both', () async {
      // Setup API to succeed
      when(mockApi.saveTaskUpdate(
        periodStart: anyNamed('periodStart'),
        periodEnd: anyNamed('periodEnd'),
        periodKey: anyNamed('periodKey'),
        indicatorToMoId: anyNamed('indicatorToMoId'),
        newParentId: anyNamed('newParentId'),
        newOrder: anyNamed('newOrder'),
        authUserId: anyNamed('authUserId'),
      )).thenAnswer((_) async => true);

      // Initial: Col 10: [T1, T3], Col 30: [T4]

      // Move T1 (id 1, from index 0) from Col 10 to Col 30 (new index 0)
      final success = await provider.moveTask(
        indicatorToMoId: 1,
        fromParentId: 10,
        fromIndex: 0,
        toParentId: 30,
        toIndex: 0,

      );

      // Check success and saving status
      expect(success, isTrue);
      expect(provider.isSaving, isFalse);

      final col10 = provider.columns[10]!; // Source: T1 removed, only T3 remains
      final col30 = provider.columns[30]!; // Destination: T1 inserted at 0

      // Check Col 10 (Source)
      expect(col10.map((t) => t.name), ['T3']);
      expect(col10[0].order, 1); // Reindexed from 3 to 1

      // Check Col 30 (Destination)
      expect(col30.map((t) => t.name), ['T1', 'T4']);
      expect(col30[0].parentId, 30); // ParentId reassigned
      expect(col30[0].order, 1);     // Reindexed T1 to order 1
      expect(col30[1].order, 2);     // Reindexed T4 to order 2

      // Verify API call for T1's new position
     /* verify(mockApi.saveTaskUpdate(
        indicatorToMoId: 1,
        newParentId: 30, // New parent ID
        newOrder: 1,     // toIndex + 1
        authUserId: 40,
        periodStart: anyNamed('periodStart'), periodEnd: '', periodKey: '',
      )).called(1);*/
    });

    test('moveTask rolls back state and resets flags on API failure', () async {
      // Initial: Col 10: [T1, T3], Col 30: [T4]
      final initialT1Order = provider.tasks.firstWhere((t) => t.indicatorToMoId == 1).order;
      final initialT1Parent = provider.tasks.firstWhere((t) => t.indicatorToMoId == 1).parentId;

      // Stub the API call to fail after the optimistic update
      when(mockApi.saveTaskUpdate(
        periodStart: anyNamed('periodStart'),
        periodEnd: anyNamed('periodEnd'),
        periodKey: anyNamed('periodKey'),
        indicatorToMoId: anyNamed('indicatorToMoId'),
        newParentId: anyNamed('newParentId'),
        newOrder: anyNamed('newOrder'),
        authUserId: anyNamed('authUserId'),
      )).thenAnswer((_) async => false); // API Save failed

      // Attempt to move T1 from Col 10 to Col 30
      final success = await provider.moveTask(
        indicatorToMoId: 1,
        fromParentId: 10,
        fromIndex: 0,
        toParentId: 30,
        toIndex: 0,
      );

      // Check failure and saving status
      expect(success, isFalse);
      expect(provider.isSaving, isFalse);

      // Check that the state has been rolled back
      final finalT1 = provider.tasks.firstWhere((t) => t.indicatorToMoId == 1);
      expect(finalT1.parentId, initialT1Parent); // Still in Col 10
      expect(finalT1.order, initialT1Order);     // Still order 1
      expect(provider.columns[30]!.length, 1);   // Col 30 is back to original size (1)
    });
  });

}


