import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lokaloka/core/utils/apis.dart';
import 'package:lokaloka/features/auth/models/user.dart';
import 'package:lokaloka/features/auth/services/auth_services.dart';
import 'dart:convert';

class ProfileHeader extends StatefulWidget {
  final UserNormal user;

  const ProfileHeader({Key? key, required this.user}) : super(key: key);

  @override
  _ProfileHeaderState createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  File? _imageFile;
  String? _avatarUrl;
  final String baseUrl = ApiService().baseUrl;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.user.avatar;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      await _uploadImage(_imageFile!);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) throw Exception("No token available");

      final uri = Uri.parse('$baseUrl/upload');
      var request = http.MultipartRequest('POST', uri)
        ..headers["Authorization"] = "Bearer $token"
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);

        // Log the full response to verify its structure
        print("API Response: $jsonResponse");

        // Handle both types of responses
        if (jsonResponse['data'] != null) {
          // If 'data' is a string (image URL)
          if (jsonResponse['data'] is String) {
            String imageUrl = jsonResponse['data'];
            print('Image URL: $imageUrl');  // Debug log to ensure you have the correct URL

            // Call the save API to store the image URL in the database
            await _saveAvatar(imageUrl);

            setState(() => _avatarUrl = imageUrl);
          }
          // If 'data' is a map
          else if (jsonResponse['data'] is Map) {
            String imageUrl = jsonResponse['data']['content'] ?? '';

            if (imageUrl.isNotEmpty) {
              print('Image URL: $imageUrl');  // Debug log to ensure you have the correct URL

              // Call the save API to store the image URL in the database
              await _saveAvatar(imageUrl);

              setState(() => _avatarUrl = imageUrl);
            } else {
              throw Exception('Image URL is empty in the response');
            }
          } else {
            throw Exception('Unexpected "data" type in the response');
          }
        } else {
          throw Exception('"data" field not found in the response');
        }
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _saveAvatar(String imageUrl) async {
    try {
      String? token = await AuthService().getToken();
      if (token == null) throw Exception("No token available");

      final uri = Uri.parse('$baseUrl/upload/save');
      final response = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "content": imageUrl,
        }),
      );

      if (response.statusCode == 201) {
        // Optionally handle success
        print("success");
      } else {
        throw Exception('Failed to save avatar');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error to save avatar: $e')));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10), // Thêm padding 10
      margin: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
      alignment: Alignment.center, // Căn giữa theo chiều ngang
      child: Row(
        mainAxisSize: MainAxisSize.min, // Giúp Row chỉ chiếm kích thước tối thiểu cần thiết
        crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo chiều dọc
        children: [
          Stack(
            children: [
              _buildAvatar(),
              Positioned(bottom: 0, right: 0, child: _buildCameraButton()),
            ],
          ),
          SizedBox(width: 10), // Khoảng cách giữa ảnh và text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.full_name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(widget.user.address ?? 'Address not available', style: TextStyle(color: Colors.grey)),
              Text('Joined: ${_formatDate(widget.user.created_at)}', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey[200],
      child: ClipOval(
        child: _avatarUrl != null
            ? Image.network(
          _avatarUrl!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
        )
            : Image.asset('assets/images/avt-default.png'),
      ),
    );
  }

  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(),
      child: CircleAvatar(
        radius: 15,
        backgroundColor: Colors.orange,
        child: Icon(Icons.camera_alt, size: 15, color: Colors.white),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Not available';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
