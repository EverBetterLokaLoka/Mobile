import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final Function(int, bool) onFriendRequestAction;
  final VoidCallback onMenuPressed;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onFriendRequestAction,
    required this.onMenuPressed,
  }) : super(key: key);

  String _formatTimestamp(DateTime timestamp) {
    // Format the timestamp for display
    return DateFormat('yMd').add_jm().format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          notification.description,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _formatTimestamp(notification.createdAt),
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: onMenuPressed,
        ),
        onTap: () {
          // Navigate to the friends page
          Navigator.of(context).pushNamed('/friend'); // Change to your friends route
        },
      ),
    );
  }
}