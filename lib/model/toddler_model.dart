class Toddler {
  final String toddlerId;
  final String toddlerName;
  final int toddlerAge;
  final String parentId;

  Toddler({
    required this.toddlerId,
    required this.toddlerName,
    required this.toddlerAge,
    required this.parentId,
  });

  factory Toddler.fromMap(Map<String, dynamic> map, String toddlerId) {
    return Toddler(
      toddlerId: toddlerId,
      toddlerName: map['toddler_name'] ?? '',
      toddlerAge: map['toddler_age'] ?? 0,
      parentId: map['parent_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'toddler_name': toddlerName,
      'toddler_age': toddlerAge,
      'parent_id': parentId,
    };
  }
}