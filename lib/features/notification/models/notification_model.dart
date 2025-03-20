import 'dart:convert';

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final int senderId;
  final String type;
  final Map<String, dynamic>? data;
  final int? friendId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    required this.senderId,
    required this.type,
    this.data,
    this.friendId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Generate a unique ID if not provided
    final id = json['id'] != null
        ? json['id'] is String ? int.parse(json['id']) : json['id']
        : DateTime.now().millisecondsSinceEpoch;

    // Handle senderId which might be null or a different type
    final senderId = json['senderId'] != null
        ? json['senderId'] is String ? int.parse(json['senderId']) : json['senderId']
        : 0;
// Handle followerId which might be null or a different type
    final friendId = json['friendId'] != null
        ? json['friendId'] is String ? int.parse(json['friendId']) : json['friendId']
        : null;
    // Handle the data field safely
    Map<String, dynamic>? dataMap;
    if (json['data'] != null) {
      if (json['data'] is String) {
        try {
          dataMap = jsonDecode(json['data']);
        } catch (e) {
          dataMap = {'value': json['data']};
        }
      } else if (json['data'] is Map) {
        dataMap = Map<String, dynamic>.from(json['data']);
      }
    }

    return NotificationModel(
      id: id,
      title: json['title'] ?? 'No Title',
      body: json['body'] ?? 'No Content',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      senderId: senderId,
      type: json['type'] ?? 'UNKNOWN',
      data: dataMap,
      friendId: friendId,
    );
  }

  Map<String, dynamic> toJson() {
    // Create a safe copy of data
    Map<String, dynamic>? safeData;
    if (data != null) {
      try {
        // Test if data is JSON serializable by encoding and decoding
        final encoded = jsonEncode(data);
        safeData = jsonDecode(encoded);
      } catch (e) {
        // If not serializable, create a simplified version
        safeData = {
          'error': 'Data could not be serialized',
          'dataType': data.runtimeType.toString()
        };
      }
    }

    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'senderId': senderId,
      'type': type,
      'data': safeData,
      'friendId':friendId,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    int? senderId,
    String? type,
    Map<String, dynamic>? data,
    int? friendId
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      data: data ?? this.data,
      friendId: friendId??this.friendId
    );
  }
}

