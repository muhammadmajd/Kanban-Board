import 'package:kanban_board/kanban_board.dart';
import 'package:flutter/material.dart';

import 'kanban_task_item.dart';

/// Helper class to structure column data and implement KanbanBoardGroup
class KanbanTaskGroup extends KanbanBoardGroup<String, KanbanTaskItem> {
  final int parentId;
  final Color color;

  KanbanTaskGroup({
    required this.parentId,
    required super.id,
    required super.name,
    required this.color,
    required super.items,
  });
}
