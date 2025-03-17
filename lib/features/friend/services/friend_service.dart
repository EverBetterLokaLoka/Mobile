import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:lokaloka/core/utils/apis.dart';
import 'package:lokaloka/features/auth/services/auth_services.dart';
import '../models/friend.dart';

class FriendService {
  static String baseUrl = ApiService().baseUrl;

  // Get all friends
  Future<List<Friend>> getFriends() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/friends'),
        headers: await _getHeaders(),
      );

      developer.log('Status code: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Friend.fromJson(json)).toList();
        } else {
          developer.log('API returned success=false or data=null: $jsonResponse');
          throw Exception('Invalid response format');
        }
      } else {
        developer.log('Failed with status code: ${response.statusCode}');
        throw Exception('Failed to load friends: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in getFriends: $e');
      throw Exception('Error: $e');
    }
  }

  // Search friends
  Future<List<Friend>> searchFriends(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/friends/search?keyword=$query'),
        headers: await _getHeaders(),
      );

      developer.log('Search status code: ${response.statusCode}');
      developer.log('Search response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Friend.fromJson(json)).toList();
        } else {
          throw Exception('Invalid search response format');
        }
      } else {
        throw Exception('Failed to search friends');
      }
    } catch (e) {
      developer.log('Error in searchFriends: $e');
      throw Exception('Error: $e');
    }
  }

  // Get friend suggestions (pending requests)
  Future<List<Friend>> getFriendSuggestions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/friends/requests'),
        headers: await _getHeaders(),
      );

      developer.log('Suggestions status code: ${response.statusCode}');
      developer.log('Suggestions response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Friend.fromJson(json)).toList();
        } else {
          throw Exception('Invalid suggestions response format');
        }
      } else {
        throw Exception('Failed to load friend suggestions');
      }
    } catch (e) {
      developer.log('Error in getFriendSuggestions: $e');
      throw Exception('Error: $e');
    }
  }

  // Get pending requests sent by the current user
  Future<List<Friend>> getPendingRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/friends/pending-requests'),
        headers: await _getHeaders(),
      );

      developer.log('Pending requests status code: ${response.statusCode}');
      developer.log('Pending requests response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Friend.fromJson(json)).toList();
        } else {
          throw Exception('Invalid pending requests response format');
        }
      } else {
        throw Exception('Failed to load pending requests');
      }
    } catch (e) {
      developer.log('Error in getPendingRequests: $e');
      throw Exception('Error: $e');
    }
  }

  // Add friend (approve request) using user ID
  Future<bool> addFriend(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/friends/approval/$userId'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error in addFriend: $e');
      throw Exception('Error: $e');
    }
  }

  // Add friend (approve request) using follower ID
  Future<bool> addFriendWithFollowerId(int followerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/friends/approval/$followerId'),
        headers: await _getHeaders(),
      );
      developer.log('Approve friend with follower ID $followerId status code: ${response.statusCode}');
      developer.log('Approve friend response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error in addFriendWithFollowerId: $e');
      throw Exception('Error: $e');
    }
  }

  // Remove friend
  Future<bool> removeFriend(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/friends/unfriend?friendId=$id'),
        headers: await _getHeaders(),
      );

      developer.log('Remove friend status code: ${response.statusCode}');
      developer.log('Remove friend response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error in removeFriend: $e');
      throw Exception('Error: $e');
    }
  }

  // Helper method to get headers
  Future<Map<String, String>> _getHeaders() async {
    // Wait for the token to be retrieved asynchronously
    String? token = await AuthService().getToken();

    if (token == null) {
      developer.log('Warning: Token is null');
      token = ""; // Provide a default empty token or handle as needed
    }

    developer.log('Using token: $token');

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Send friend request
  Future<bool> addRequestFriend(int userId) async {
    try {
      // Create body with followedId
      final body = json.encode({"followedId": userId});

      final response = await http.post(
        Uri.parse('$baseUrl/friends'),
        headers: await _getHeaders(),
        body: body,
      );

      developer.log('Add friend status code: ${response.statusCode}');
      developer.log('Add friend response: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      developer.log('Error in addRequestFriend: $e');
      throw Exception('Error: $e');
    }
  }

  // Check friend status
  Future<String> checkFriendStatus(int userId) async {
    try {
      // First try to check if the user is in your friends list
      final friends = await getFriends();
      for (var friend in friends) {
        if (friend.userId == userId) {
          return "FRIEND";
        }
      }

      // Then check if they're in your pending requests that you've sent
      final pendingRequests = await getPendingRequests();
      for (var request in pendingRequests) {
        if (request.userId == userId) {
          return "PENDING";
        }
      }

      // Then check if they're in your friend requests (requests sent to you)
      final requests = await getFriendSuggestions();
      for (var request in requests) {
        if (request.userId == userId) {
          return "REQUESTED";
        }
      }

      // If you have an API endpoint for checking status, use it instead
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/friends/status/$userId'),
          headers: await _getHeaders(),
        );

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);

          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            return jsonResponse['data']['status'] ?? "NONE";
          }
        }
      } catch (e) {
        developer.log('Status endpoint not available: $e');
        // Continue with fallback logic
      }

      // If we can't determine the status, assume NONE
      return "NONE";
    } catch (e) {
      developer.log('Error in checkFriendStatus: $e');
      return "NONE";
    }
  }
  // Add friend (approve request) using user ID
  Future<bool> deleteFriendRequest(int followedId) async {
    try {
      final response = await ApiService().request(path: '/friends/cancel-request/$followedId', method: "DELETE", typeUrl: "baseUrl", currentPath: '');
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error in deleteFriendRequest: $e');
      throw Exception('Error: $e');
    }
  }

  // cancel request send
  Future<bool> cancelFriendRequestSend(int followerId) async {
    try {
      final response = await ApiService().request(path: '/friends/cancel-request-send/$followerId', method: "DELETE", typeUrl: "baseUrl", currentPath: '');
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error in deleteFriendRequest: $e');
      throw Exception('Error: $e');
    }
  }
  Future<bool> sendNotification(String message, int friendId, String currentUserSend) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications'), // Thay thế bằng URL thực tế của bạn
        headers: await _getHeaders(), // Sử dụng hàm _getHeaders để có tiêu đề xác thực
        body: jsonEncode({
          'userId': friendId, // ID của người nhận thông báo
          'description': message, // Mô tả thông báo
          'foreignId': currentUserSend // ID của người gửi lời mời kết bạn
        }),
      );

      if (response.statusCode == 200) {
        return true; // Trả về true nếu thành công
      } else {
        developer.log('Failed to send notification: ${response.body}');
        return false; // Trả về false nếu không thành công
      }
    } catch (e) {
      developer.log('Error in sendNotification: $e');
      return false; // Trả về false trong trường hợp có lỗi
    }
  }
  Future<bool> cancelNotification(int currentUserId, int foreignId) async {
    try {
      final response = await ApiService().request(path: '/notifications/$foreignId/$currentUserId', method: "DELETE", typeUrl: "baseUrl", currentPath: '');
      return true;
    } catch (e) {
      developer.log('Error in deleteFriendRequest: $e');
      throw Exception('Error: $e');
    }
  }
}

