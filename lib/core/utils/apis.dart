import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/auth/services/auth_services.dart';
import '../constants/url_constant.dart';

class ApiService {
  final String baseUrl = 'https://adb4-113-176-99-140.ngrok-free.app/api';

  final String imgKey = "725fa29bb10ba691adbaa03f93017c3fbb716315";

  final String locationUrl = 'https://provinces.open-api.vn/api/p';

  String? token = "";

  Future<http.Response> request({
    required String path,
    required String method,
    required String typeUrl,
    required String currentPath,
    Map<String, dynamic>? data,
  }) async {
    Uri url;
    if (typeUrl == UrlConstant().baseUrl) {
      if (currentPath != "/login" && currentPath != "/sign-up") {
        token = await AuthService().getToken();
      }
      url = Uri.parse('$baseUrl$path');
    } else if (typeUrl == UrlConstant().locationUrl) {
      token = "";
      url = Uri.parse('$locationUrl$path');
    } else {
      throw Exception('Invalid URL type: $typeUrl');
    }

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: _defaultHeaders(token!));
        break;
      case 'POST':
        response = await http.post(url,
            headers: _defaultHeaders(token!), body: jsonEncode(data));
        break;
      case 'PUT':
        response = await http.put(url,
            headers: _defaultHeaders(token!), body: jsonEncode(data));
        break;
      case 'PATCH':
        response = await http.patch(url,
            headers: _defaultHeaders(token!), body: jsonEncode(data));
        break;
      case 'DELETE':
        response = await http.delete(url,
            headers: _defaultHeaders(token!), body: jsonEncode(data));
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    print(token);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      throw Exception('Failed to load data: ${response.body}');
    }

    // Trả về phản hồi ngay cả khi gặp lỗi
    return response;
  }
  Future<http.Response> get(String path) async {
    return await request(
      path: path,
      method: 'GET',
      typeUrl: UrlConstant().baseUrl,
      currentPath: path, // hoặc path của bạn có thể là một tham số khác
    );
  }
  Map<String, String> _defaultHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      "Authorization": "Bearer $token",
    };
  }

  Future<String> fetchImageUrl(String province) async {
    var headers = {
      'X-API-KEY': imgKey,
      'Content-Type': 'application/json'
    };

    var url = Uri.parse('https://google.serper.dev/images');

    var body = json.encode({"q": "$province city", "location": "Vietnam", "gl": "vn"});

    try {
      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        if (jsonResponse['images'] != null &&
            jsonResponse['images'].isNotEmpty) {
          return jsonResponse['images'][0]['imageUrl'];
        }
        return "";
      } else {
        print('Error: ${response.reasonPhrase}');
        return "";
      }
    } catch (e) {
      print('Exception: $e');
      return "";
    }
  }
}
