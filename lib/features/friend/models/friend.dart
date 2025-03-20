class Friend {
  final int id;
  final int userId;
  final String username;
  final String email;
  final String? avatar;
  final String? relationshipType;

  Friend({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    this.avatar,
    this.relationshipType,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      userId: json['userId'] ?? 0,
      username: json['username'],
      email: json['email'],
      avatar: json['avatar'],
      relationshipType: json['relationshipType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'email': email,
      'avatar': avatar,
      'relationshipType': relationshipType,
    };
  }
}

