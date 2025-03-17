import 'package:flutter/material.dart';
import 'package:lokaloka/features/notification/models/notification_model.dart';
import 'package:lokaloka/features/notification/services/notification_service.dart';
import 'package:lokaloka/features/notification/widgets/notification_item.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotificationService(); // Khởi tạo service
  }

  Future<void> _initializeNotificationService() async {
    try {
      await _notificationService.initialize(); // Gọi initialize
      await _fetchNotifications(); // Sau đó lấy notifications
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize notifications: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: ${e.toString()}')),
        );
      }
    }
  }

  void _deleteNotification(int userId, int foreignId) async {
    try {
      await _notificationService.deleteNotification(userId, foreignId);
      await _fetchNotifications(); // Làm mới danh sách notifications
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return NotificationItem(
            notification: notification,
            onFriendRequestAction: (id, accept) {
              // Xử lý yêu cầu kết bạn nếu cần
            },
            onMenuPressed: () {
              final userId = notification.userId; // Giả sử trường này tồn tại
              final foreignId = notification.foreignId; // Giả sử trường này tồn tại
              // Hiển thị menu
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Delete notification'),
                      onTap: () {
                        Navigator.pop(context);
                        _deleteNotification(foreignId,userId);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.block),
                      title: const Text('Block user'),
                      onTap: () {
                        Navigator.pop(context);
                        // Thực hiện chức năng chặn người dùng ở đây
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}