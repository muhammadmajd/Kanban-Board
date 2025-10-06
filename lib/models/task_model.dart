class TaskModel {
  final int indicatorToMoId;
  int parentId;
  String name;
  int order;

  TaskModel({
    required this.indicatorToMoId,
    required this.parentId,
    required this.name,
    required this.order,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        if (value.isEmpty) return 0;
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    String safeParseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    return TaskModel(
      indicatorToMoId: safeParseInt(json['indicator_to_mo_id']),
      parentId: safeParseInt(json['parent_id']),
      name: safeParseString(json['name']),
      order: safeParseInt(json['order']),
    );
  }

  Map<String, dynamic> toJson() => {
    'indicator_to_mo_id': indicatorToMoId,
    'parent_id': parentId,
    'name': name,
    'order': order,
  };

  //  copyWith
  TaskModel copyWith({
    int? indicatorToMoId,
    int? parentId,
    String? name,
    int? order,
  }) {
    return TaskModel(
      indicatorToMoId: indicatorToMoId ?? this.indicatorToMoId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }
}
