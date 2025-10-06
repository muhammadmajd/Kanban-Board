
import 'package:kpi/providers/kanban_provider.dart';

extension KanbanProviderTestExtension on KanbanProvider {
  // Expose the private _normalizeAllOrders for direct unit testing
  dynamic getPrivateMethodsForTest() {
    return _KanbanProviderPrivateHelper(this);
  }
}

class _KanbanProviderPrivateHelper {
  final KanbanProvider _provider;

  _KanbanProviderPrivateHelper(this._provider);


  void normalizeAllOrders() {
    _provider.normalizeAllOrders();
  }
}