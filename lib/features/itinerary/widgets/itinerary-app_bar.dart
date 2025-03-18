import 'package:flutter/material.dart';

import '../../home/screens/home_screen.dart';

class ItineraryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Color backgroundColor;

  ItineraryAppBar({
    Key? key,
    required this.titleText,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm"),
        content: Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("NO"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                    (Route<dynamic> route) => false,
              );
            },
            child: Text("YES"),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: AppBar(
        title: Text(
          titleText,
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        actions: actions,
        bottom: bottom,
        centerTitle: centerTitle,
        backgroundColor: backgroundColor,
        elevation: 4.0,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
