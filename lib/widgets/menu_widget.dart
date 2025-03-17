import 'package:flutter/material.dart';
import 'package:lokaloka/core/styles/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../globals.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Are you sure you want to log out?",
            style: TextStyle(color: AppColors.orangeColor),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(AppColors.primaryColor),
              ),
              onPressed: () async {
                Navigator.pop(context);
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove("auth_token");
                await prefs.remove("token_saved_time");
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
              child: Text("Yes", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.grey),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text("No", style: TextStyle(color: Colors.white)),
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
                    onPressed: () => Navigator.pop(context),
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
                        : AssetImage('assets/images/avt-default') as ImageProvider,
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
                  _buildMenuItem(context, Icons.exit_to_app, "Sign out", null,
                      iconColor: Colors.red, isLogout: true),
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
      {Color iconColor = Colors.black, bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(fontSize: 16)),
      onTap: () async {
        if (isLogout) {
          logout(context);
        } else if (route == "/sos") {
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
