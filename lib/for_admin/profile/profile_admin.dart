import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:eternapix/settings/setting_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eternapix/for_admin/list/list_users.dart';
import 'package:eternapix/for_admin/feedback/feedback_from_users.dart';
import 'package:eternapix/for_admin/bottomnavigationadminbar/custom_bottom_navigation_admin_bar.dart';

class ProfileAdminPage extends StatefulWidget {
  @override
  _ProfileAdminPageState createState() => _ProfileAdminPageState();
}

class _ProfileAdminPageState extends State<ProfileAdminPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 2; // Default to 'person' icon
  String? _profileImageUrl;
  String _profileDescription = 'Loading...';
  String _profileName = 'Loading...'; // Added profileName
  String _idLine = 'Loading...'; // Added profileName
  String _tel = 'Loading...'; // Added profileName
  final List<Map<String, String>> imageUrls = [];
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  bool _isStoryVisible = false; // State to control visibility

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  void _toggleStoryVisibility() {
    setState(() {
      _isStoryVisible = !_isStoryVisible;
    });
  }

  Future<void> _fetchProfileData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .get();
        setState(() {
          _profileImageUrl = userDoc['imageUrl'] ??
              'https://s.isanook.com/jo/0/ud/494/2471329/ygbabymonster_-17244421174165.jpg'; // Default image URL
          _profileDescription =
              userDoc['profileDescription'] ?? 'No description available';
          _profileName = userDoc['profileName'] ??
              'No name available'; // Fetch profileName
          _idLine = userDoc['idLine'] ?? 'No name available'; // Fetch idLine
          _tel = userDoc['tel'] ?? 'No name available'; // Fetch telephone
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  Future<void> _refreshData() async {
    await _fetchProfileData(); // Call the fetch function to refresh data
  }

  void _onNavigation(int index) {
    switch (index) {
      case 0: // list icon tapped
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ListUsersPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SizeTransition(
                sizeFactor: animation.drive(Tween(begin: 0.0, end: 1.0)),
                child: child,
              );
            },
          ),
        );
        break;
      case 1: // Feedback icon tapped
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ReadFeedbackPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SizeTransition(
                sizeFactor: animation.drive(Tween(begin: 0.0, end: 1.0)),
                child: child,
              );
            },
          ),
        );
        break;
      case 2: // Profile icon tapped
        // Do nothing because we are already on ProfilePage
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(40.0), // Adjust height as needed
          child: AppBar(
            automaticallyImplyLeading: false,
            title: Text(_profileName), // Use fetched profileName
            actions: [
              IconButton(
                icon: Icon(Icons.settings), // Icon for editing profile
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          SettingsPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return SizeTransition(
                          sizeFactor:
                              animation.drive(Tween(begin: 0.0, end: 1.0)),
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 50),
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : NetworkImage(
                            'https://cdn-icons-png.flaticon.com/512/61/61205.png'),
                  ),
                  SizedBox(height: 15),
                  Text(_profileDescription, textAlign: TextAlign.center),
                  Text('ID Line :  $_idLine', textAlign: TextAlign.center),
                  Text('Telephone : $_tel', textAlign: TextAlign.center),
                  SizedBox(height: 20),
                  // Card with profile details
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5, // Add shadow to create dimension
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width *
                          0.8, // 80% of the screen width
                      height: 175, // Custom height
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EternaPix App',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Admin Rank: Silver',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Goodness score: 90 / 100',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                          Spacer(), // Pushes content below upwards
                          Center(
                            child: Text(
                              'Thank you for working hard for us',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavigationAdminBar(
          bottomNavigationKey: _bottomNavigationKey,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          onNavigation: _onNavigation,
        ),
      ),
    );
  }
}
