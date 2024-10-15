import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:eternapix/for_admin/bottomnavigationadminbar/custom_bottom_navigation_admin_bar.dart';
import 'package:eternapix/for_admin/profile/profile_admin.dart';
import 'package:eternapix/for_admin/list/list_users.dart';
import 'package:eternapix/for_admin/feedback/card_feedback.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReadFeedbackPage extends StatefulWidget {
  @override
  _ReadFeedbackPageState createState() => _ReadFeedbackPageState();
}

class _ReadFeedbackPageState extends State<ReadFeedbackPage> {
  int _currentIndex = 1;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  String? _selectedStar; // For star filter
  String? _selectedDate; // For date filter
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  // Method to check if the user is an admin
  Future<void> _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc['isAdmin'] == true) {
        setState(() {
          _isAdmin = true;
        });
      } else {
        Navigator.pushReplacementNamed(context, '/unauthorized');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Widget for filtering form
  Widget _buildSearchForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Filter by Stars',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedStar,
                  items: ['1', '2', '3', '4', '5']
                      .map((star) => DropdownMenuItem<String>(
                            value: star,
                            child: Text('$star Stars'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStar = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Filter by Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedDate,
                  items: ['Last 7 Days', 'Last 30 Days', 'Last Year']
                      .map((dateRange) => DropdownMenuItem<String>(
                            value: dateRange,
                            child: Text(dateRange),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDate = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Feedback',
              style: TextStyle(
                fontFamily: 'AppBarHome',
                fontSize: 28,
              ),
            ),
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([_buildSearchForm()]),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('user_feedback')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(child: Text('No feedback found.')),
                );
              }

              if (!_isAdmin) {
                return SliverFillRemaining(
                  child: Center(child: Text('Unauthorized access.')),
                );
              }

              // Filter the feedback based on star and date criteria
              var filteredDocs = snapshot.data!.docs.where((doc) {
                var feedbackData = doc.data() as Map<String, dynamic>;

                bool matchesStar = _selectedStar == null ||
                    feedbackData['star'].toString() == _selectedStar;
                bool matchesDate = _selectedDate == null ||
                    _filterByDate(feedbackData['date'], _selectedDate!);

                return matchesStar && matchesDate;
              }).toList();

              if (filteredDocs.isEmpty) {
                return SliverFillRemaining(
                  child:
                      Center(child: Text('No feedback matches your search.')),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    var feedbackDoc = filteredDocs[index];
                    var feedbackData =
                        feedbackDoc.data() as Map<String, dynamic>;

                    String profileName =
                        feedbackData['profileName'] ?? 'Unknown';
                    String feedbackText = feedbackData['feedback'] ?? '';
                    Timestamp date = feedbackData['date'] ?? Timestamp.now();
                    int star = feedbackData['star'] ?? 0;

                    return FeedbackCard(
                      userName: profileName,
                      feedback: feedbackText,
                      date: date,
                      star: star,
                    );
                  },
                  childCount: filteredDocs.length,
                ),
              );
            },
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

  // Function to filter feedback by date
  bool _filterByDate(Timestamp feedbackDate, String selectedDateRange) {
    DateTime feedbackDateTime = feedbackDate.toDate();
    DateTime now = DateTime.now();
    if (selectedDateRange == 'Last 7 Days') {
      return feedbackDateTime.isAfter(now.subtract(Duration(days: 7)));
    } else if (selectedDateRange == 'Last 30 Days') {
      return feedbackDateTime.isAfter(now.subtract(Duration(days: 30)));
    } else if (selectedDateRange == 'Last Year') {
      return feedbackDateTime.isAfter(now.subtract(Duration(days: 365)));
    }
    return true;
  }

  // Function for handling the navigation
  void _onNavigation(int index) {
    switch (index) {
      case 0:
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
      case 1:
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
}
