import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lokaloka/core/styles/colors.dart';
import 'package:lokaloka/features/itinerary/models/Itinerary.dart';
import 'package:lokaloka/features/itinerary/screens/detail_itinerary_screen.dart';
import 'package:lokaloka/features/moments/screens/create_moment_screen.dart';
import '../../../core/utils/apis.dart';
import '../../../core/utils/format_text.dart';
import '../../../core/utils/transfer_money.dart';
import '../../../globals.dart';
import '../../../widgets/app_bar_widget.dart';
import '../../../widgets/notice_widget.dart';
import '../../auth/models/user.dart';
import '../../navigation/screens/map_navigation_screen.dart';
import '../../profile/screens/account_tab.dart';
import '../../profile/services/profile_services.dart';
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
  final ProfileService _profileService = ProfileService();
  late final UserNormal user;
  TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchItineraries();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final response = await _profileService.getUserProfile();

    if (response != null) {
      setState(() {
        user = response;
      });
    } else {
      showCustomNotification(
        context: context,
        notification: CustomNotification(
          message: 'Fail to load user data',
          isError: true,
        ),
      );
    }
  }

  void showCustomNotification({
    required BuildContext context,
    required Widget notification,
    Duration duration = const Duration(seconds: 3),
  }) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: notification,
        ),
      ),
    );

    Overlay.of(context).insert(entry);

    Future.delayed(duration, () {
      entry?.remove();
    });
  }

  Future<bool> checkEmergencyPhone(
      BuildContext context, String? trustPhone) async {
    if (trustPhone != "" && trustPhone != null) {
      print("Số điện thoại khẩn cấp: $trustPhone");
      return true;
    }

    bool? shouldUpdate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Notice"),
          content: Text(
              "You do not have an emergency phone number. Do you want to update?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Yes"),
            ),
          ],
        );
      },
    );

    if (shouldUpdate == false) {
      print("Không cập nhật số điện thoại.");
      return false;
    }

    bool? phoneEntered = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Update emergency phone number"),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "Type phone number",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String phone = phoneController.text.trim();

                RegExp phoneRegex = RegExp(r'^(0\d{9}|\+84\d{9})$');

                if (phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter phone number!")));
                  return;
                }

                if (!phoneRegex.hasMatch(phone)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Phone number is not valid!")));
                  return;
                }

                Navigator.of(context).pop(true);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );

    if (phoneEntered == false || phoneController.text.isEmpty) {
      print("Người dùng không nhập số điện thoại.");
      return false;
    }

    print("Số điện thoại mới: ${phoneController.text}");
      _handleUpdate();
    return true;
  }

  Future<void> _handleUpdate() async {
    print("vao ham");
    final updatedUser = UserNormal(
      id: user.id,
      full_name: user.full_name,
      dob: user.dob,
      gender: user.gender,
      email: user.email,
      phone: user.phone,
      address: user.address,
      emergency_numbers: phoneController.text,
      name: user.name,
      avatar: user.avatar,
    );

    final result = await _profileService.updateUserProfile(updatedUser);

    if (result is bool && result) {
      trustPhone = phoneController.text;
      showCustomNotification(
        context: context,
        notification: CustomNotification(
          message: 'Trust phone updated successfully.',
        ),
      );

    } else {
      showCustomNotification(
        context: context,
        notification: CustomNotification(
          message:
              'An error occurred while updating your profile. Please try again later.',
          isError: true,
        ),
      );
    }
  }

  Future<void> splitLocation(int? id, Itinerary itinerary) async {
    if (!mounted) return;

    bool hasPhone = await checkEmergencyPhone(context, trustPhone);
    if (!hasPhone) return;

    Itinerary GoItinerary = await ItineraryApi().getItineraryById(id);

    if (GoItinerary.start_date == null) {
      print("Chưa có ngày bắt đầu.");

      bool? updateStatus =
          await ItineraryApi().goItineraryUpdate(id, itinerary);
      if (!updateStatus!) return;

      return;
    } else {
      bool? update = await ItineraryApi().updateItinerary(id, itinerary);
      if (!update!) {
        setState(() {});
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
      print("Chuyến đi đã hoàn thành!");
      return;
    }

    int currentDay = daysPassed + 1;
    List<Location> todayLocations =
        GoItinerary.locations.where((loc) => loc.day == currentDay).toList();

    if (todayLocations.isEmpty) {
      print("Không có địa điểm nào cho ngày $currentDay.");
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

  Future<bool> noticeDelete(
      BuildContext context, String message, String type) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (type != "error") ...[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor:
                              type == "error" ? Colors.red : Colors.cyan,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) => value ?? false);
  }

  void _deleteItineraryApi(Map<String, dynamic> trip, String? userName) async {
    bool confirm = await showCustomNotice(
        context,
        "Hi $userName! Please confirm that you want to delete this trip",
        "confirm");

    if (confirm == false) {
      return;
    }

    if (confirm == true) {
      final result = await _itineraryService.deleteItinerary(trip['id'] as int);

      if (result == true) {
        await noticeDelete(context, "Successfully deleted", "success");
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
  // final Map<String, dynamic>? shareIinterary;

  void _shareItinerary(Map<String, dynamic> trip) {
    final String shareText = 'Check out this itinerary: ${trip['title']}!';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMomentScreen(
          userName: userGlobal.displayName,
          userLocation: userGlobal.address!,
          userAvatar: userGlobal.avatar!,
          shareItinerary: trip,
          type: "share",
        ),
      ),
    );

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
        builder: (context) => DetailItineraryScreen(
            itineraryItems: data, title: data.title, type: 'view'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppBarCustom(),
      floatingActionButton: Container(
        width: 80,
        height: 80,
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
      child: InkWell(
        onTap: () async {
          Itinerary itinerary = Itinerary.fromJson(trip);
          getById(itinerary.id!);
        },
        borderRadius: BorderRadius.circular(15),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                        // formatTitle(trip['title']) ?? 'Unknown Title',
                        trip['title'] ?? 'Unknown Title',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text('${trip['init_date']} days',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.attach_money,
                              size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(CurrencyFormatter.formatVnd(trip['price']),
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.place, size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text('${trip['locations']?.length ?? 0} Destinations',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
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
                        child: Icon(Icons.more_horiz_outlined,
                            color: Colors.black),
                      ),
                      if (selectedTab != 2)
                        ElevatedButton(
                          onPressed: () async {
                            Itinerary itinerary = Itinerary.fromJson(trip);
                            await splitLocation(itinerary.id, itinerary);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: Size(35, 23),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child:
                              Text("Go", style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
