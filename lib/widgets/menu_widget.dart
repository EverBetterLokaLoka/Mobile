import 'package:flutter/material.dart';
import 'package:lokaloka/core/styles/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/auth/models/user.dart';
import '../features/home/screens/home_screen.dart';
import '../globals.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Are you sure you want to Sign out?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          contentPadding: EdgeInsets.zero,
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const Key('logout_cancel_button'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF78909C), // Gray color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(0, 45), // Height 45
                    ),
                    child: Text(
                      'No',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('logout_confirm_button'),
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.remove("auth_token");
                      await prefs.remove("token_saved_time");
                      travelDays = 0;
                      cityName = "";
                      trustPhone = "";
                      cityTrip = null;
                      images.clear();
                      userGlobal = UserNormal(
                          id: 1,
                          name: "",
                          email: "",
                          full_name: "",
                          address: "",
                          avatar: "");
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(0, 45), // Height 45
                    ),
                    child: Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        "/home",
                            (route) => false,
                        arguments: PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(-1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;

                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Text(
                    "Menu",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  CircleAvatar(
                    backgroundImage: userGlobal?.avatar != null
                        ? NetworkImage(userGlobal!.avatar!)
                        : AssetImage('assets/images/avt-default.png')
                            as ImageProvider,
                    radius: 22,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(context, Icons.person, "Account", '/profile'),
                  _buildMenuItem(context, Icons.notifications, "Notification",
                      '/notification',
                      iconColor: Colors.greenAccent),
                  _buildMenuItem(context, Icons.create, "Create Itinerary",
                      '/create-itinerary',
                      iconColor: Colors.pinkAccent),
                  _buildMenuItem(
                      context, Icons.flight_takeoff, "My trip", '/my-trip',
                      iconColor: Colors.yellow),
                  _buildMenuItem(
                      context, Icons.photo_library, "Moment", '/moment',
                      iconColor: AppColors.orangeColor),
                  _buildMenuItem(context, Icons.group, "Friends", '/friend',
                      iconColor: AppColors.primaryColor),
                  _buildMenuItem(context, Icons.map, "Map", '/map',
                      iconColor: AppColors.primaryColor),
                  _buildMenuItem(context, Icons.warning, "SOS", '/sos',
                      iconColor: Colors.red),
                  _buildMenuItem(context, Icons.explore, "Explore", '/explore',
                      iconColor: Colors.deepOrangeAccent),
                  _buildMenuItem(context, Icons.info, "About Us", '/about-us',
                      iconColor: Colors.purpleAccent),
                  TextButton(
                    key: Key("logout_button"),
                    onPressed: () => logout(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.fromLTRB(15, 10, 0, 0),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: Colors.black87, // Màu chữ
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.exit_to_app,
                          color: Colors.red,
                          size: 25,
                        ),
                        SizedBox(width: 13),
                        Text(
                          "Sign Out",
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, String? route,
      {Color iconColor = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(fontSize: 16)),
      onTap: () async {
        if (route == "/sos") {
          final phoneNumber = "tel:$trustPhone";
          if (await canLaunchUrl(Uri.parse(phoneNumber))) {
            await launchUrl(Uri.parse(phoneNumber));
          } else {
            print("Không thể gọi điện");
          }
        } else if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
