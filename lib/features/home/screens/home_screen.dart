import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lokaloka/core/styles/colors.dart';
import 'package:lokaloka/features/auth/models/user.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../globals.dart';
import '../../../widgets/app_bar_widget.dart';
import '../../auth/services/auth_services.dart';
import '../../navigation/services/navigation_api.dart';
import '../../profile/services/profile_services.dart';
import '../../weather/services/LocationService.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? currentLocation;
  final ProfileService _profileService = ProfileService();
  UserNormal? user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthService().checkTokenAndProceed(context);
    });
    _fetchUserProfile();
    _initializeLocation();
    getCity();
  }

  Future<void> _fetchUserProfile() async {
    user = await _profileService.getUserProfile();

    if (user != null) {
      trustPhone = user?.emergency_numbers;
      userGlobal = user;
    }
  }

  void getCity() async {
    String? city = await LocationService.getCurrentCity();
    if (city != null) {
      cityName = city;
      print("Thành phố hiện tại: $city");
    } else {
      print("Không thể lấy thành phố.");
    }
  }

  Future<void> _initializeLocation() async {
    await NavigationApi().getCurrentLocation();
    _checkPermissions();
    setState(() {});
  }

  Future<void> _checkPermissions() async {
    PermissionStatus locationStatus = await Permission.location.status;
    PermissionStatus cameraStatus = await Permission.camera.status;

    if (locationStatus.isDenied || cameraStatus.isDenied) {
      _requestPermissions();
    } else if (locationStatus.isPermanentlyDenied ||
        cameraStatus.isPermanentlyDenied) {
      _showSettingsDialog();
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
    ].request();

    if (statuses[Permission.location]!.isDenied ||
        statuses[Permission.camera]!.isDenied) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Request permission"),
        content: Text(
            "The app needs location and camera permissions to work. Please grant permissions to continue."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestPermissions();
            },
            child: Text("Try again"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Access denied"),
        content: Text(
            "You have permanently denied permission. Go to settings to grant permission."),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: Text("Open setting"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 1.2,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/SC_000_Home_Background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: 10),
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildExperienceSection(),
                          _buildExploreSection(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hi, ${user?.displayName ?? "User"}",
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.black, size: 16),
                        SizedBox(width: 5),
                        Text(
                          "${user?.address?.isNotEmpty == true ? user!.address : cityName}, Việt Nam",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: CircleAvatar(
                    backgroundImage: user?.avatar != null
                        ? NetworkImage(user!.avatar!)
                        : AssetImage(user?.gender == 'male'
                                ? 'assets/images/default-avt-female.png'
                                : 'assets/images/default-avt-male.png')
                            as ImageProvider,
                    radius: 22,
                  ),
                )
              ],
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Where do you want to go?",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(height: 15)
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceSection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Experience",
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor)),
          SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildExperienceItem(
                  LucideIcons.map, "Travel Itinerary", "/navigation-map"),
              _buildExperienceItem(LucideIcons.users, "Friends", "/friend"),
              _buildExperienceItem(LucideIcons.shieldAlert, "SOS", "/sos"),
              _buildExperienceItem(LucideIcons.camera, "Moment", "/moment"),
              _buildExperienceItem(LucideIcons.mapPin, "Map", "/map"),
              _buildExperienceItem(LucideIcons.cloudSun, "Weather", "/weather"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(IconData icon, String label, String navigate) {
    return Builder(
      builder: (context) => Column(
        children: [
          GestureDetector(
            onTap: () async {
              if (navigate == "/sos") {
                final phoneNumber = "tel:$trustPhone";
                if (await canLaunchUrl(Uri.parse(phoneNumber))) {
                  await launchUrl(Uri.parse(phoneNumber));
                } else {
                  print("Không thể gọi điện");
                }
              } else {
                Navigator.pushNamed(context, navigate);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orangeColor,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildExploreSection(context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Explore",
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor)),
              Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/explore'),
                child: Text(
                  "See all",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          _buildExploreCard(),
        ],
      ),
    );
  }

  Widget _buildExploreCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset('assets/images/hoiAn.png',
                height: 150, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Hoi An Ancient Town",
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orangeColor)),
                Spacer(),
                Icon(Icons.star, color: Colors.yellow),
                SizedBox(width: 2),
                Text("4.8")
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
            child: Row(
              children: [Icon(Icons.location_on), Text("Quang Nam")],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
                "Hoi An Ancient Town is an exceptionally well-preserved example of a Southeast Asian trading port that dates from the 15th to the 19th century. Renowned for its historical buildings, it showcases a blend of European and "),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 10, 10, 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                  onPressed: () => {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor),
                  child: Text(
                    "View",
                    style: TextStyle(color: Colors.white),
                  )),
            ),
          )
        ],
      ),
    );
  }
}
