import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lokaloka/features/notification/models/notification_model.dart';

class NotificationStorageService {
  static const String _boxName = 'notifications';
  static const String _notificationsKey = 'notification_list';
  late Box _box;

  // Initialize Hive and open the box
  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // Save notifications to local storage
  Future<void> saveNotifications(List<NotificationModel> notifications) async {
    try {
      // Convert notifications to a list of maps
      final List<Map<String, dynamic>> notificationMaps = notifications.map((notification) {
        // Create a safe copy of the notification data
        final Map<String, dynamic> notificationMap = notification.toJson();

        // Handle the data field specially
        if (notificationMap['data'] != null) {
          try {
            // Try to encode and decode to ensure it's JSON-safe
            final String jsonString = jsonEncode(notificationMap['data']);
            notificationMap['data'] = jsonDecode(jsonString);
          } catch (e) {
            // If encoding fails, store a simplified version
            print('❌ Error encoding data field: $e');
            notificationMap['data'] = {
              'error': 'Data could not be serialized',
              'dataType': notificationMap['data'].runtimeType.toString()
            };
          }
        }

        return notificationMap;
      }).toList();

      // Save the list directly
      await _box.put(_notificationsKey, jsonEncode(notificationMaps));
      print('✅ Saved ${notifications.length} notifications to storage');
    } catch (e) {
      print('❌ Error saving notifications: $e');
      // Try a more robust approach if the first attempt fails
      try {
        // Save each notification individually with minimal data
        final List<Map<String, dynamic>> simplifiedMaps = notifications.map((notification) {
          return {
            'id': notification.id,
            'title': notification.title,
            'body': notification.body,
            'createdAt': notification.createdAt.toIso8601String(),
            'isRead': notification.isRead,
            'senderId': notification.senderId,
            'type': notification.type,
            // Omit the data field
          };
        }).toList();

        await _box.put(_notificationsKey, jsonEncode(simplifiedMaps));
        print('✅ Saved ${notifications.length} simplified notifications to storage');
      } catch (e) {
        print('❌ Failed to save even simplified notifications: $e');
      }
    }
  }

  // Load notifications from local storage
  Future<List<NotificationModel>> loadNotifications() async {
    try {
      final String? encodedList = _box.get(_notificationsKey);

      if (encodedList == null) {
        return [];
      }

      final List<dynamic> decodedList = jsonDecode(encodedList);
      final List<NotificationModel> notifications = [];

      for (var item in decodedList) {
        try {
          notifications.add(NotificationModel.fromJson(item));
        } catch (e) {
          print('❌ Error parsing notification: $e');
        }
      }

      // Sort by creation date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Loaded ${notifications.length} notifications from storage');
      return notifications;
    } catch (e) {
      print('❌ Error loading notifications: $e');
      return [];
    }
  }

  // Clear all notifications
  Future<void> clearNotifications() async {
    await _box.delete(_notificationsKey);
    print('✅ Cleared all notifications from storage');
  }

  // Mark a notification as read
  Future<void> markAsRead(int notificationId, List<NotificationModel> allNotifications) async {
    try {
      final updatedNotifications = allNotifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      await saveNotifications(updatedNotifications);
      print('✅ Marked notification $notificationId as read in storage');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(int notificationId, List<NotificationModel> allNotifications) async {
    try {
      final updatedNotifications = allNotifications.where((n) => n.id != notificationId).toList();
      await saveNotifications(updatedNotifications);
      print('✅ Deleted notification $notificationId from storage');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }
}

