import 'package:flutter/material.dart';
import 'package:lokaloka/features/auth/services/auth_services.dart';
import 'package:lokaloka/features/friend/models/friend.dart';
import 'package:lokaloka/features/friend/services/friend_service.dart';
import 'package:lokaloka/features/friend/widgets/friend_list_item.dart';
import 'dart:developer' as developer;

class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({Key? key}) : super(key: key);

  @override
  State<SearchFriendsScreen> createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  List<Friend> _searchResults = [];
  Map<String, String> _friendStatuses = {}; // Store friend statuses by email
  Map<String, int> _followerIds = {}; // Store follower IDs by email
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFriends(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await _friendService.searchFriends(query);

      _friendStatuses.clear();
      _followerIds.clear();

      final friendsFuture = _friendService.getFriends();
      final pendingRequestsFuture = _friendService.getPendingRequests();
      final friendRequestsFuture = _friendService.getFriendSuggestions();

      final friends = await friendsFuture;
      final pendingRequests = await pendingRequestsFuture;
      final friendRequests = await friendRequestsFuture;

      developer.log('Pending requests: ${pendingRequests.map((f) => '${f.username} (id: ${f.id}, userId: ${f.userId}, email: ${f.email})').join(', ')}');

      final friendEmails = Map.fromEntries(friends.map((f) => MapEntry(f.email.toLowerCase(), f.id)));

      final pendingRequestEmails = Map.fromEntries(pendingRequests.map((f) => MapEntry(f.email.toLowerCase(), f.id)));

      final friendRequestEmails = Map.fromEntries(friendRequests.map((f) => MapEntry(f.email.toLowerCase(), f.id)));

      Map<String, String> tempStatuses = {};
      Map<String, int> tempFollowerIds = {};

      for (var friend in results) {
        final lowerEmail = friend.email.toLowerCase();

        if (friendEmails.containsKey(lowerEmail)) {
          tempStatuses[lowerEmail] = "FRIEND";
          tempFollowerIds[lowerEmail] = friendEmails[lowerEmail]!;
          developer.log('User ${friend.username} (email: ${friend.email}) is a FRIEND with follower ID: ${friendEmails[lowerEmail]}');
        } else if (pendingRequestEmails.containsKey(lowerEmail)) {
          tempStatuses[lowerEmail] = "PENDING";
          tempFollowerIds[lowerEmail] = pendingRequestEmails[lowerEmail]!;
          developer.log('User ${friend.username} (email: ${friend.email}) is PENDING with follower ID: ${pendingRequestEmails[lowerEmail]}');
        } else if (friendRequestEmails.containsKey(lowerEmail)) {
          tempStatuses[lowerEmail] = "REQUESTED";
          tempFollowerIds[lowerEmail] = friendRequestEmails[lowerEmail]!;
          developer.log('User ${friend.username} (email: ${friend.email}) is REQUESTED with follower ID: ${friendRequestEmails[lowerEmail]}');
        } else {
          tempStatuses[lowerEmail] = "NONE";
          developer.log('User ${friend.username} (email: ${friend.email}) is NONE');
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _friendStatuses = tempStatuses;
          _followerIds = tempFollowerIds;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _showErrorSnackBar('Failed to search friends: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _sendFriendRequest(Friend friend) async {
    try {
      String? currentUserId = await AuthService().getUserIdFromToken();
      String? currentUserLogin = await AuthService().getUserNameFromToken(context);

      if (currentUserId == null || currentUserLogin == null) {
        _showErrorSnackBar('Unable to retrieve user ID or username');
        return;
      }

      final success = await _friendService.addRequestFriend(friend.userId);
      if (success) {
        final lowerEmail = friend.email.toLowerCase();
        setState(() {
          _friendStatuses[lowerEmail] = "PENDING";
        });

        final notificationMessage = 'You received a friend request from $currentUserLogin';
        final notificationId = await _friendService.sendNotification(notificationMessage, friend.userId, currentUserId);

        if (notificationId != null) {
          print("success");
          // _showSuccessSnackBar('Friend request sent to ${friend.username} and notification sent.');
        } else {
          _showErrorSnackBar('Friend request sent to ${friend.username}, but failed to send notification.');
        }
      } else {
        _showErrorSnackBar('Failed to send friend request');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _acceptFriendRequest(Friend friend, int followerId) async {
    try {
      final success = await _friendService.addFriendWithFollowerId(followerId);
      if (success) {
        final lowerEmail = friend.email.toLowerCase();
        setState(() {
          _friendStatuses[lowerEmail] = "FRIEND";
        });
        _showSuccessSnackBar('Added ${friend.username} as friend');
      } else {
        _showErrorSnackBar('Failed to accept friend request');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Find new friends',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              _searchFriends(value);
            },
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              _searchFriends(value);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          if (_searchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Friends',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Action to view all friends
                    },
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                ? const Center(child: Text('Search for friends'))
                : _searchResults.isEmpty
                ? const Center(child: Text('No results found'))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final friend = _searchResults[index];
                final lowerEmail = friend.email.toLowerCase();
                final status = _friendStatuses[lowerEmail] ?? "NONE";
                final followerId = _followerIds[lowerEmail];

                return FriendListItem(
                  friend: friend,
                  actionButton: _buildActionButton(friend, status, followerId),
                );
              },
            ),
          ),
          // Bottom action bar with keyboard
          Container(
            height: 50,
            color: Colors.grey.shade200,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.gif_box_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.mic_none),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Friend friend, String status, int? followerId) {
    developer.log('Building button for ${friend.username} (email: ${friend.email}) with status: $status and follower ID: $followerId');

    switch (status) {
      case "FRIEND":
        return Expanded(
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: ElevatedButton(
              onPressed: () {
                _showFriendOptions(friend, followerId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Friends'),
            ),
          ),
        );

      case "PENDING":
        return Expanded(
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: ElevatedButton(
              onPressed: () async {
                if (friend.id != null) {
                  final success = await _friendService.cancelFriendRequestSend(friend.id);
                  if (success) {
                    final lowerEmail = friend.email.toLowerCase();
                    setState(() {
                      _friendStatuses[lowerEmail] = "NONE"; // Update UI status
                      _followerIds.remove(lowerEmail); // Remove ID as it does not exist anymore
                    });

                    // Lấy ID người dùng hiện tại
                    String? currentUserId = await AuthService().getUserIdFromToken();
                    if (currentUserId != null) {
                      bool notificationCancelled = await _friendService.cancelNotification(int.parse(currentUserId), friend.id);
                      if (notificationCancelled) {
                        _showSuccessSnackBar('Canceled friend request to ${friend.username} and notification cancelled.');
                      } else {
                        _showErrorSnackBar('Failed to cancel notification after cancelling friend request.');
                      }
                    } else {
                      _showErrorSnackBar('Failed to retrieve current user ID.');
                    }
                  } else {
                    _showErrorSnackBar('Failed to cancel friend request to ${friend.username}');
                  }
                } else {
                  _showErrorSnackBar('Cannot cancel request: Missing follower ID');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
        );

      case "REQUESTED":
        return Expanded(
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: ElevatedButton(
              onPressed: () async {
                if (followerId != null) {
                  await _acceptFriendRequest(friend, followerId);
                } else {
                  _showErrorSnackBar('Cannot approve request: Missing follower ID');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ),
        );

      case "NONE":
      default:
        return Expanded(
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: ElevatedButton(
              onPressed: () async {
                await _sendFriendRequest(friend);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add Friend'),
            ),
          ),
        );
    }
  }

  void _showFriendOptions(Friend friend, int? followerId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Send Message'),
                onTap: () {
                  Navigator.pop(context);
                  // Logic for sending message
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_remove),
                title: const Text('Unfriend'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final idToUse = followerId != null ? followerId.toString() : friend.userId.toString();
                    final success = await _friendService.removeFriend(idToUse);
                    if (success) {
                      final lowerEmail = friend.email.toLowerCase();
                      setState(() {
                        _friendStatuses[lowerEmail] = "NONE";
                        _followerIds.remove(lowerEmail);
                      });
                      _showSuccessSnackBar('Unfriended ${friend.username}');
                    } else {
                      _showErrorSnackBar('Failed to unfriend ${friend.username}');
                    }
                  } catch (e) {
                    _showErrorSnackBar('Error: $e');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  // Logic to block user
                },
              ),
            ],
          ),
        );
      },
    );
  }
}