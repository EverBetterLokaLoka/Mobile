import 'dart:convert';

import 'package:lokaloka/core/constants/url_constant.dart';
import 'package:lokaloka/core/utils/apis.dart';
import 'package:lokaloka/features/auth/services/auth_services.dart';
import 'package:lokaloka/features/notification/models/notification_model.dart';
class NotificationService {
  final ApiService _apiService = ApiService();
  int? userId; // Có thể null
  String? _path; // Có thể null

  Future<void> initialize() async {
    String? userIdString = await AuthService().getUserIdFromToken();
    print("User ID from token: $userIdString"); // Debugging

    if (userIdString != null) {
      userId = int.tryParse(userIdString);
      if (userId != null) {
        _path = '/notifications/user/$userId';
      } else {
        print("Failed to convert userId to int.");
        throw Exception("Invalid userId.");
      }
    } else {
      print("User ID is null, cannot fetch notifications.");
      throw Exception("User ID is null.");
    }
  }


  Future<List<NotificationModel>> getNotifications() async {
    if (_path == null) {
      throw Exception('User ID is not available. Cannot fetch notifications.');
    }

    try {
      final response = await _apiService.request(
        path: _path!,
        method: 'GET',
        typeUrl: UrlConstant().baseUrl,
        currentPath: _path!,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return []; // Return an empty list on error
    }
  }

  Future<void> markAsRead(int notificationId) async {
    // Implement this if needed, depending on your backend API
  }

  Future<bool> deleteNotification(int userId, int foreignId) async {
    try {
      final response = await _apiService.request(
          path: '/notifications/$foreignId/$userId',
          method: "DELETE",
          typeUrl: UrlConstant().baseUrl,
          currentPath: ''
      );
      return true;
    } catch (e) {
      print('Error in deleteFriendRequest: $e');
      throw Exception('Error: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    // Implement this if needed, depending on your backend API
  }

  Future<void> respondToFriendRequest(int notificationId, bool accept) async {
    // Implement this if needed, depending on your backend API
  }
}