

import 'package:flutter/material.dart';
import 'package:kpi/screen/widgets/item_ghost_widget.dart';
import 'package:kpi/screen/widgets/task_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:kanban_board/kanban_board.dart';
import '../models/kanban_task_group.dart';
import '../models/kanban_task_item.dart';
import '../providers/kanban_provider.dart';
import '../models/task_model.dart';
import '../providers/theme_provider.dart';
import 'widgets/k_appbar.dart';




class KanbanBoardScreen extends StatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}
class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  late KanbanBoardController _controller ;
  //  ADD a key for the KanbanBoard
  Key _boardKey = ValueKey(0); // Initialize with a simple key

  @override
  void initState() {
    super.initState();
    _controller = KanbanBoardController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<KanbanProvider>(context, listen: false);
      provider.fetchTasks().catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $error')),
        );
      });
    });
  }




  Map<int, String> get columnTitles => {
    0: "Новые задачи",
    1: "В процессе",
    2: "Завершено",
  };

  Map<int, Color> get columnColors => {
    0: Colors.blue,
    1: Colors.orange,
    2: Colors.green,
  };

  /// Column Header Builder (Used by groupHeaderBuilder)
  Widget _groupHeaderBuilder(BuildContext context, KanbanTaskGroup group, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(

        color:  isDarkMode ? Colors.grey[700] :Colors.blue,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Text(
            group.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${group.items.length} задач',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }



  // Group Constraints (Column Width)
  BoxConstraints get _groupConstraints => const BoxConstraints(
    minWidth: 300,
    maxWidth: 300,
  );

  /// --- WIDGET BUILD ---

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KanbanProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Transform the provider's Map data into the package's expected List of KanbanTaskGroup.
    final List<KanbanTaskGroup> kanbanGroups = provider.columns.entries.map((entry) {
      final parentId = entry.key;
      final color = columnColors[parentId] ?? Colors.blue;
      final title = columnTitles[parentId] ?? "Папка $parentId";

      // Map TaskModel to KanbanTaskItem
      final taskItems = entry.value.map((task) => KanbanTaskItem(task: task)).toList();

      return KanbanTaskGroup(
        parentId: parentId,
        id: parentId.toString(),
        name: title,
        color: color,
        items: taskItems,
      );
    }).toList();
    // Determine Theme Colors for SnackBar
    final Color snackBarBackgroundColor = themeProvider.isDarkMode ? Colors.grey.shade700 : Colors.green.shade50;
    final Color snackBarContentColor = themeProvider.isDarkMode ? Colors.white : Colors.green.shade900;

    return Scaffold(
      appBar: KAppBar(title: 'Kanban Board',),

      body: provider.loading
          ? Center(child: CircularProgressIndicator(color:themeProvider.isDarkMode?Colors.blue: Colors.white))
          : KanbanBoard(
                  key: _boardKey,
                  controller: _controller,
                  groups: kanbanGroups,

                  // Styling and constraints
                  boardDecoration: BoxDecoration(
                     color: themeProvider.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                  ),
                  groupDecoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                  ),
                  groupConstraints: _groupConstraints,

                  // Ghost and Footers
                  itemGhost: GhostWidget( isDarkMode: themeProvider.isDarkMode,),
                  // groupFooterBuilder: (context, groupId) => _buildListFooter(),

                  // Builders
                  groupHeaderBuilder: (context, group) {

                  final String groupId = group.toString();

                  final kanbanGroup = kanbanGroups.firstWhere((g) => g.id == groupId);
                  return _groupHeaderBuilder(context, kanbanGroup, themeProvider.isDarkMode);
                  },

                  groupItemBuilder: (context, groupId, itemIndex) {
                      // Lookup by groupId (String) is correct here.
                      final group = kanbanGroups.firstWhere((g) => g.id == groupId);
                      // Get the item
                      final taskItem = group.items[itemIndex];

                      // Use the existing card builder
                      return TaskCardWidget(taskItem:taskItem,columnColor: group.color, isDarkMode:themeProvider.isDarkMode);
                              },

                       onGroupItemMove: (oldItemIndex, newItemIndex, oldGroupIndex, newGroupIndex) async {
                              try{
                                    // Safety checks (prevent RangeError)
                                    if (oldGroupIndex == null || newGroupIndex == null ||
                                        oldItemIndex == null || newItemIndex == null ||
                                        oldGroupIndex >= kanbanGroups.length || newGroupIndex >= kanbanGroups.length) return;

                                    final KanbanTaskGroup oldGroup = kanbanGroups[oldGroupIndex];
                                    if (oldItemIndex >= oldGroup.items.length) return;

                                    final KanbanTaskGroup newGroup = kanbanGroups[newGroupIndex];
                                    final KanbanTaskItem draggedItem = oldGroup.items[oldItemIndex];
                                    final TaskModel draggedTask = draggedItem.task;

                                    final actionProvider = Provider.of<KanbanProvider>(context, listen: false);

                                    // Call provider (optimistic update happens inside)
                                    bool success = await actionProvider.moveTask(
                                      indicatorToMoId: draggedTask.indicatorToMoId,
                                      fromParentId: oldGroup.parentId,
                                      fromIndex: oldItemIndex,
                                      toParentId: newGroup.parentId,
                                      toIndex: newItemIndex,

                                    );

                                  // Handle feedback and board reset
                                  if (mounted) {
                                    // Show SnackBar based on success/failure
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? ' Изменения сохранены.'
                                              : ' Не удалось сохранить изменения. Откат данных.',
                                          style: TextStyle(
                                              color: success ? snackBarContentColor : Colors
                                                  .white),
                                        ),
                                        backgroundColor: success
                                            ? snackBarBackgroundColor
                                            : Colors.red,
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );

                                    // Force board rebuild to prevent scroll controller errors
                                    /*setState(() {
                                      _boardKey = ValueKey(DateTime.now().microsecondsSinceEpoch);
                                    });*/

                                  }
                            }
                                 catch(e)
                                 {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                       content: Text('Error:'+e.toString(),
                                         style: TextStyle(
                                             color:  snackBarContentColor,
                                       )),
                                       backgroundColor:snackBarBackgroundColor,
                                       duration: const Duration(seconds: 2),
                                       behavior: SnackBarBehavior.floating,
                                     ),
                                   );

                                 }
                  },
                  onGroupMove: (oldGroupIndex, newGroupIndex) {
                  },
                ),
    );
  }
}
