import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lokaloka/core/utils/apis.dart';
import 'package:http/http.dart' as http;
import 'package:lokaloka/features/auth/services/auth_services.dart';
import 'package:lokaloka/features/itinerary/models/Itinerary.dart';
import 'package:lokaloka/features/moments/screens/moment_screen.dart';
import 'package:lokaloka/features/moments/screens/select_itinerary_screen.dart';

import '../models/Feeling.dart';

class CreateMomentScreen extends StatefulWidget {
  final String userName;
  final String userLocation;
  final String userAvatar;
  final Map<String, dynamic>? shareItinerary;
  final String? type;

  const CreateMomentScreen(
      {Key? key,
      required this.userName,
      required this.userLocation,
      required this.userAvatar,
      this.shareItinerary,
      this.type})
      : super(key: key);

  @override
  _CreateMomentScreenState createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  final TextEditingController _contentController = TextEditingController();
  final DraggableScrollableController _dragController =
      DraggableScrollableController();
  final ImagePicker _picker = ImagePicker();

  late String uploadUrl;
  bool _isExpanded = false;
  bool _isPickingImage = false;
  bool _isUploading = false;
  List<File> _selectedImages = []; // List to hold selected images
  List<String> _uploadedImageUrls = []; // List to hold uploaded image URLs
  bool isLoading = true;
  Map<String, dynamic>? selectedItinerary;
  bool _isPublishEnabled = false;
  String? staticMapUrl;
  bool _isLoading = false;
  bool _isPublishing = false;
  Feeling? selectedFeeling;
  late ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    uploadUrl = "${ApiService().baseUrl}/upload";
    _dragController.addListener(_onDragUpdate);
    _contentController.addListener(_checkPublishButtonStatus);
  }

  void _onDragUpdate() {
    if (_dragController.size > 0.2 && !_isExpanded) {
      setState(() => _isExpanded = true);
    } else if (_dragController.size <= 0.2 && _isExpanded) {
      setState(() => _isExpanded = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _contentController.removeListener(_checkPublishButtonStatus);
    _contentController.dispose();
    _dragController.removeListener(_onDragUpdate);
    _dragController.dispose();
    super.dispose();
  }

  void _checkPublishButtonStatus() {
    setState(() {
      _isPublishEnabled =
          _contentController.text.isNotEmpty || _uploadedImageUrls.isNotEmpty;
    });
  }

  void _handlePublish() {
    if (_isPublishing) return;

    setState(() {
      _isPublishing = true;
    });

    _publishPost().then((success) {
      if (success) {
        if (widget.type == "share") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MomentsScreen()),
            (route) => route.settings.name == "/home",
          );
        } else {
          Navigator.pop(context, true);
        }
      }
      setState(() {
        _isPublishing = false;
      });
    });
  }

  Future<void> _pickImages() async {
    if (_isPickingImage) return;

    _isPickingImage = true;
    _isUploading = true;

    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          print("aaaaa");
          _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
        });

        String? token = await AuthService().getToken();
        if (token != null) {
          for (var image in _selectedImages) {
            await _uploadImage(token, image);
          }
        } else {
          _scaffoldMessenger?.showSnackBar(
            SnackBar(content: Text("Token is expired or not found.")),
          );
        }
      }
    } catch (e) {
      _scaffoldMessenger?.showSnackBar(
        SnackBar(content: Text("Error picking images: $e.")),
      );
    } finally {
      _isPickingImage = false;
      _isUploading = false;
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

        setState(() {
          _uploadedImageUrls.add(jsonResponse['data']);
          _checkPublishButtonStatus();
        });

        _scaffoldMessenger?.showSnackBar(
          SnackBar(content: Text("Image uploaded successfully!")),
        );
      } else {
        final responseData = await response.stream.bytesToString();
        _scaffoldMessenger?.showSnackBar(
          SnackBar(
              content: Text(
                  "Upload failed: ${response.statusCode} - $responseData")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
      print("Itinerary selected: ${itinerary['id']}");
    }
  }

  void _showFeelingSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(10),
          child: Wrap(
            children: feelings.map((feeling) {
              return ListTile(
                leading: Text(feeling.emoji, style: TextStyle(fontSize: 24)),
                title: Text("Feeling ${feeling.name}"),
                onTap: () {
                  setState(() {
                    selectedFeeling = feeling;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
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
      body: _isUploading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double availableWidth = constraints.maxWidth - 100;

                          TextPainter textPainter = TextPainter(
                            text: TextSpan(
                              text: "is feeling ${selectedFeeling?.name ?? ''}",
                              style: TextStyle(fontSize: 14),
                            ),
                            maxLines: 1,
                            textDirection: TextDirection.ltr,
                          )..layout(maxWidth: availableWidth);

                          bool shouldBreakLine = textPainter.didExceedMaxLines;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(widget.userAvatar!),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${widget.userName}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (selectedFeeling != null)
                                      shouldBreakLine
                                          ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                "is feeling ${selectedFeeling!.name} ",
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              Text(
                                                selectedFeeling!.emoji,
                                                style: TextStyle(fontSize: 20),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                          : Row(
                                        children: [
                                          SizedBox(width: 4),
                                          Text(
                                            "is feeling ${selectedFeeling!.name} ",
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            selectedFeeling!.emoji,
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _contentController,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText:
                                    'Share your moment to connect with others...',
                                border: InputBorder.none,
                              ),
                            ),
                            if (selectedItinerary != null) ...[
                              SizedBox(height: 5),
                              _buildTripCard(selectedItinerary!),
                            ] else if (widget.shareItinerary != null) ...[
                              SizedBox(height: 5),
                              _buildTripCard(widget.shareItinerary!),
                            ],
                            _buildImageWidgets(),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 120),
                  ],
                ),
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
                      _isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: Colors.white,
                    ),
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.1,
                  minChildSize: 0.1,
                  maxChildSize: 0.5,
                  controller: _dragController,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
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
                          GestureDetector(
                            onTap: _toggleFooter,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 4.0),
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
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              padding: EdgeInsets.zero,
                              children: [
                                _buildActionButton(
                                  icon: Icons.image,
                                  label: 'Choose images',
                                  color: Colors.blue,
                                  onTap: _pickImages,
                                ),
                                _buildActionButton(
                                  icon: Icons.emoji_emotions,
                                  label: "Emotions",
                                  color: Colors.yellow,
                                  onTap: () {
                                    _showFeelingSelector(context);
                                  },
                                ),
                                // _buildActionButton(
                                //   icon: Icons.people,
                                //   label: 'Tag friends',
                                //   color: Colors.green,
                                //   onTap: () {
                                //     // TODO: Implement friend tagging
                                //   },
                                // ),
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
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Cancel'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isPublishEnabled &&
                                                  !_isPublishing
                                              ? _handlePublish
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                _isPublishEnabled &&
                                                        !_isPublishing
                                                    ? Colors.teal
                                                    : Colors.grey,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: _isPublishing
                                              ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ))
                                              : Text('Public'),
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

  Widget _buildImageWidgets() {
    if (_uploadedImageUrls.isEmpty) {
      return SizedBox();
    }

    List<String> limitedImages = _uploadedImageUrls.take(6).toList();
    bool hasMoreImages = _uploadedImageUrls.length > 6;

    return Column(
      children: [
        SizedBox(height: 5),
        if (limitedImages.length == 3)
          _buildSpecialLayout(limitedImages) // Layout đặc biệt cho 3 ảnh
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _getCrossAxisCount(_uploadedImageUrls.length),
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemCount: hasMoreImages ? 6 : limitedImages.length,
                itemBuilder: (context, index) {
                  if (index == 5 && hasMoreImages) {
                    return _buildMoreImagesOverlay(
                        limitedImages[5], _uploadedImageUrls.length - 6);
                  }
                  return _buildImageItem(limitedImages[index]);
                },
              );
            },
          ),
      ],
    );
  }

  int _getCrossAxisCount(int length) {
    if (length == 1) return 1;
    if (length == 2) return 2;
    return 3;
  }

  Widget _buildImageItem(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Center(child: Icon(Icons.image_not_supported)),
          );
        },
      ),
    );
  }

  Widget _buildMoreImagesOverlay(String imageUrl, int extraCount) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Center(child: Icon(Icons.image_not_supported)),
              );
            },
          ),
        ),
        Container(color: Colors.black54),
        Center(
          child: Text(
            '+$extraCount',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialLayout(List<String> images) {
    return Row(
      children: [
        Expanded(
          flex: 2, // Ảnh lớn chiếm 2 phần
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              images[0],
              fit: BoxFit.cover,
              height: 220, // Chiều cao cố định
            ),
          ),
        ),
        SizedBox(width: 5),
        Expanded(
          flex: 1, // Hai ảnh nhỏ chiếm 1 phần
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[1],
                    fit: BoxFit.cover,
                    width: 80,
                  ),
                ),
              ),
              SizedBox(height: 5),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[2],
                    fit: BoxFit.cover,
                    width: 80,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _publishPost() async {
    String content = _contentController.text;

    if (content.isEmpty && _uploadedImageUrls.isEmpty) {
      if (mounted) {
        _scaffoldMessenger?.showSnackBar(
          SnackBar(content: Text("Please add some content or images.")),
        );
      }
      return false;
    }

    String? token = await AuthService().getToken();
    if (token == null) {
      if (mounted) {
        _scaffoldMessenger?.showSnackBar(
          SnackBar(
              content:
                  Text("Token is expired or not found. Please log in again.")),
        );
      }
      Navigator.pushReplacementNamed(context, '/login');
      return false;
    }

    String? userId = await AuthService().getUserIdFromToken();
    if (userId == null) {
      if (mounted) {
        _scaffoldMessenger?.showSnackBar(
          SnackBar(content: Text("User ID not found in token.")),
        );
      }
      return false;
    }

    List<Map<String, dynamic>> imageList = _uploadedImageUrls
        .map((url) => {
              'content': url,
            })
        .toList();

    Map<String, dynamic> postData = {
      'content': content,
      'images': imageList,
      'emotion': selectedFeeling?.name ?? null,
      'user_id': userId,
      'title': null,
      'destroyed': false,
    };

    if (selectedItinerary != null) {
      try {
        Itinerary itinerary = Itinerary.fromJson(selectedItinerary!);
        postData['itineraryId'] = itinerary.id;
      } catch (e) {
        print('Error parsing itinerary: $e');
      }
    } else if (widget.shareItinerary != null) {
      try {
        Itinerary itinerary = Itinerary.fromJson(widget.shareItinerary!);
        postData['itineraryId'] = itinerary.id;
      } catch (e) {
        print('Error parsing itinerary: $e');
        // Tiếp tục mà không có itinerary
      }
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiService().baseUrl}/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(postData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _scaffoldMessenger?.showSnackBar(
            SnackBar(content: Text("Post published successfully!")),
          );
        }
        return true;
      } else {
        final responseData = response.body;
        if (mounted) {
          print(response.body);
          _scaffoldMessenger?.showSnackBar(
            SnackBar(
                content: Text(
                    "Failed to publish post: ${response.statusCode} - $responseData'")),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessenger?.showSnackBar(
          SnackBar(content: Text("Error publishing post: $e")),
        );
      }
      return false;
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
                        (location) =>
                            location['image'] != null &&
                            location['image'].isNotEmpty,
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
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
    );
  }
}
