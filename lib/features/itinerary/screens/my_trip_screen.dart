import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lokaloka/core/styles/colors.dart';
import 'package:lokaloka/features/itinerary/models/Itinerary.dart';
import 'package:lokaloka/features/itinerary/screens/detail_itinerary_screen.dart';
import '../../../core/utils/apis.dart';
import '../../../globals.dart';
import '../../../widgets/app_bar_widget.dart';
import '../../../widgets/notice_widget.dart';
import '../../navigation/screens/map_navigation_screen.dart';
import '../../weather/services/LocationService.dart';
import '../services/itinerary_api.dart';

class MyTripScreen extends StatefulWidget {
  const MyTripScreen({Key? key}) : super(key: key);

  @override
  _MyTripState createState() => _MyTripState();
}

class _MyTripState extends State<MyTripScreen> {
  final ItineraryApi _itineraryService = ItineraryApi();
  List<Map<String, dynamic>> allItineraries = [];
  List<Map<String, dynamic>> filteredItineraries = [];
  bool isLoading = true;
  int selectedTab = 0;
  List<String> locationNames = [];
  List<LatLng> locations = [];

  @override
  void initState() {
    super.initState();
    _fetchItineraries();
  }

  Future<void> splitLocation(int? id, Itinerary itinerary) async {
    //Change status

    Itinerary GoItinerary = await ItineraryApi().getItineraryById(id);

    if (GoItinerary.start_date == null) {
      print("❌ Chưa có ngày bắt đầu.");
      bool? updateStatus =
          await ItineraryApi().goItineraryUpdate(id, itinerary);
      //get by id itinerary to go
      if (!updateStatus!) {
        return;
      }
      return;
    } else {
      bool? update = await ItineraryApi().updateItinerary(id, itinerary);

      if (!update!) {
        return;
      }
    }

    ItineraryApi().checkItineraryStatus(GoItinerary.toJson());

    DateTime updatedAt = GoItinerary.updated_at ?? DateTime.now();
    DateTime startDate = GoItinerary.start_date ?? DateTime.now();
    int initDate = GoItinerary.init_date ?? 0;

    int daysPassed = updatedAt.difference(startDate).inDays;

    if (daysPassed >= initDate) {
      await showCustomNotice(
          context, "Congratulations on completing your journey!", "confirm");
      await ItineraryApi().finishItineraryUpdate(id, itinerary);
      setState(() {});
      print("✅ Chuyến đi đã hoàn thành!");
      return;
    }

    int currentDay = daysPassed + 1;

    List<Location> todayLocations =
        GoItinerary.locations.where((loc) => loc.day == currentDay).toList();

    if (todayLocations.isEmpty) {
      print("❌ Không có địa điểm nào cho ngày $currentDay.");
      return;
    }

    List<String> locationNames = todayLocations.map((loc) => loc.name).toList();
    String? address = GoItinerary.address;

    List<LatLng> fetchedLocations =
        await LocationService.getCoordinatesFromAddresses(
            locationNames, address!);

    setState(() {
      locations = fetchedLocations;
    });

    print("📍 Địa điểm ngày $currentDay: $locationNames");
    print("🗺️ Danh sách tọa độ: $locations");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapNavigationScreen(
          title: GoItinerary.title,
          locations: locations,
          locationNames: locationNames,
        ),
      ),
    );
  }

  Future<void> _fetchItineraries() async {
    setState(() => isLoading = true);

    final itineraries = await _itineraryService.fetchItineraries();

    setState(() {
      allItineraries = itineraries;
      _filterItineraries();
      isLoading = false;
    });
  }

  void _deleteItineraryApi(Map<String, dynamic> trip, String? userName) async {
    bool? confirm;
    while (confirm == null) {
      confirm = await showCustomNotice(
          context,
          "Hi $userName! Please confirm that you want to delete this trip",
          "confirm");
    }

    if (confirm == true) {
      final result = await _itineraryService.deleteItinerary(trip['id'] as int);

      if (result == true) {
        await showCustomNotice(context, "Successfully deleted", "success");
        setState(() {
          allItineraries.removeWhere((item) => item['id'] == trip['id']);
          allItineraries.remove(trip);
          _filterItineraries();
        });
      } else {
        await showCustomNotice(context, "Fail to delete itinerary", "error");
      }
    } else {
      setState(() {
        allItineraries.removeWhere((item) => item['id'] == trip['id']);
        _filterItineraries();
      });
    }
  }

  void _filterItineraries() {
    setState(() {
      filteredItineraries = allItineraries
          .where((trip) => trip['status'] == selectedTab)
          .toList();

      // final itineraryResponse = parseItineraryResponse(filteredItineraries);
      // //Fetch images for location
      // String? imageItinerary = await ApiService().fetchImageUrl(cityTrip!);
    });
  }

  void _shareItinerary(Map<String, dynamic> trip) {
    final String shareText = 'Check out this itinerary: ${trip['title']}!';
    print("Sharing: $shareText");
  }

  void _deleteItinerary(Map<String, dynamic> trip) {
    setState(() {
      _deleteItineraryApi(trip, userGlobal?.displayName);
    });
    print("Deleted itinerary: ${trip['title']}");
  }

  Future<void> getById(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    Itinerary data = await ItineraryApi().getItineraryById(id);

    if (!context.mounted) return;

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailItineraryScreen(itineraryItems: data, type: 'view'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppBarCustom(),
      floatingActionButton: Container(
        width: 65,
        height: 65,
        child: FloatingActionButton(
          backgroundColor: Colors.orange,
          shape: CircleBorder(),
          onPressed: () {
            Navigator.pushNamed(context, "/create-itinerary");
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 32, color: Colors.white),
              Text("Itinerary",
                  style: TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        title: const Text('Travel Itinerary'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tabs
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTabItem('Itineraries', 0),
                      _buildTabItem('Going', 1),
                      _buildTabItem('History', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredItineraries.isEmpty
                      ? const Center(child: Text("No itineraries found"))
                      : ListView.builder(
                          itemCount: filteredItineraries.length,
                          itemBuilder: (context, index) {
                            final trip = filteredItineraries[index];

                            // Ensure 'locations' exists and is not empty
                            String? locationImageUrl;
                            if (trip['locations'] != null &&
                                trip['locations'] is List &&
                                trip['locations'].isNotEmpty) {
                              locationImageUrl = trip['locations'][0]['image'];
                            }

                            return FutureBuilder<String?>(
                              future: locationImageUrl != null &&
                                      locationImageUrl.isNotEmpty
                                  ? ApiService().fetchImageUrl(locationImageUrl)
                                  : Future.value(null),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return _buildTripCard(trip);
                                } else if (snapshot.hasError) {
                                  return _buildTripCard(trip);
                                } else {
                                  return _buildTripCard(trip,
                                      imageItinerary: snapshot.data);
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Tab Buttons
  Widget _buildTabItem(String title, int tabIndex) {
    bool isActive = selectedTab == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = tabIndex;
          _filterItineraries();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.orangeColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
              SizedBox(
                height: 85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'share') {
                          _shareItinerary(trip);
                        } else if (value == 'view') {
                          Itinerary itinerary = Itinerary.fromJson(trip);
                          getById(itinerary.id!);
                        } else if (value == 'delete') {
                          _deleteItinerary(trip);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, color: Colors.black),
                              SizedBox(width: 10),
                              Text('Share'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.remove_red_eye,
                                  color: AppColors.primaryColor),
                              SizedBox(width: 10),
                              Text('View'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(30, 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Icon(Icons.more_vert, color: Colors.black),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Itinerary itinerary = Itinerary.fromJson(trip);
                        await splitLocation(itinerary.id, itinerary);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(35, 23),
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('GO', style: TextStyle(color: Colors.white)),
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
