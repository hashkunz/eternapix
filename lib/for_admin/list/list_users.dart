import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:eternapix/for_admin/profile/profile_admin.dart';
import 'package:eternapix/for_admin/feedback/feedback_from_users.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eternapix/for_admin/profile/create_profile_admin.dart';
import 'package:eternapix/for_admin/bottomnavigationadminbar/custom_bottom_navigation_admin_bar.dart';
import 'package:eternapix/for_admin/list/list_ui.dart';

class ListUsersPage extends StatefulWidget {
  @override
  _ListUsersPageState createState() => _ListUsersPageState();
}

class _ListUsersPageState extends State<ListUsersPage> {
  int _currentIndex = 0;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  User? user;
  int totalUsers = 0;
  List<DocumentSnapshot> usersList = [];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _checkUserProfile();
    await _checkUserRole();
    await _fetchTotalUsers();
    await _fetchUsersList();
  }

  Future<void> _checkUserProfile() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userProfile = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user!.uid)
          .get();
      if (userProfile.exists && userProfile['idLine'] == "00") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CreateProfileAdminPage()),
        );
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _checkUserRole() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user!.uid)
          .get();

      if (userDoc.exists && userDoc['isAdmin'] == true) {
        // Admin role confirmed
      } else {
        Navigator.pushReplacementNamed(context, '/unauthorized');
      }
    }
  }

  Future<void> _fetchTotalUsers() async {
    if (user != null) {
      DocumentSnapshot adminCheck = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user!.uid)
          .get();

      if (adminCheck.exists && adminCheck['isAdmin'] == true) {
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance.collection('profiles').get();

        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            totalUsers = snapshot.size;
          });
        }
      }
    }
  }

  Future<void> _fetchUsersList() async {
    if (user != null) {
      DocumentSnapshot adminCheck = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user!.uid)
          .get();

      if (adminCheck.exists && adminCheck['isAdmin'] == true) {
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance.collection('profiles').get();

        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            usersList = snapshot.docs;
          });
        }
      }
    }
  }

  void _onNavigation(int index) {
    switch (index) {
      case 0:
        // Do nothing because we are already on this page
        break;
      case 1:
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
      case 2:
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProfileAdminPage(),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'EternaPix',
              style: TextStyle(
                fontFamily: 'AppBarHome',
                fontSize: 28,
              ),
            ),
            pinned: true,
            expandedHeight: 60.0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
          SliverFillRemaining(
            child: ListUI(usersList: usersList),
          ),
        ],
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
    );
  }
}
