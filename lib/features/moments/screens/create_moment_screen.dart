import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lokaloka/core/utils/apis.dart';
import 'package:http/http.dart' as http;
import 'package:lokaloka/features/auth/services/auth_services.dart';
import 'package:lokaloka/features/itinerary/models/Itinerary.dart';
import 'package:lokaloka/features/moments/screens/select_itinerary_screen.dart';

import '../../itinerary/services/itinerary_api.dart';

class CreateMomentScreen extends StatefulWidget {
  final String userName;
  final String userLocation;
  final String userAvatar;

  const CreateMomentScreen({
    Key? key,
    required this.userName,
    required this.userLocation,
    required this.userAvatar,
  }) : super(key: key);

  @override
  _CreateMomentScreenState createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  final TextEditingController _contentController = TextEditingController();
  final DraggableScrollableController _dragController = DraggableScrollableController();
  final ImagePicker _picker = ImagePicker();

  late String uploadUrl;
  bool _isExpanded = false;
  bool _isPickingImage = false;
  List<File> _selectedImages = []; // List to hold selected images
  List<String> _uploadedImageUrls = []; // List to hold uploaded image URLs
  bool isLoading = true;
  Map<String, dynamic>? selectedItinerary;

  @override
  void initState() {
    super.initState();
    uploadUrl = "${ApiService().baseUrl}/upload";
    _dragController.addListener(_onDragUpdate);
  }

  void _onDragUpdate() {
    if (_dragController.size > 0.2 && !_isExpanded) {
      setState(() => _isExpanded = true);
    } else if (_dragController.size <= 0.2 && _isExpanded) {
      setState(() => _isExpanded = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _dragController.removeListener(_onDragUpdate);
    _dragController.dispose();
    super.dispose();
  }

  void _handlePublish() {
    _publishPost();
    Navigator.pop(context);
  }

  Future<void> _pickImages() async {
    if (_isPickingImage) return;

    _isPickingImage = true;

    try {
      final pickedFiles = await _picker.pickMultiImage(); // Allow selection of multiple images
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        for (var pickedFile in pickedFiles) {
          setState(() {
            _selectedImages.add(File(pickedFile.path));
          });
        }

        String? token = await AuthService().getToken();
        if (token != null) {
          for (var image in _selectedImages) {
            await _uploadImage(token, image);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Token is expired or not found.')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _uploadImage(String token, File image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        print('Upload successful: ${jsonResponse['data']}');

        // Add the uploaded image URL to the list
        setState(() {
          _uploadedImageUrls.add(jsonResponse['data']); // Add URL to list
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image uploaded successfully!')));
      } else {
        final responseData = await response.stream.bytesToString();
        print('Upload failed with status: ${response.statusCode}');
        print('Response body: $responseData');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${response.statusCode} - $responseData')));
      }
    } catch (e) {
      print('Error during upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _toggleFooter() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _dragController.animateTo(
          0.5,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _dragController.animateTo(
          0.1,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _openItinerarySelector() async {
    final itinerary = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectItineraryScreen()),
    );

    if (itinerary != null) {
      setState(() {
        selectedItinerary = itinerary;
      });
    }
    print(itinerary['id']);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Moment'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // User info section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(widget.userAvatar),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.userLocation,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content input area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Share your moment to connect with others...',
                          border: InputBorder.none,
                        ),
                      ),

                      // Show uploaded images
                      _buildImageWidgets(),
                      if (selectedItinerary != null) ...[
                        SizedBox(height: 16),
                        _buildTripCard(selectedItinerary!),
                      ],
                    ],
                  ),
                ),
              ),

              // Spacer to make room for the draggable sheet
              SizedBox(height: 120),
            ],
          ),

          // Toggle button for the footer
          Positioned(
            right: 16,
            bottom: _isExpanded
                ? MediaQuery.of(context).size.height * 0.5 - 30
                : MediaQuery.of(context).size.height * 0.1 - 30,
            child: FloatingActionButton(
              mini: true,
              onPressed: _toggleFooter,
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                color: Colors.white,
              ),
            ),
          ),

          // Draggable bottom sheet for actions
          DraggableScrollableSheet(
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: 0.5,
            controller: _dragController,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle for dragging
                    GestureDetector(
                      onTap: _toggleFooter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Scrollable content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          // Action buttons
                          _buildActionButton(
                            icon: Icons.image,
                            label: 'Choose images', // changed to plural
                            color: Colors.blue,
                            onTap: _pickImages, // Call the new method here
                          ),
                          _buildActionButton(
                            icon: Icons.emoji_emotions,
                            label: 'Emotion/activity',
                            color: Colors.amber,
                            onTap: () {
                              // TODO: Implement emotion picker
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.people,
                            label: 'Tag friends',
                            color: Colors.blue,
                            onTap: () {
                              // TODO: Implement friend tagging
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.map,
                            label: 'Share your itinerary',
                            color: Colors.red,
                            onTap: () async {
                              await _openItinerarySelector();
                            },
                          ),

                          // Bottom action buttons
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _handlePublish,
                                    child: Text('Public'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Method to build widgets for the uploaded images
  Widget _buildImageWidgets() {
    int imageCount = _uploadedImageUrls.length;

    if (imageCount == 0) {
      return Container(); // No images to show
    } else if (imageCount == 1) {
      // Show one image
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Image.network(
          _uploadedImageUrls[0],
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    } else if (imageCount == 2) {
      // Show two images
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Image.network(
                _uploadedImageUrls[0],
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 8), // Space between images
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Image.network(
                _uploadedImageUrls[1],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      );
    } else if (imageCount >= 3) {
      // Show three or more images
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.network(
                    _uploadedImageUrls[0],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.network(
                    _uploadedImageUrls[1],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Image.network(
              _uploadedImageUrls[2],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        ],
      );
    }

    return Container(); // Default case; return an empty container
  }
  Future<void> _publishPost() async {
    String content = _contentController.text;
    Itinerary itinerary = Itinerary.fromJson(selectedItinerary!);

    // Kiểm tra xem người dùng có nhập nội dung hoặc tải ảnh lên không
    if (content.isEmpty && _uploadedImageUrls.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please add some content or images.')));
      }
      return;
    }

    String? token = await AuthService().getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Token is expired or not found.')));
      }
      return;
    }

    // Dữ liệu gửi lên server
    List<Map<String, dynamic>> imageList = _uploadedImageUrls.map((url) => {
      'content': url,
      // Có thể thêm các trường khác nếu cần thiết, như userId, postId, v.v.
    }).toList();

    // Bắt đầu gửi yêu cầu đến server
    try {
      final response = await http.post(
        Uri.parse('${ApiService().baseUrl}/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          'itinerary': itinerary,
          'images': imageList,  // Đảm bảo rằng 'images' là danh sách đối tượng
        }),
      );

      // Kiểm tra phản hồi
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post published successfully!')));
        }
        Navigator.pop(context); // Quay lại màn hình trước
      } else {
        final responseData = response.body;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to publish post: ${response.statusCode} - $responseData')));
        }
      }
    } catch (e) {
      print('Error during publish: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: trip['locations'] != null && trip['locations'].isNotEmpty
                    ? Image.network(
                  trip['locations'].firstWhere(
                        (location) => location['image'] != null && location['image'].isNotEmpty,
                    orElse: () => {'image': ''},
                  )['image'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300], // Placeholder
                  child: Icon(Icons.image, color: Colors.grey),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip['title'] ?? 'Unknown Title',
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('2 days 1 night',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(trip['price']?.toString() ?? 'N/A',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('${trip['locations']?.length ?? 0} Destinations',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}