import 'package:kanban_board/kanban_board.dart';
import 'package:kpi/models/task_model.dart';

/// Helper class to wrap TaskModel and implement KanbanBoardGroupItem
class KanbanTaskItem extends KanbanBoardGroupItem {
  final TaskModel task;

  KanbanTaskItem({required this.task});

  // The package requires a unique ID for each item
  @override
  String get id => task.indicatorToMoId.toString();
}
