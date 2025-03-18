import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  final LatLng defaultLocation = const LatLng(15.994179, 108.201885); // Đà Nẵng
  LatLng? _currentPosition; // Vị trí người dùng
  final TextEditingController _searchController = TextEditingController();
  File? _capturedImage;
  BitmapDescriptor? _customMarkerIcon;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      print("❌ Quyền vị trí bị từ chối!");
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ Dịch vụ vị trí chưa bật!");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    if (mapController != null) {
      mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition!, zoom: 14.0),
      ));
    }
  }

  Future<void> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      File imageFile = File(image.path);
      setState(() {
        _capturedImage = imageFile;
      });

      await _setCustomMarkerIcon(imageFile);
    }
  }

  Future<void> _setCustomMarkerIcon(File imageFile) async {
    // Đọc dữ liệu ảnh và nén xuống kích thước nhỏ hơn
    List<int> compressedBytes = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      quality: 50, // Giảm chất lượng ảnh (0-100)
      minWidth: 100, // Giới hạn chiều rộng tối đa
      minHeight: 100, // Giới hạn chiều cao tối đa
    ) ?? [];

    if (compressedBytes.isNotEmpty) {
      final Uint8List uint8List = Uint8List.fromList(compressedBytes);
      final BitmapDescriptor bitmap = BitmapDescriptor.fromBytes(uint8List);

      setState(() {
        _customMarkerIcon = bitmap;
      });
    }
  }

  Future<List<String>> _searchPlaces(String query) async {
    try {
      print("🔍 Đang tìm kiếm địa điểm: $query");
      List<Location> locations = await locationFromAddress(query);
      return locations.map((loc) => '${loc.latitude}, ${loc.longitude}').toList();
    } catch (e, stacktrace) {
      print("🔴 Lỗi tìm kiếm địa điểm: $e");
      print(stacktrace);
      return [];
    }
  }

  void _goToLocation(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location loc = locations.first;
        LatLng newPosition = LatLng(loc.latitude, loc.longitude);

        setState(() {
          _currentPosition = newPosition;
        });

        if (mapController != null) {
          mapController!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: newPosition, zoom: 14.0),
          ));
        }
      }
    } catch (e) {
      print("🔴 Không thể tìm thấy địa điểm: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Itinerary'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              if (_currentPosition != null) {
                controller.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: _currentPosition!, zoom: 14.0),
                ));
              }
            },
            markers: _currentPosition != null && _customMarkerIcon != null
                ? {
              Marker(
                markerId: const MarkerId("currentLocation"),
                position: _currentPosition!,
                icon: _customMarkerIcon!,
              )
            }
                : {},
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? defaultLocation,
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // Thanh tìm kiếm
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: TypeAheadField<String>(
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: "Search for locations...",
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              suggestionsCallback: (pattern) async {
                return await _searchPlaces(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text(suggestion),
                );
              },
              onSelected: (suggestion) {
                _searchController.text = suggestion;
                _goToLocation(suggestion);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureImage,
        child: const Icon(Icons.camera_alt),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
