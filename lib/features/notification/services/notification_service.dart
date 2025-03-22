import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lokaloka/features/auth/services/auth_services.dart';
import 'package:lokaloka/features/friend/services/friend_service.dart';
import 'package:lokaloka/features/notification/models/notification_model.dart';
import 'package:lokaloka/features/notification/services/notification_storage_service.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class NotificationService extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationStorageService _storageService = NotificationStorageService();

  int? userId;
  StompClient? _stompClient;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  final List<Function(bool)> _connectionListeners = [];
  final List<NotificationModel> _notifications = [];
  bool _isInitialized = false;

  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const String _wsBaseUrl = 'wss://8fbe-14-174-105-39.ngrok-free.app/ws';

  bool get isConnected => _isConnected;
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isInitialized => _isInitialized;

  void addConnectionListener(Function(bool) listener) {
    _connectionListeners.add(listener);
  }

  void removeConnectionListener(Function(bool) listener) {
    _connectionListeners.remove(listener);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize storage service first
      await _storageService.initialize();

      // Load saved notifications
      final savedNotifications = await _storageService.loadNotifications();
      _notifications.clear();
      _notifications.addAll(savedNotifications);

      // Get user ID
      String? userIdString = await _authService.getUserIdFromToken();
      if (userIdString == null) {
        throw Exception("User ID not found in token.");
      }

      userId = int.tryParse(userIdString);
      if (userId == null) {
        throw Exception("Could not convert user ID to integer.");
      }

      // Connect to WebSocket
      await _connectStompWebSocket();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      rethrow;
    }
  }

  Future<void> _connectStompWebSocket() async {
    if (_isConnecting) return;
    _isConnecting = true;

    await disconnect(); // Disconnect if already connected

    try {
      print('🔌 Attempting to connect to STOMP WebSocket at $_wsBaseUrl');

      // Get auth token if needed
      String? token = await _authService.getToken();

      // Configure STOMP client
      _stompClient = StompClient(
        config: StompConfig(
          url: _wsBaseUrl,
          onConnect: _onStompConnect,
          onDisconnect: _onStompDisconnect,
          onWebSocketError: (error) {
            print('❌ WebSocket error: $error');
            _isConnected = false;
            _notifyConnectionListeners();
            _scheduleReconnect();
          },
          // Add token to headers if needed
          stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
          webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
          // Heartbeat settings
          heartbeatOutgoing: Duration(seconds: 20),
          heartbeatIncoming: Duration(seconds: 20),
          // Reconnect settings
          reconnectDelay: Duration(seconds: 5),
        ),
      );

      // Activate the client
      _stompClient!.activate();
    } catch (e) {
      print('❌ Connection error: $e');
      _isConnected = false;
      _notifyConnectionListeners();
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _onStompConnect(StompFrame frame) {
    print('✅ Connected to STOMP WebSocket');
    _isConnected = true;
    _reconnectAttempts = 0;
    _notifyConnectionListeners();

    // Subscribe to user-specific notifications
    if (userId != null) {
      // Subscribe to the user's specific topic with correct path format
      _stompClient!.subscribe(
        destination: '/topic/notifications/$userId',
        callback: (StompFrame frame) {
          print('🔔 RECEIVED MESSAGE on /topic/notifications/$userId: ${frame.body}');
          _handleStompMessage(frame);
        },
      );

      // Also subscribe to general topics if needed
      _stompClient!.subscribe(
        destination: '/topic/friendship',
        callback: (StompFrame frame) {
          print('🔔 RECEIVED MESSAGE on /topic/notifications/$userId: ${frame.body}');
          _handleStompMessage(frame);
        },
      );

      print('✅ Subscribed to notifications for user $userId');
    }
  }

  void _handleStompMessage(StompFrame frame) {
    print('📩 Received STOMP message:');
    print('📩 Headers: ${frame.headers}');
    print('📩 Body: ${frame.body}');

    if (frame.body == null) {
      print('⚠️ Message body is null');
      return;
    }

    try {
      print('🔄 Attempting to parse message as JSON');
      final jsonData = jsonDecode(frame.body!);
      print('✅ Successfully parsed JSON: $jsonData');

      try {
        // For friend requests, ensure we have an ID
        if (jsonData['type'] == 'FRIEND_REQUEST' && jsonData['id'] == null) {
          // Generate a unique ID for this notification
          jsonData['id'] = DateTime.now().millisecondsSinceEpoch;
        }

        final notification = NotificationModel.fromJson(jsonData);
        print('✅ Successfully created NotificationModel: ${notification.title}');
        _addNotification(notification);
      } catch (e) {
        print('❌ Error creating NotificationModel: $e');
        // Create a more detailed error message
        print('❌ JSON data causing error: $jsonData');
        print('❌ Stack trace: $e');

        // Fallback to simple notification with more robust creation
        _createNotificationFromRawData(jsonData);
      }
    } catch (e) {
      print('❌ Error parsing JSON: $e');
      // Try to use the message as a simple string notification
      // _createSimpleNotification(frame.body!);
    }
  }

  void _createNotificationFromRawData(Map<String, dynamic> data) {
    print('🔄 Creating notification from raw data: $data');
    try {
      // Ensure we have all required fields with proper types
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch,
        title: data['title']?.toString() ?? 'New Notification',
        body: data['body']?.toString() ?? 'You have a new notification',
        createdAt: DateTime.now(),
        senderId: data['senderId'] is int
            ? data['senderId']
            : data['senderId'] is String
            ? int.tryParse(data['senderId']) ?? 0
            : 0,
        type: data['type']?.toString() ?? 'SYSTEM',
        data: data,
      );
      print('✅ Created notification from raw data');
      _addNotification(notification);
    } catch (e) {
      print('❌ Error creating notification from raw data: $e');
      // _createSimpleNotification(jsonEncode(data));
    }
  }

  // void _createSimpleNotification(String message) {
  //   print('🔄 Creating simple notification from message: $message');
  //   try {
  //     final notification = NotificationModel(
  //       id: DateTime.now().millisecondsSinceEpoch,
  //       title: 'New Notification',
  //       body: message,
  //       createdAt: DateTime.now(),
  //       senderId: 0,
  //       type: 'SYSTEM',
  //     );
  //     print('✅ Created simple notification');
  //     _addNotification(notification);
  //   } catch (e) {
  //     print('❌ Error creating simple notification: $e');
  //   }
  // }

  void _onStompDisconnect(StompFrame frame) {
    print('❌ Disconnected from STOMP WebSocket');
    _isConnected = false;
    _notifyConnectionListeners();
    _scheduleReconnect();
  }

  void _notifyConnectionListeners() {
    for (var listener in _connectionListeners) {
      listener(_isConnected);
    }
  }

  void _addNotification(NotificationModel notification) {
    // Check for duplicates to avoid adding the same notification multiple times
    if (!_notifications.any((n) => n.id == notification.id)) {
      print('📝 Adding notification to list: ${notification.title}');
      _notifications.insert(0, notification);
      print('📊 Notification list size: ${_notifications.length}');

      // Save to local storage with error handling
      _storageService.saveNotifications(_notifications).catchError((error) {
        print('❌ Error saving notifications: $error');
        // Continue execution even if saving fails
      });

      notifyListeners();
      print('🔔 Notified listeners');
    } else {
      print('⚠️ Duplicate notification detected, not adding: ${notification.id}');
    }
  }

  Future<void> disconnect() async {
    if (_stompClient != null && _stompClient!.connected) {
      _stompClient!.deactivate();
      _stompClient = null;
    }

    _isConnected = false;
    _notifyConnectionListeners();
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    await _storageService.clearNotifications();
    notifyListeners();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      Future.delayed(_reconnectDelay, () {
        if (!_isConnected && !_isConnecting) {
          _connectStompWebSocket();
        }
      });
    }
  }

  // Add a test method to manually add a notification
  void sendTestNotification() {
    final testNotification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Test Notification',
      body: 'This is a test notification at ${DateTime.now()}',
      createdAt: DateTime.now(),
      senderId: 0,
      type: 'SYSTEM',
    );

    _addNotification(testNotification);
  }

  // Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final updatedNotification = _notifications[index].copyWith(isRead: true);
      _notifications[index] = updatedNotification;

      // Save to local storage
      await _storageService.saveNotifications(_notifications);

      notifyListeners();
    }
  }

  // Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);

    // Save to local storage
    await _storageService.saveNotifications(_notifications);

    notifyListeners();
  }

  // Handle friend request
  Future<void> handleFriendRequest(int notificationId, bool accepted) async {
    // Find the notification
    final notification = _notifications.firstWhere(
          (n) => n.id == notificationId,
      orElse: () => throw Exception('Notification not found'),
    );

    if (notification.friendId == null) {
      throw Exception('Follower ID not found in notification');
    }

    try {
      FriendService friend = FriendService();
      if(accepted){
        bool success = await friend.addFriend(notification.friendId!);

        if (success) {
          print('✅ Friend request ${accepted ? "accepted" : "rejected"} successfully');
        } else {
          print('❌ Error responding to friend request');
          throw Exception('Failed to respond to friend request');
        }
      }else{
        String notifiId = notification.friendId.toString();
        bool reject = await friend.removeFriend(notifiId);
        if (reject) {
          print('✅ Friend request rejected successfully');
        } else {
          print('❌ Error responding to friend request');
          throw Exception('Failed to respond to friend request');
        }
      }

    } catch (e) {
      print('❌ Exception responding to friend request: $e');
      rethrow;
    } finally {
      await markAsRead(notificationId);
    }
  }

}

