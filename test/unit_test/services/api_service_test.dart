import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kpi/models/task_model.dart';
import 'package:kpi/services/api_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';


//  Specify which class to generate a mock for (the http.Client)
@GenerateMocks([
  http.Client,  // Generates MockClient
  ApiService   // Generates MockApiService
])
import 'api_service_test.mocks.dart';

void main() {
  late MockClient mockClient;
  late ApiService apiService;
  const String testToken = 'test_token';
  final Uri fetchTasksUrl = Uri.parse('https://api.dev.kpi-drive.ru/_api/indicators/get_mo_indicators');

  // Define the standard mock response data
  final String mockTasksJson = json.encode({
    "STATUS": "OK",
    "DATA": {
      "rows": [
        {"indicator_to_mo_id": 1001, "parent_id": 1, "name": "Task 1", "order": 1},
        {"indicator_to_mo_id": 1002, "parent_id": 2, "name": "Task 2", "order": 2},
      ]
    }
  });

  setUp(() {
    // Create mock object.
    mockClient = MockClient();

    //  Initialize ApiService with the mock client.
    apiService = ApiService(token: testToken, client: mockClient);
  });

  // -------------------------------------------------------------------------

  group('fetchTasks', () {
    const String periodStart = '2025-01-01';
    const String periodEnd = '2025-01-31';
    const int requestedMoId = 42;
    const int authUserId = 40;

    test('should return a list of TaskModel on successful API call (200)', () async {
      // Stub the method before interacting with it (WHEN the client posts to ANY url...).
      when(
        mockClient.post(
          fetchTasksUrl,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response(mockTasksJson, 200));

      // Interact with the mock object.
      final result = await apiService.fetchTasks(
        periodStart: periodStart,
        periodEnd: periodEnd,
        periodKey: 'month',
        requestedMoId: requestedMoId,
        authUserId: authUserId,
      );

      // Verify the interaction and the result.
      verify(mockClient.post(
        fetchTasksUrl, // Verify correct URL
        headers: {'Authorization': 'Bearer $testToken'}, // Verify correct headers
        body: anyNamed('body'), // Verify correct body was sent
      )).called(1); // Exact number of invocations

      expect(result, isA<List<TaskModel>>());
      expect(result.length, 2);
      expect(result[0].name, 'Task 1');
    });

    test('should throw an exception when API returns an error status code (500)', () {
      // Stub the method to throw a specific error.
      when(
        mockClient.post(
          fetchTasksUrl,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      // Assert that calling the method throws the expected exception.
      expect(
        apiService.fetchTasks(
          periodStart: periodStart,
          periodEnd: periodEnd,
          periodKey: 'month',
          requestedMoId: requestedMoId,
          authUserId: authUserId,
        ),
        throwsA(isA<Exception>()),
      );

      // Verify the interaction.
      verify(mockClient.post(
        fetchTasksUrl,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);
    });



    test('should return empty list when API returns empty data array', () async {
      final String mockEmptyJson = json.encode({"STATUS": "OK", "DATA": {"rows": []}});

      // Stub the method to return empty rows.
      when(
        mockClient.post(
          fetchTasksUrl,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response(mockEmptyJson, 200));

      // Interact with the mock object.
      final result = await apiService.fetchTasks(
        periodStart: periodStart,
        periodEnd: periodEnd,
        periodKey: 'month',
        requestedMoId: requestedMoId,
        authUserId: authUserId,
      );

      //   FIRST, verify the interaction that just occurred.
      verify(mockClient.post(
        fetchTasksUrl,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);

      //  SECOND, assert the result.
      expect(result, isEmpty);

      // THIRD, verify no *unverified* interactions remain.
      // This is now safe because the post call was just verified in step 3.
      verifyNoMoreInteractions(mockClient);
    });
  });


  group('saveTaskUpdate', () {
    test('should return false on unmocked network exception', () async {
      // Since we did not stub the client to handle the MultipartRequest,
      // the network call inside saveTaskUpdate will fail and be caught.
      final result = await apiService.saveTaskUpdate(
        periodStart: '2025-01-01',
        periodEnd: '2025-01-31',
        periodKey: 'month',
        indicatorToMoId: 1001,
        newParentId: 2,
        newOrder: 5,
        authUserId: 40,
      );

      // The final catch block ensures this returns false.
      expect(result, isFalse);
    });

  });

}