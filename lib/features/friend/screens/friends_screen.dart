import 'package:flutter/material.dart';
import 'package:lokaloka/features/friend/models/friend.dart';
import 'package:lokaloka/features/friend/services/friend_service.dart';
import 'package:lokaloka/features/friend/screens/add_new_friends_screen.dart';
import 'package:lokaloka/features/friend/screens/search_friends_screen.dart';
import 'dart:developer' as developer;

import 'package:lokaloka/widgets/notice_widget.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendService _friendService = FriendService();
  List<Friend> _friends = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final friends = await _friendService.getFriends();
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        _showErrorSnackBar('Failed to load friends: ${e.toString()}');
      }
    }
  }

  Future<void> _unfriendUser(Friend friend) async {
    try {
      final success = await _friendService.removeFriend(friend.id.toString());
      if (success) {
        setState(() {
          _friends.removeWhere((f) => f.id == friend.id);
        });
        _showSuccessSnackBar('Unfriended ${friend.username}');
      } else {
        _showErrorSnackBar('Failed to unfriend ${friend.username}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
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

  void _navigateToSearchScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchFriendsScreen()),
    );

    // If returning from search screen, refresh friends list
    if (result == true) {
      _loadFriends();
    }
  }

  void _showFriendOptions(Friend friend) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_remove),
                title: const Text('Unfriend'),
                onTap: () {
                  Navigator.pop(context);
                  _showUnfriendDialog(context, friend.username, friend);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearchScreen,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black,
          tabs: [
            Tab(
              child: Container(
                color: _tabController.index == 0 ? Colors.orange : Colors.white,
                child: const Center(
                  child: Text(
                    'Friends',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Tab(
              child: Container(
                color: _tabController.index == 1 ? Colors.orange : Colors.white,
                child: const Center(
                  child: Text(
                    'Add New Friends',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
          onTap: (index) {
            setState(() {});
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              // Friends Count
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_friends.length} Friends',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Friends List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : ListView.builder(
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: friend.avatar != null
                            ? NetworkImage(friend.avatar!)
                            : null,
                        child: friend.avatar == null
                            ? Text(friend.username[0].toUpperCase())
                            : null,
                      ),
                      title: Text(
                        friend.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        friend.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () => _showFriendOptions(friend),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Add New Friends Tab
          AddNewFriendsScreen(
            onFriendAdded: () {
              // Refresh the friends list when a friend is added
              _loadFriends();
            },
          ),
        ],
      ),
    );
  }

  void _showUnfriendDialog(BuildContext context, String friendName, Friend friend) {
    showCustomNotice(context, "Unfriend $friendName? Are you sure you want to unfriend $friendName?", "confirm").then((confirmed) {
      if (confirmed == true) {
        _unfriendUser(friend); // Gọi hàm xóa bạn
      }
    });
  }
}