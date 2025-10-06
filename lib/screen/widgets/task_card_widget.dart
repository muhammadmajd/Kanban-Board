import 'package:flutter/material.dart';

import '../../models/kanban_task_item.dart';



class TaskCardWidget extends StatelessWidget {
  final KanbanTaskItem taskItem;
  final Color columnColor;
  final bool isDarkMode;

  const TaskCardWidget({
    super.key,
    required this.taskItem,
    required this.columnColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final task = taskItem.task;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: columnColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? columnColor : columnColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${task.order}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Task Content
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    task.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.grey.shade800,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'ID: ${task.indicatorToMoId}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}