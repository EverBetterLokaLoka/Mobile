import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:lokaloka/core/utils/apis.dart';
import 'package:lokaloka/features/auth/models/user.dart';
import 'package:lokaloka/features/auth/services/auth_services.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:lokaloka/features/profile/models/post_modal.dart';
import 'package:lokaloka/core/constants/url_constant.dart';
import 'package:lokaloka/globals.dart';

class ProfileService {
  String baseUrl = ApiService().baseUrl;
  final ApiService _apiService = ApiService();

  // Fetch user profile
  Future<UserNormal?> getUserProfile() async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) {
        throw Exception("No token available, please log in again.");
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (!decodedToken.containsKey('id')) {
        throw Exception("Token doesn't contain user ID!");
      }
      String userId = decodedToken['id'].toString();
      print(userId);
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return UserNormal.fromJson(responseData['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again');
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while fetching profile: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserNormal user) async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) {
        throw Exception("No token found");
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (!decodedToken.containsKey('id')) {
        throw Exception("Token doesn't contain user ID!");
      }
      String userId = decodedToken['id'].toString();

      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'full_name': user.full_name,
          'email': user.email,
          'phone': user.phone,
          'address': user.address,
          'emergency_numbers': user.emergency_numbers,
          'dob': user.dob,
          'gender': user.gender,
          'password': user.password
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        trustPhone = user.emergency_numbers!;
        return true;
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while updating profile: $e');
      rethrow;
    }
  }

  // Fetch posts
  Future<List<Post>> fetchPosts() async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Authentication token is missing. Please log in again.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while fetching posts: $e');
      rethrow;
    }
  }

  // Fetch all posts
  Future<List<Post>> fetchAllPosts() async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Authentication token is missing. Please log in again.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/posts/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while fetching posts: $e');
      rethrow;
    }
  }

  // Toggle like on a post
  Future<Post> toggleLike(int postId) async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Authentication token is missing');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/likes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return Post.fromJson(responseData);
      } else {
        throw Exception('Failed to toggle like: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  // Add comment to a post
  Future<Comment> addComment(int postId, String content) async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Authentication token is missing. Please log in again.');
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (!decodedToken.containsKey('id')) {
        throw Exception("Token doesn't contain user ID!");
      }

      String userEmail = '';
      try {
        final userProfile = await getUserProfile();
        if (userProfile != null) {
          userEmail = userProfile.email;
        }
      } catch (e) {
        print('Could not get user profile: $e');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          'userId': decodedToken['id'],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['userEmail'] == null || responseData['userEmail'] == '') {
          responseData['userEmail'] = userEmail.isNotEmpty ? userEmail : 'user@example.com';
        }

        if (responseData['id'] == null) responseData['id'] = 0;
        if (responseData['postId'] == null) responseData['postId'] = postId;
        if (responseData['userId'] == null) {
          responseData['userId'] = int.tryParse(decodedToken['id'].toString()) ?? 0;
        }

        if (responseData['content'] == null || responseData['content'] == '') {
          responseData['content'] = content;
        }

        if (responseData['createdAt'] == null || responseData['createdAt'] == '') {
          responseData['createdAt'] = DateTime.now().toIso8601String();
        }

        return Comment.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again');
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('Error while adding comment: $e');
      rethrow;
    }
  }

  // New: Update comment
  Future<Comment> updateComment(int postId, int commentId, String content) async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Authentication token is missing. Please log in again.');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/posts/$postId/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return Comment.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again');
      } else {
        throw Exception('Failed to update comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while updating comment: $e');
      rethrow;
    }
  }

  // New: Delete comment
  Future<void> deleteComment(int commentId) async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Authentication token is missing. Please log in again.');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/posts/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while deleting comment: $e');
      rethrow;
    }
  }

  // Fetch user by ID
  Future<UserNormal?> getUserById(int userId) async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) {
        throw Exception("No token available, please log in again.");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return UserNormal.fromJson(responseData['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again');
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while fetching user: $e');
      rethrow;
    }
  }

  // Fetch user name
  Future<String> getUserName() async {
    try {
      UserNormal? user = await getUserProfile();
      return user?.full_name ?? 'Unknown User';
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
  }

  // Delete post
  Future<void> deletePost(int postId) async {
    final String? token = await AuthService().getToken(); // Fetch the Bearer token

    final response = await http.delete(
      Uri.parse('$baseUrl/posts/$postId'), // Adjust the URL if needed
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete post');
    }
  }

  // Fetch comments for a post
  Future<List<Comment>> getComments(int postId) async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Authentication token is missing. Please log in again.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((comment) => Comment.fromJson(comment)).toList();
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while fetching comments: $e');
      rethrow;
    }
  }
}