import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lokaloka/core/utils/apis.dart';
import 'package:http/http.dart' as http;
import 'package:lokaloka/features/auth/services/auth_services.dart';
import 'package:lokaloka/features/itinerary/models/Itinerary.dart';
import 'package:lokaloka/features/moments/screens/select_itinerary_screen.dart';

import '../../../core/utils/transfer_money.dart';
import '../../itinerary/services/itinerary_api.dart';
import '../../weather/services/LocationService.dart';

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
  final DraggableScrollableController _dragController =
      DraggableScrollableController();
  final ImagePicker _picker = ImagePicker();

  late String uploadUrl;
  bool _isExpanded = false;
  bool _isPickingImage = false;
  List<File> _selectedImages = []; // List to hold selected images
  List<String> _uploadedImageUrls = []; // List to hold uploaded image URLs
  bool isLoading = true;
  Map<String, dynamic>? selectedItinerary;
  bool _isPublishEnabled = false;
  List<LatLng> latLngLocations = [];
  String staticMapUrl = '';
  List<String> locations = [];
  static const String graphHopperApiKey =
      "087f9f85-d3ed-4565-94da-bbe55971cf88";

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
    _publishPost().then((success) {
      if (success) {
        Navigator.pop(context, true); // Trả về true nếu đã publish thành công
      }
    });
  }

  Future<void> _pickImages() async {
    if (_isPickingImage) return;

    _isPickingImage = true;

    try {
      final pickedFiles = await _picker.pickMultiImage();
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
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Token is expired or not found.')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error picking images: $e')));
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

        setState(() {
          _uploadedImageUrls.add(jsonResponse['data']);
          _checkPublishButtonStatus();
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image uploaded successfully!')));
      } else {
        final responseData = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Upload failed: ${response.statusCode} - $responseData')));
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

  String imageUrl = '';

  Future<List<Map<String, dynamic>>> getCoordinates(List<String> locations) async {
    List<Map<String, dynamic>> coordinates = [];

    for (String location in locations) {
      String url = "https://nominatim.openstreetmap.org/search?q=$location&format=json";

      try {
        final response = await Dio().get(url);
        if (response.statusCode == 200 && response.data.isNotEmpty) {
          var lat = response.data[0]["lat"];
          var lon = response.data[0]["lon"];
          coordinates.add({"lat": lat, "lon": lon});
        }
      } catch (e) {
        print("❌ Lỗi khi lấy tọa độ cho $location: $e");
      }
    }
    return coordinates;
  }

  Future<void> _openItinerarySelector() async {
    final itinerary = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectItineraryScreen()),
    );

    if (itinerary != null) {
      List<String> locationNames = [];

      if (itinerary.containsKey("locations") &&
          itinerary["locations"] is List) {
        locationNames = (itinerary["locations"] as List)
            .map((location) => location["name"].toString())
            .toList();
      }

      final coordinates = await getCoordinates(locationNames);

      String? address = itinerary['address'];
      print("📌 Địa chỉ: $address");
      print("📌 Danh sách địa điểm: $locationNames");

      Future<String> getRouteImageUrl(List<Map<String, dynamic>> coordinates) async {
        if (coordinates.length < 2) {
          print("❌ Cần ít nhất 2 địa điểm để tạo tuyến đường.");
          return "";
        }

        String points = coordinates.map((c) => "${c['lon']},${c['lat']}").join(";");
        String osrmUrl = "http://router.project-osrm.org/route/v1/driving/$points?overview=full&geometries=geojson";

        try {
          final response = await Dio().get(osrmUrl);
          if (response.statusCode == 200) {
            var route = response.data["routes"][0]["geometry"]["coordinates"];
            String path = route.map((p) => "${p[1]},${p[0]}").join("|");

            // Tạo URL ảnh bản đồ với tuyến đường
            String imageUrl =
                "https://staticmap.openstreetmap.de/staticmap.php?center=${coordinates[0]['lat']},${coordinates[0]['lon']}&zoom=12&size=800x600&path=$path";

            print("📍 URL ảnh: $imageUrl");
            return imageUrl;
          }
        } catch (e) {
          print("❌ Lỗi khi lấy tuyến đường: $e");
        }
        return "";
      }

      imageUrl = await getRouteImageUrl(coordinates);

      setState(() {
        staticMapUrl = imageUrl;
        selectedItinerary = itinerary;
      });
    }
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
                        )
                      ],
                    ),
                  ],
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
                      _buildImageWidgets(),
                      // Image.network(
                      //   imageUrl,
                      //   fit: BoxFit.cover,
                      //   errorBuilder: (context, error, stackTrace) {
                      //     print("🚨 Lỗi khi tải ảnh: $error");
                      //     return Icon(Icons.error, size: 60, color: Colors.red);
                      //   },
                      // ),
                      _buildTripCard(selectedItinerary!),
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
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isPublishEnabled
                                        ? _handlePublish
                                        : null,
                                    child: Text('Public'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isPublishEnabled
                                          ? Colors.teal
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildImageWidgets() {
    if (_uploadedImageUrls.isEmpty) {
      return Container(); // No images to show
    }

    return Wrap(
      spacing: 8.0,
      children: _uploadedImageUrls.map((url) {
        return Container(
          width: 100, // Set width for the images
          height: 100, // Set height for the images
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<bool> _publishPost() async {
    String content = _contentController.text;
    Itinerary itinerary = Itinerary.fromJson(selectedItinerary!);

    if (content.isEmpty && _uploadedImageUrls.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please add some content or images.')));
      }
      return false; // Không publish thành công
    }

    String? token = await AuthService().getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Token is expired or not found.')));
      }
      return false; // Không publish thành công
    }

    List<Map<String, dynamic>> imageList = _uploadedImageUrls
        .map((url) => {
              'content': url,
            })
        .toList();

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
          'images': imageList, // Đảm bảo rằng 'images' là danh sách đối tượng
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Post published successfully!')));
          print("success create post");
        }
        return true; // Publish thành công
      } else {
        final responseData = response.body;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Failed to publish post: ${response.statusCode} - $responseData')));
        }
        return false; // Không publish thành công
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return false; // Không publish thành công
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

  Widget _buildTripCard(Map<String, dynamic> trip, {String? imageItinerary}) {
    return Padding(
      padding: const EdgeInsets.all(15),
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
                child: imageItinerary != null && imageItinerary.isNotEmpty
                    ? Image.network(imageItinerary,
                    width: 80, height: 80, fit: BoxFit.cover)
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
                        Text('${trip['init_date']} days',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(CurrencyFormatter.formatVnd(trip['price']),
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
