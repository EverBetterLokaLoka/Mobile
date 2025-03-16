import 'package:flutter/material.dart';
import 'package:lokaloka/features/friend/models/friend.dart';
import 'package:lokaloka/features/friend/services/friend_service.dart';
import 'package:lokaloka/features/friend/widgets/friend_list_item.dart';
import 'dart:developer' as developer;
class AddNewFriendsScreen extends StatefulWidget {
  final Function? onFriendAdded;

  const AddNewFriendsScreen({
    Key? key,
    this.onFriendAdded,
  }) : super(key: key);

  @override
  State<AddNewFriendsScreen> createState() => _AddNewFriendsScreenState();
}

class _AddNewFriendsScreenState extends State<AddNewFriendsScreen> with SingleTickerProviderStateMixin {
  final FriendService _friendService = FriendService();
  List<Friend> _suggestedFriends = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadSuggestedFriends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final friends = await _friendService.getFriendSuggestions();
      setState(() {
        _suggestedFriends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load friend suggestions');
    }
  }

  Future<void> _addFriend(Friend friend) async {
    try {
      final success = await _friendService.addFriend(friend.id);
      developer.log("friend id là: " + friend.id.toString());
      if (success) {
        setState(() {
          _suggestedFriends.removeWhere((f) => f.id == friend.id);
        });
        _showSuccessSnackBar('Added ${friend.username} as friend');

        if (widget.onFriendAdded != null) {
          widget.onFriendAdded!();
        }
      } else {
        _showErrorSnackBar('Failed to add ${friend.username}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _deleteFriendRequest(Friend friend) async {
    try {
      developer.log("friend: "+ friend.id.toString());
      final success = await _friendService.deleteFriendRequest(friend.id);

      if(success){
        setState(() {
          _suggestedFriends.removeWhere((f) => f.id == friend.id);
        });
        _showSuccessSnackBar('Deleted friend request from ${friend.username}');
      }else{
        _showErrorSnackBar('Failed to delete ${friend.username}');
      }

    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Friend requests (${_suggestedFriends.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Implement see all functionality
                  },
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suggestedFriends.isEmpty
                ? const Center(child: Text('No friend requests available'))
                : ListView.builder(
              itemCount: _suggestedFriends.length,
              itemBuilder: (context, index) {
                final friend = _suggestedFriends[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: friend.avatar != null
                            ? NetworkImage(friend.avatar!)
                            : null,
                        child: friend.avatar == null
                            ? Text(
                          friend.username[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend.username,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _addFriend(friend),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8), // Bo góc nhẹ 8px
                                      ),
                                    ),
                                    child: const Text(
                                      'Confirm',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _deleteFriendRequest(friend),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[200],
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8), // Bo góc nhẹ 8px
                                      ),
                                    ),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

