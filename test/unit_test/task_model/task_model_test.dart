import 'package:flutter_test/flutter_test.dart';
import 'package:kpi/models/task_model.dart';
void main() {
  // Define a standard, valid JSON map for testing
  final Map<String, dynamic> validJson = {
    'indicator_to_mo_id': 101,
    'parent_id': 1,
    'name': 'Implement Unit Tests',
    'order': 5,
  };

  // Define a standard model instance
  final TaskModel standardTask = TaskModel(
    indicatorToMoId: 101,
    parentId: 1,
    name: 'Implement Unit Tests',
    order: 5,
  );

  group('TaskModel', () {
    // --- 1. Initialization and Basic Properties ---
    test('should correctly initialize with given values', () {
      final task = TaskModel(
        indicatorToMoId: 50,
        parentId: 2,
        name: 'Refactor Code',
        order: 1,
      );
      expect(task.indicatorToMoId, 50);
      expect(task.parentId, 2);
      expect(task.name, 'Refactor Code');
      expect(task.order, 1);
    });

    // --- 2. fromJson Factory Method Tests ---
    group('fromJson', () {
      test('should create a TaskModel from valid JSON data', () {
        final task = TaskModel.fromJson(validJson);

        expect(task, isA<TaskModel>());
        expect(task.indicatorToMoId, 101);
        expect(task.parentId, 1);
        expect(task.name, 'Implement Unit Tests');
        expect(task.order, 5);
      });

      test('should handle string values for integer fields gracefully', () {
        final Map<String, dynamic> stringIntJson = {
          'indicator_to_mo_id': '202',
          'parent_id': '3',
          'name': 'Handle String Ints',
          'order': '10',
        };
        final task = TaskModel.fromJson(stringIntJson);

        expect(task.indicatorToMoId, 202);
        expect(task.parentId, 3);
        expect(task.order, 10);
      });

      test('should default to 0 for null, empty, or unparseable integer fields', () {
        final Map<String, dynamic> problematicJson = {
          'indicator_to_mo_id': null,
          'parent_id': '',
          'name': 'Problematic Data',
          'order': 'not_a_number',
        };
        final task = TaskModel.fromJson(problematicJson);

        expect(task.indicatorToMoId, 0); // null -> 0
        expect(task.parentId, 0); // empty string -> 0
        expect(task.order, 0); // unparseable string -> 0
      });

      test('should handle null for string field by using empty string', () {
        final Map<String, dynamic> nullStringJson = {
          'indicator_to_mo_id': 1,
          'parent_id': 1,
          'name': null,
          'order': 1,
        };
        final task = TaskModel.fromJson(nullStringJson);

        expect(task.name, ''); // null -> ''
      });
    });

    // --- 3. toJson Serialization Test ---
    test('should correctly convert the TaskModel instance to a JSON map', () {
      final json = standardTask.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['indicator_to_mo_id'], 101);
      expect(json['parent_id'], 1);
      expect(json['name'], 'Implement Unit Tests');
      expect(json['order'], 5);
    });

    // --- 4. copyWith Method Tests ---
    group('copyWith', () {
      test('should return a new instance with the same values when no parameters are provided', () {
        final copiedTask = standardTask.copyWith();

        expect(copiedTask.indicatorToMoId, standardTask.indicatorToMoId);
        expect(copiedTask.parentId, standardTask.parentId);
        expect(copiedTask.name, standardTask.name);
        expect(copiedTask.order, standardTask.order);
        // Ensure it's a new instance, not just a reference to the old one
        expect(copiedTask, isNot(same(standardTask)));
      });

      test('should create a new instance with updated parentId and order', () {
        final copiedTask = standardTask.copyWith(
          parentId: 2,
          order: 99,
        );

        // Updated fields
        expect(copiedTask.parentId, 2);
        expect(copiedTask.order, 99);

        // Unchanged fields
        expect(copiedTask.indicatorToMoId, standardTask.indicatorToMoId);
        expect(copiedTask.name, standardTask.name);
      });

      test('should create a new instance with an updated name', () {
        final newName = 'Update API calls';
        final copiedTask = standardTask.copyWith(name: newName);

        // Updated field
        expect(copiedTask.name, newName);

        // Unchanged fields
        expect(copiedTask.parentId, standardTask.parentId);
      });
    });
  });
}