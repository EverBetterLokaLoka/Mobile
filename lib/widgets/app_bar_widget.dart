import 'package:flutter/material.dart';
import '../core/styles/colors.dart';
import 'menu_widget.dart';

class AppBarCustom extends StatelessWidget {
  const AppBarCustom({super.key});

  @override
  Widget build(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BottomAppBar(
        shape: CircularNotchedRectangle(),
        color: AppColors.primaryColor,
        padding: EdgeInsets.symmetric(vertical: 3),
        notchMargin: 4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, '/home', context, "Home", currentRoute),
            _buildNavItem(
                Icons.map, '/my-trip', context, "My Trip", currentRoute),
            SizedBox(width: 40),
            _buildNavItem(Icons.notifications, '/notification', context,"Notification" ,currentRoute),
            _buildNavItem(Icons.menu, '/menu', context, "Menu", currentRoute,
                screen: Menu()),
          ],
        ),
      ),
    );
  }
}

Widget _buildNavItem(IconData icon, String route, BuildContext context,
    String label, String? currentRoute,
    {Widget? screen}) {
  bool isActive = currentRoute == route;
  Color color = isActive ? AppColors.orangeColor : Colors.white;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(icon, color: color, size: 30),
          onPressed: () {
            if (currentRoute == route) {
              return;
            }

            if (screen != null) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => screen,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    return SlideTransition(
                        position: animation.drive(tween), child: child);
                  },
                ),
              );
            } else {
              Navigator.pushReplacementNamed(context, route);
            }
          }
      ),
      Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
    ],
  );
}
