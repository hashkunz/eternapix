import 'package:flutter/material.dart';
import 'package:eternapix/profile/create_profile.dart'; // Import CreateProfilePage
import 'package:eternapix/photo/picker.dart'; // Import PickerPage
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eternapix/profile/profile.dart'; // Import ProfilePage
import 'package:eternapix/bottomnavigationbar/custom_bottom_navigation_bar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedFilter = 'All';
  User? user;
  final List<Map<String, dynamic>> posts = [];
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey =
      GlobalKey<CurvedNavigationBarState>();
  int _currentIndex = 0;
  int itemsToLoad = 6; // จำนวนรูปที่ต้องการโหลดในครั้งแรก
  ScrollController _scrollController = ScrollController(); // ScrollController

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
    _fetchUserPhotos();

    // เพิ่มการฟังการเลื่อนของ ScrollController
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMorePhotos(); // โหลดรูปเพิ่มเติมเมื่อเลื่อนไปถึงจุดสิ้นสุด
      }
    });
  }

  Future<void> _checkUserProfile() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userProfile = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user!.uid)
          .get();
      if (userProfile.exists && userProfile['profileName'] == "Unknown") {
        // Navigate to CreateProfilePage if profileName is "Unknown"
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CreateProfilePage()),
        );
      }
    } else {
      // Handle case where user is not logged in
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _fetchUserPhotos() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        List<String> categories = [
          'Animals',
          'Nature',
          'Architecture',
          'Food',
          'People',
          'Travel',
        ];

        // Clear existing posts
        posts.clear();

        // Loop through each category and fetch images
        for (String category in categories) {
          QuerySnapshot userImagesSnapshot = await FirebaseFirestore.instance
              .collection('categories')
              .doc(user.uid)
              .collection('userCategories')
              .doc(category)
              .collection('images')
              .get();

          // Add images from this category to posts
          posts.addAll(userImagesSnapshot.docs.map((doc) {
            Timestamp timestamp = doc['date']; // Assuming 'date' is a Timestamp
            DateTime dateTime =
                timestamp.toDate(); // Convert Timestamp to DateTime
            String formattedDate =
                "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";

            return {
              'date': formattedDate, // Format the DateTime as needed
              'imagePostUrl': doc['imagePostUrl'] ??
                  '', // Provide a default value if 'imagePostUrl' is missing
              'timestamp': dateTime // Keep the original timestamp for sorting
            };
          }).toList());
        }

        // Sort posts by timestamp in descending order to have the latest first
        posts.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        // Update state after fetching and sorting all images
        setState(() {});
      } catch (e) {
        // Handle any errors that occur during fetching
        print('Error fetching user images: $e');
      }
    }
  }

  void _loadMorePhotos() {
    // Load additional photos if there are more available
    setState(() {
      itemsToLoad += 6; // เพิ่มจำนวนรูปที่โหลดในแต่ละครั้ง
    });
  }

  List<String> get filterOptions {
    Set<String> months = {'All'};
    for (var post in posts) {
      String month = post['date']!
          .split('-')[1]; // Extract the month from the formatted date
      months.add(month);
    }
    return months.toList();
  }

  List<Map<String, dynamic>> get filteredPosts {
    if (selectedFilter == 'All') {
      return posts.take(itemsToLoad).toList(); // แสดงรูปตามจำนวนที่โหลด
    } else {
      return posts
          .where((post) => post['date']!.contains(selectedFilter))
          .take(itemsToLoad)
          .toList(); // แสดงรูปตามจำนวนที่โหลด
    }
  }

  void _onNavigation(int index) {
    switch (index) {
      case 0: // Home icon tapped
        // Do nothing because we are already on Homepage
        break;
      case 1: // Add icon tapped
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PickerPage(),
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
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProfilePage(),
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
        controller: _scrollController, // เชื่อม ScrollController
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'EternaPix',
              style: TextStyle(
                fontFamily: 'AppBarHome', // ชื่อฟอนต์ที่คุณกำหนดใน pubspec.yaml
                fontSize: 28, // ปรับขนาดตัวอักษรตามต้องการ
              ),
            ),
            pinned: true, // To keep the AppBar visible at the top
            expandedHeight: 100.0, // Height when expanded
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color.fromARGB(255, 255, 255, 255),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilterWidget(
                      options: filterOptions,
                      selectedFilter: selectedFilter,
                      onFilterSelected: (newValue) {
                        setState(() {
                          selectedFilter = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return PostWidget(
                  date: filteredPosts[index]['date']!,
                  imageUrl: filteredPosts[index]['imagePostUrl']!,
                );
              },
              childCount: filteredPosts.length,
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
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

class PostWidget extends StatelessWidget {
  final String date;
  final String imageUrl;

  PostWidget({required this.date, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            date,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(imageUrl),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterWidget extends StatelessWidget {
  final List<String> options;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  FilterWidget({
    required this.options,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  String _getMonthName(String monthNumber) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    int monthIndex = int.tryParse(monthNumber) ?? 0;
    return monthIndex >= 1 && monthIndex <= 12
        ? monthNames[monthIndex - 1]
        : 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      height: 50.0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Enable horizontal scrolling
        child: Row(
          children: options.map((option) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () => onFilterSelected(option),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedFilter == option
                      ? const Color.fromARGB(255, 106, 188, 255)
                      : const Color.fromARGB(
                          255, 255, 255, 255), // Background color
                  shape: StadiumBorder(), // Rounded shape
                ),
                child: Text(
                  _getMonthName(option),
                  style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
