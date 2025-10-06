
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

class KanbanProvider extends ChangeNotifier {
  final ApiService api;
  List<TaskModel> _tasks = [];
  bool loading = false;
  bool isSaving = false;

  // Default params
  String periodStart = '2025-08-01';
  String periodEnd = '2025-08-31';
  String periodKey = 'month';
  int requestedMoId = 42;
  int authUserId = 40;

  KanbanProvider({required this.api});

  List<TaskModel> get tasks => _tasks;

  ///  Группировка задач по их родительским идентификаторам.
  Map<int, List<TaskModel>> get columns {
    final map = <int, List<TaskModel>>{};
    for (var t in _tasks) {
      map.putIfAbsent(t.parentId, () => []);
      map[t.parentId]!.add(t);
    }
    // Сортировка задач в каждом столбце.
    for (var key in map.keys) {
      map[key]!.sort((a, b) => a.order.compareTo(b.order));
    }
    return map;
  }
 /// Получение всех задач
  Future<void> fetchTasks() async {
    loading = true;
    notifyListeners();
    try {
      final list = await api.fetchTasks(
        periodStart: periodStart,
        periodEnd: periodEnd,
        periodKey: periodKey,
        requestedMoId: requestedMoId,
        authUserId: authUserId,
      );
      _tasks = list;
      normalizeAllOrders();
    } catch (e) {
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
  ///Метод сбрасывает и нормализует порядковые номера всех задач в каждом столбце,
  /// чтобы обеспечить чёткую последовательную нумерацию, начиная с 1.

  void normalizeAllOrders() {
    final cols = <int, List<TaskModel>>{};
    for (var t in _tasks) {
      cols.putIfAbsent(t.parentId, () => []);
      cols[t.parentId]!.add(t);
    }
    final newList = <TaskModel>[];
    for (var entry in cols.entries) {
      final col = entry.value;
      col.sort((a, b) => a.order.compareTo(b.order));
      for (int i = 0; i < col.length; i++) {
        col[i].order = i + 1;
        //developer.log( col[i].name);

        newList.add(col[i]);
      }
    }
    _tasks = newList;
  }
  /// Переместить задачу: обновить локальное состояние, затем сохранить изменения для затронутых столбцов.
  /// в случае сбоя -> откатиться к резервной копии и вернуть false
  Future<bool> moveTask({
    required int indicatorToMoId,
    required int fromParentId,
    required int fromIndex,
    required int toParentId,
    required int toIndex,

  }) async {
    //if (isSaving) return false; // prevent concurrent moves
    if (isSaving) {
      developer.log('Already saving, ignoring move', name: 'KanbanProvider');
      return false;
    }
    isSaving = true;
    developer.log(
      'moveTask called with: '
          'indicatorToMoId: $indicatorToMoId, '
          'fromParentId: $fromParentId, '
          'fromIndex: $fromIndex, '
          'toParentId: $toParentId, '
          'toIndex: $toIndex',
      name: 'KanbanProvider',
      //level: developer.Level.info.value,
    );


    // Сохранение резервной версии на случай сбоя API
    final backup = _tasks.map((t) => t.copyWith()).toList();

    try {
      //Создание столбцов Карта для манипуляций
      final cols = columns.map((k, v) => MapEntry(k, v.toList()));

      ///  Удалить из исходного списка
      //
      final srcList = cols[fromParentId];
      if (srcList == null) throw Exception('Source column not found');

      TaskModel? moving;

      // Получить элемент
      if (fromIndex < srcList.length) {
        moving = srcList.removeAt(fromIndex);
      } else {
        // Fallback or error: Task not found at expected index
        throw Exception('Task not found at index $fromIndex in column $fromParentId');
      }

      ///   Вставить элемент в целевой список.
      cols.putIfAbsent(toParentId, () => []);
      final destList = cols[toParentId]!;

      // Вставить по точному индексу, рассчитанному DropTargetAre.
      final insertIndex = toIndex.clamp(0, destList.length);
      destList.insert(insertIndex, moving);

      // Переназначить parentId и order для затронутых столбцов.
      void reindex(int pid) {
        final list = cols[pid] ?? [];
        for (int i = 0; i < list.length; i++) {
          list[i].parentId = pid;
          list[i].order = i + 1; // Orders start at 1
        }
      }

      reindex(fromParentId);
      if (fromParentId != toParentId) reindex(toParentId);

      //  Пересоздать _tasks из столбцов и уведомить listeners (оптимистичное обновление).
      final newTasks = <TaskModel>[];
      for (var entry in cols.entries) {
        newTasks.addAll(entry.value);
      }
      _tasks = newTasks;
      notifyListeners();

      // сохранить изменения в базе данных.
      //final x= await api.testSave();
      final result = await api.saveTaskUpdate(
        periodStart: periodStart,
        periodEnd: periodEnd,
        periodKey: periodKey,
        indicatorToMoId: indicatorToMoId,
        newParentId: toParentId,
        newOrder: toIndex+1, // This is the new order!
        authUserId: authUserId,
      );


      if (!result) {
        throw Exception('Failed saving task ');
      }
      else{

      }


      isSaving = false;
      return true;
    } catch (e) {
      // Откат при сбое
      _tasks = backup;
      isSaving = false;
      notifyListeners();

      return false;
    }
  }

}
