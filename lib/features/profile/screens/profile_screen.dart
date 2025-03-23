import 'package:flutter/material.dart';
import 'package:lokaloka/features/auth/services/auth_services.dart';
import 'package:lokaloka/features/auth/models/user.dart';
import 'package:lokaloka/features/profile/services/profile_services.dart';
import 'package:lokaloka/globals.dart';
import '../../../core/styles/colors.dart';
import 'profile_header.dart';
import 'account_tab.dart';
import 'home_tab.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserNormal? user;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      String? token = await AuthService().getToken();
      if (token == null) {
        setState(() {
          error = "No token available. Please log in again.";
          isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await ProfileService().getUserProfile();
      if (response != null) {
        setState(() {
          user = response;
          trustPhone = user?.emergency_numbers;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to fetch user profile";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error: No internet connection."
            "\nPlease turn on Wi-Fi or mobile data";
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
        title: Text('Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
                alignment: Alignment.center,
                child: Text(error!, style: TextStyle(color: Colors.red))),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchUserProfile,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (user == null) {
      return Center(child: Text('No user data available'));
    }

    return Column(
      children: [
        ProfileHeader(user: user!),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.orangeColor,
          unselectedLabelColor: Colors.black,
          indicatorColor: AppColors.orangeColor,
          tabs: [
            Tab(text: "My Home"),
            Tab(text: "Account"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              HomeTab(),
              AccountTab(
                user: user!,
                onProfileUpdated: _fetchUserProfile,
              ),
            ],
          ),
        ),
      ],
    );
  }
}