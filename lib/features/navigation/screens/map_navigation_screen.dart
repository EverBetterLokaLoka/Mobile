import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lokaloka/globals.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/styles/colors.dart';
import '../../itinerary/widgets/itinerary-app_bar.dart';
import '../../moments/screens/moment_screen.dart';
import '../services/navigation_api.dart';

class MapNavigationScreen extends StatefulWidget {
  String? title = "";
  List<LatLng> locations = [];
  List<String> locationNames = [];

  MapNavigationScreen(
      {super.key,
      required this.title,
      required this.locations,
      required this.locationNames});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapNavigationScreen> {
  GoogleMapController? mapController;
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  Marker? userMarker;
  List<String> _instructions = [];
  String apiKey = "087f9f85-d3ed-4565-94da-bbe55971cf88";
  LatLng? currentLocation;
  bool isNavigating = false;
  int currentStep = 0;
  StreamSubscription<Position>? positionStream;
  File? _capturedImage;
  BitmapDescriptor? _customMarkerIcon;
  BitmapDescriptor? userIcon;
  Map<String, File?> _locationImages = {};
  File? imageFile;
  int? _selectedIndex;
  Marker? newMarker;
  List<LatLng> locations = [];
  List<String> locationNames = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    locations = widget.locations;
    locationNames = widget.locationNames;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("GPS chưa bật!");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Người dùng từ chối cấp quyền vị trí!");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Quyền vị trí bị từ chối vĩnh viễn!");
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    LatLng userLocation = LatLng(position.latitude, position.longitude);

    setState(() {
      currentLocation = userLocation;
      if (!locations.contains(userLocation)) {
        locations.insert(0, userLocation);
        locationNames.insert(0, "Vị trí hiện tại");
      }
    });

    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    if (currentLocation == null) return;

    var result =
        await NavigationApi().getRouteFromGraphHopper(locations, apiKey);
    List<LatLng> routePoints = result["route"];
    List<String> instructions = result["instructions"];

    if (routePoints.isNotEmpty) {
      setState(() {
        polylines.add(Polyline(
          polylineId: PolylineId("route"),
          points: routePoints,
          color: Colors.blue,
          width: 2,
        ));
        _instructions = instructions;
      });
    }
  }

  void _startNavigation() {
    if (isNavigating) return;

    setState(() {
      isNavigating = true;
      currentStep = 0;
    });

    if (currentLocation != null) {
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation!, 24),
      );
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best, distanceFilter: 5),
    ).listen((Position position) {
      if (!isNavigating) return;

      LatLng newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        currentLocation = newPosition;

        userMarker = Marker(
          markerId: const MarkerId("user_location"),
          position: newPosition,
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: const InfoWindow(title: "Vị trí của bạn"),
        );
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, 18),
      );
    });
  }

  void _stopNavigation() {
    positionStream?.cancel();
    setState(() {
      isNavigating = false;
    });
  }

  void _setMapBounds() {
    if (locations.isEmpty || mapController == null) return;

    LatLngBounds bounds = _getBounds(locations);

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (LatLng point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _captureImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        imageFile = File('assets/capture');
        _locationImages[locations[index].toString()] = imageFile;
        imageFile = File(image.path);
        print("Ảnh đã lưu cho vị trí ${locations[index]}: ${imageFile?.path}");
        print("imageFile$imageFile");
        print("_locationImages${_locationImages[locations[index].toString()]}");
        _updateMarkerWithImage(_selectedIndex!, imageFile!);
      });
    }
  }

  Future<void> _askCapture(int index) async {
    bool? shouldCapture = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Chụp ảnh?"),
          content:
              const Text("Bạn có muốn chụp ảnh để lưu tại địa điểm này không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Hủy"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Chụp ảnh"),
            ),
          ],
        );
      },
    );

    if (shouldCapture == true) {
      await _captureImage(index);
      setState(() {});
    }
  }

  Future<void> _updateMarkerWithImage(int index, File imageFile) async {
    List<int> compressedBytes = await FlutterImageCompress.compressWithFile(
          imageFile.absolute.path,
          quality: 50,
          minWidth: 400,
          minHeight: 400,
        ) ??
        [];

    if (compressedBytes.isNotEmpty) {
      final Uint8List uint8List = Uint8List.fromList(compressedBytes);
      final BitmapDescriptor bitmap = BitmapDescriptor.fromBytes(uint8List);

      newMarker = Marker(
        markerId: MarkerId(locations[index].toString()),
        position: locations[index],
        icon: bitmap,
        infoWindow: InfoWindow(
          title: locationNames[index],
          snippet:
              "Vĩ độ: ${locations[index].latitude}, Kinh độ: ${locations[index].longitude}",
        ),
      );

      setState(() {
        markers
            .removeWhere((m) => m.markerId.value == newMarker!.markerId.value);
        markers.add(newMarker!);
      });

      print("Danh sách markers sau khi cập nhật: $markers");

      print("Đã cập nhật marker có ảnh cho vị trí ${locations[index]}.");
    } else {
      print("Lỗi khi nén ảnh!");
    }
    setState(() {});
  }

  void _showCompletionPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          contentPadding: EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Congratulations on completing your journey!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "After completing your trip, would you like to share your amazing experience?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[500],
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      _shareExperience();
                      Navigator.of(context).pop();
                    },
                    child: Text("Share"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareExperience() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        MomentsScreen(),
      ),
    );
    print("User clicked Share!");
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ItineraryAppBar(
        titleText: widget.title ?? "Navigation Map",
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 7,
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) {
                        mapController = controller;
                        _setMapBounds();
                      },
                      mapType: MapType.terrain,
                      initialCameraPosition: CameraPosition(
                        target: locations[0],
                        zoom: 12,
                      ),
                      markers: {
                        ...locations.asMap().entries.map((entry) {
                          int index = entry.key;
                          LatLng position = entry.value;
                          return Marker(
                            markerId: MarkerId(position.toString()),
                            position: position,
                            infoWindow: InfoWindow(
                              title: locationNames[index],
                              snippet:
                                  "Vĩ độ: ${position.latitude}, Kinh độ: ${position.longitude}",
                            ),
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                          );
                        }).toSet(),
                      },
                      polylines: polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                    ),
                    Positioned(
                      bottom: 260,
                      right: 7,
                      child: GestureDetector(
                        onTap: () async {
                          final phoneNumber = "tel:$trustPhone";
                          if (await canLaunchUrl(Uri.parse(phoneNumber))) {
                            await launchUrl(Uri.parse(phoneNumber));
                          } else {
                            print("Không thể gọi điện");
                          }
                        },
                        child: Image.asset(
                          'assets/images/sos.png',
                          width: 45,
                          height: 45,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 215,
                      right: 7,
                      child: FloatingActionButton(
                        backgroundColor: Colors.white,
                        mini: true,
                        onPressed: () {
                          mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(currentLocation!, 18),
                          );
                        },
                        child: Icon(Icons.my_location, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Container(width: 120, height: 3, color: Colors.black),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _instructions.length,
                          itemBuilder: (context, index) {
                            String instruction =
                                _instructions[index].toLowerCase();

                            IconData getIcon(String instruction) {
                              if (instruction.contains("turn right")) {
                                return Icons.turn_right;
                              } else if (instruction.contains("turn left")) {
                                return Icons.turn_left;
                              } else if (instruction.contains("keep left")) {
                                return Icons.arrow_left;
                              } else if (instruction.contains("keep right")) {
                                return Icons.arrow_right;
                              } else if (instruction.contains("turn sharp")) {
                                return Icons.turn_slight_right;
                              } else if (instruction.contains("continue")) {
                                return Icons.straight;
                              } else if (instruction
                                  .contains("at roundabout")) {
                                return Icons.roundabout_right;
                              } else if (instruction
                                  .contains("arrive at destination")) {
                                return Icons.flag;
                              } else {
                                return Icons.directions;
                              }
                            }

                            if (index == currentStep &&
                                instruction.contains("arrive at destination")) {
                              Future.delayed(Duration(milliseconds: 300), () {
                                _showCompletionPopup(context);
                              });
                            }
                            return ListTile(
                              leading: Icon(getIcon(instruction)),
                              title: Text(
                                index == currentStep
                                    ? "**${_instructions[index]}** (Going...)"
                                    : _instructions[index],
                                style: TextStyle(
                                  fontWeight: index == currentStep
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: isNavigating ? null : _startNavigation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              minimumSize: const Size(100, 36),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Start",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.play_arrow,
                                    color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _stopNavigation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              minimumSize: const Size(100, 36),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Stop",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.stop,
                                    color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
