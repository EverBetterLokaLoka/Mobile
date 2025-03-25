import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lokaloka/globals.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/format_text.dart';
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
  String apiKey = "52dae9b3-7a54-4a17-ae46-417c34e7be4a";
  LatLng? currentLocation;
  bool isNavigating = false;
  int currentStep = 0;
  StreamSubscription<Position>? positionStream;
  BitmapDescriptor? userIcon;
  int? _selectedIndex;
  Marker? newMarker;
  List<LatLng> locations = [
    // LatLng(16.064603140719623, 108.24628558279103),
    // LatLng(16.061478074883002, 108.24141842656643),

  //   Day 2
    LatLng(16.062985208463225, 108.22979269468084),
    LatLng(16.06134812409352, 108.22966731087038),
  //   LatLng(16.061611099784958, 108.23196992178055),
  //   LatLng(16.060402112286944, 108.24339649279878),
  ];
  List<String> locationNames = [
    // "My Khe BEACH",
    // "GỐM Garden Coffee",

    // day 2
    "Carp Transforming into Dragon Statue"
    "Dragon Bridge"
    // "Son Tra Night Market"
    // "Ms. Lien's 5-star restaurant"
  ];
  bool isLoading = false;
  bool isPopupShown = false;
  List<String> waypoints = [
    "waypoint 1",
    "waypoint 2",
    "waypoint 3",
    "arrive at destination"
  ];
  List<bool> waypointCompleted = [];
  Set<Polyline> completedPolylines = {};
  Set<Polyline> upcomingPolylines = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    waypointCompleted = List<bool>.filled(locations.length, false);
    waypointCompleted[0] = true;
    completedPolylines.clear();
    upcomingPolylines.clear();
    // locations = widget.locations;
    // locationNames = widget.locationNames;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoading = true);
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
        locationNames.insert(0, "Current location");
        waypointCompleted = List<bool>.filled(locations.length, false);
        waypointCompleted[0] = true;
      }
    });

    await _fetchRoute(); // Fetch lộ trình từ vị trí hiện tại đến địa điểm 1
    setState(() => isLoading = false);
  }

  Future<void> _fetchRoute() async {
    if (currentLocation == null || currentStep >= locations.length - 1) return;

    List<LatLng> routeLocations = [
      currentLocation!,
      locations[currentStep + 1],
    ];

    var result =
        await NavigationApi().getRouteFromGraphHopper(locations, apiKey);
    List<LatLng> routePoints = result["route"];
    List<String> instructions = result["instructions"];

    if (routePoints.isNotEmpty) {
      setState(() {
        upcomingPolylines.clear();
        upcomingPolylines.add(Polyline(
          polylineId: PolylineId("upcoming_route_${currentStep + 1}"),
          points: routePoints,
          color: Colors.blue,
          width: 4,
        ));
        _instructions = instructions;
      });
    }
  }

  void _startNavigation() {
    if (isNavigating) return;

    setState(() {
      isNavigating = true;
      currentStep = 0; // Bắt đầu từ vị trí hiện tại đến địa điểm 1
    });

    if (currentLocation != null) {
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation!, 18),
      );
    }

    _navigateToNextWaypoint();
  }

  void _navigateToNextWaypoint() {
    if (currentStep >= locations.length - 1) {
      _stopNavigation(); // Đã đến đích cuối, dừng lại
      return;
    }

    _fetchRoute(); // Fetch lộ trình đến điểm tiếp theo

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((Position position) async {
      if (!isNavigating) return;

      LatLng newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        currentLocation = newPosition;
        userMarker = Marker(
          markerId: const MarkerId("user_location"),
          position: newPosition,
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: const InfoWindow(title: "Your location"),
        );
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, 18),
      );

      // Kiểm tra khoảng cách đến điểm tiếp theo
      double distanceToNextWaypoint = Geolocator.distanceBetween(
        newPosition.latitude,
        newPosition.longitude,
        locations[currentStep + 1].latitude,
        locations[currentStep + 1].longitude,
      );

      if (distanceToNextWaypoint < 10 && !waypointCompleted[currentStep + 1]) {
        setState(() {
          waypointCompleted[currentStep + 1] = true;

          if (upcomingPolylines.isNotEmpty) {
            Polyline completedRoute = upcomingPolylines.first.copyWith(
              colorParam: Colors.grey.withOpacity(0.3), // Màu xám nhạt cho route cũ
              widthParam: 2,
            );
            completedPolylines.add(completedRoute);
            upcomingPolylines.clear(); // Xóa route sắp đi cũ
          }
        });

        positionStream?.pause(); // Tạm dừng stream khi đến nơi
        _showWaypointPopup(context, currentStep + 1);

        // Nếu chưa phải đích cuối, tăng currentStep và fetch lộ trình mới
        if (currentStep < locations.length - 2) {
          setState(() {
            currentStep++;
            _fetchRoute();//Kiem tra ky lai neu khong duoc thi xoa dong nay .-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
          });
          _navigateToNextWaypoint(); // Tiếp tục đến điểm tiếp theo
        } else if (currentStep == locations.length - 2) {
          if (!isPopupShown) {
            isPopupShown = true;
            _showCompletionPopup(context);
          }
        }
      }
    });
  }

  void _showWaypointPopup(BuildContext context, int waypointIndex) {
    showDialog(
      context: context,
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
                "Arrived ${locationNames[waypointIndex]}!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "You have completed the destination ${waypointIndex}/${locations.length - 1}.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  positionStream?.resume();
                },
                child: Text("Continue"),
              ),
            ],
          ),
        );
      },
    );
  }
  void _stopNavigation() {
    positionStream?.cancel();
    setState(() {
      isNavigating = false;
    });
  }

  void _setMapBounds() {
    if (locations.length < 2) return;

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
                      isPopupShown = false;
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
                      isPopupShown = false;
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
        builder: (context) => MomentsScreen(),
      ),
    );
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _stopNavigation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(formatTitle(widget.title!) ?? 'Travel Itinerary'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                "/my-trip",
                    (route) => false,
              );
            }
        ),
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

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (locations.isNotEmpty && mapController != null) {
                            Future.delayed(Duration(milliseconds: 500), () {
                              final firstLocation = locations[1];
                              final markerId =
                                  MarkerId(firstLocation.toString());
                              mapController!.showMarkerInfoWindow(markerId);
                            });
                          }
                        });
                      },
                      mapType: MapType.terrain,
                      initialCameraPosition: CameraPosition(
                        target: locations.isNotEmpty
                            ? locations[0]
                            : const LatLng(0, 0),
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
                              title:
                                  "Location ${index + 1}: ${locationNames[index]}",
                              snippet:
                                  "Lat: ${position.latitude}, Lng: ${position.longitude}",
                            ),
                          );
                        }).toSet(),
                      },
                      polylines: {...completedPolylines, ...upcomingPolylines},
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                    ),
                    Positioned(
                      bottom: 283,
                      right: 7,
                      child: GestureDetector(
                        onTap: () async {
                          final phoneNumber = "tel:$trustPhone";
                          if (await canLaunchUrl(Uri.parse(phoneNumber))) {
                            await launchUrl(Uri.parse(phoneNumber));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Cannot make calls."),
                                duration: Duration(seconds: 3),
                              ),
                            );
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
                      bottom: 235,
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
                          itemCount: locations.length,
                          itemBuilder: (context, index) {
                            bool isCompleted = waypointCompleted[index];
                            return AnimatedOpacity(
                              duration: Duration(milliseconds: 300),
                              opacity: index <= currentStep + 1 ? 1.0 : 0.3,
                              child: ListTile(
                                leading: Icon(
                                  isCompleted ? Icons.check_circle : Icons.directions,
                                  color: isCompleted ? Colors.green : Colors.grey,
                                ),
                                title: Text(
                                  index == currentStep + 1 && !isCompleted
                                      ? "**${locationNames[index]}** (Is coming...)"
                                      : locationNames[index],
                                  style: TextStyle(
                                    fontWeight: index == currentStep + 1 && !isCompleted
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  isCompleted ? "Completed" : "Not yet at the location",
                                  style: TextStyle(color: isCompleted ? Colors.green : Colors.grey),
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
