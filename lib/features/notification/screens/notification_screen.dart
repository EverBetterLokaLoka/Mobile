import 'package:flutter/material.dart';
import 'package:lokaloka/features/auth/services/auth_services.dart';
import 'package:lokaloka/features/notification/services/notification_service.dart';
import 'package:lokaloka/features/notification/models/notification_model.dart';
import 'package:lokaloka/features/notification/widgets/notification_item.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  bool _isConnected = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _notificationService.removeConnectionListener(_onConnectionChanged);
    super.dispose();
  }

  void _onConnectionChanged(bool isConnected) {
    setState(() {
      _isConnected = isConnected;
    });
  }

  Future<void> _initializeNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!_notificationService.isInitialized) {
        _notificationService.addConnectionListener(_onConnectionChanged);
        await _notificationService.initialize();
      } else {
        _isConnected = _notificationService.isConnected;
      }

      _notificationService.addListener(() {
        if (mounted) setState(() {});
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error initializing: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNotifications() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh: $e')),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _handleFriendRequestAction(int notificationId, bool accepted) async {
    try {
      await _notificationService.handleFriendRequest(notificationId, accepted);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted
              ? 'Friend request accepted'
              : 'Friend request rejected'),
          backgroundColor: accepted ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    _notificationService.markAsRead(notification.id);

    // Handle different notification types
    switch (notification.type) {
      case 'FRIEND_REQUEST':
      // Show friend request details
        showDialog(
          context: context,
          builder: (context) {
            bool isHandled = false; // Local state for handling button visibility

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('Friend Request'),
                  content: Text(notification.body),
                  actions: [
                    if (!isHandled) ...[
                      TextButton(
                        onPressed: () {
                          _handleFriendRequestAction(notification.id, false);
                          setState(() {
                            isHandled = true; // Disable buttons when one is pressed
                          });
                        },
                        child: Text('Reject', style: TextStyle(color: Colors.red)),
                      ),
                      TextButton(
                        onPressed: () {
                          _handleFriendRequestAction(notification.id, true);
                          setState(() {
                            isHandled = true; // Disable buttons when one is pressed
                          });
                        },
                        child: Text('Accept', style: TextStyle(color: Colors.green)),
                      ),
                    ] else ...[
                      Text(
                        'Request already handled.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        );
        break;
      case 'SYSTEM':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification.title),
            content: Text(notification.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Tooltip(
            message: _isConnected ? 'Connected' : 'Disconnected',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                _isConnected ? Icons.wifi : Icons.wifi_off,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add_alert),
            onPressed: () {
              _notificationService.sendTestNotification();
            },
            tooltip: 'Add Test Notification',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _notificationService.clearNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cleared')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear all'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildNotificationList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeNotifications,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    final notifications = _notificationService.notifications;

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationItem(
            notification: notification,
            onFriendRequestAction: _handleFriendRequestAction,
            onMarkAsRead: (id) {
              _notificationService.markAsRead(id);
            },
            onDelete: (id) {
              _notificationService.deleteNotification(id);
            },
            onTap: _handleNotificationTap,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}