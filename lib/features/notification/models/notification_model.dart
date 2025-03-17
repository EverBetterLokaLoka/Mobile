class NotificationModel {
  final int id;
  final int userId;
  final String description;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int foreignId;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    required this.foreignId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      description: json['description'],
      isRead: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      foreignId: json['foreignId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'description': description,
      'status': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'foreignId': foreignId,
    };
  }
}