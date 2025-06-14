class AppUser {
  final String userId;
  final String userName;
  final String userEmail;
  final List<String> toddlerIds;

  AppUser({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.toddlerIds,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String userId) {
    // Handle the toddlers data conversion properly
    List<String> toddlersList = [];

    if (map['toddlers'] != null) {
      if (map['toddlers'] is Map) {
        // Convert Map keys to List<String>
        toddlersList = (map['toddlers'] as Map).keys.cast<String>().toList();
      } else if (map['toddlers'] is List) {
        // If stored as List instead of Map
        toddlersList = List<String>.from(map['toddlers']);
      }
    }

    return AppUser(
      userId: userId,
      userName: map['user_name'] ?? '',
      userEmail: map['user_email'] ?? '',
      toddlerIds: toddlersList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_name': userName,
      'user_email': userEmail,
      'toddlers': {for (var id in toddlerIds) id: true}, // Stores as Map
    };
  }
}