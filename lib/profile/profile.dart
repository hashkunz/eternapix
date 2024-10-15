import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:eternapix/photo/picker.dart';
import 'package:eternapix/home/home.dart';
import 'package:eternapix/settings/setting_page.dart';
import 'package:eternapix/profile/edit_profile.dart';
import 'package:eternapix/profile/category_profile.dart';
import 'package:eternapix/profile/grid_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eternapix/profile/highlights_profile.dart';
import 'package:eternapix/bottomnavigationbar/custom_bottom_navigation_bar.dart';
import 'package:eternapix/profile/storage_usage_widget.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 2; // Default to 'person' icon
  String? _profileImageUrl;
  String _profileDescription = 'Loading...';
  String _birthdate = 'Loading...';
  String _profileName = 'Loading...'; // Added profileName
  int _postCount = 0; // Variable to hold post count
  final List<Map<String, String>> imageUrls = [];
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  bool _isStoryVisible = false; // State to control visibility

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _fetchPostData(); // Fetch the image post URLs
    _fetchStories();
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
          _birthdate = userDoc['birthdate'] ?? 'No birthdate available';
          _profileName = userDoc['profileName'] ??
              'No name available'; // Fetch profileName
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  Future<void> _fetchPostData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<String> categories = [
          'Animals',
          'Nature',
          'Architecture',
          'Food',
          'People',
          'Travel'
        ];

        List<Map<String, dynamic>> fetchedItems =
            []; // เปลี่ยนเป็น dynamic เพื่อรองรับ Timestamp
        int totalPostCount = 0;

        for (String category in categories) {
          QuerySnapshot snapshot = await FirebaseFirestore.instance
              .collection('categories')
              .doc(user.uid)
              .collection('userCategories')
              .doc(category)
              .collection('images')
              .orderBy('date', descending: true) // เรียงลำดับจากล่าสุดไปเก่า
              .get();

          for (var doc in snapshot.docs) {
            String? imageUrl = doc['imagePostUrl'] as String?;
            Timestamp timestamp = doc['date']; // ดึง Timestamp
            if (imageUrl != null) {
              fetchedItems.add({
                'url': imageUrl,
                'id': doc.id,
                'category': category,
                'timestamp': timestamp, // เก็บ Timestamp เพื่อใช้ในการเรียง
              });
            }
          }

          totalPostCount += snapshot.docs.length;
        }

        // เรียง fetchedItems ตาม Timestamp
        fetchedItems.sort(
            (a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp']));

        setState(() {
          imageUrls.clear();
          imageUrls.addAll(fetchedItems.map((item) {
            return item.map((key, value) => MapEntry(key, value.toString()));
          }).toList());
          _postCount = totalPostCount;
        });

        // print("Fetched image items: $imageUrls");
      }
    } catch (e) {
      print('Error fetching post data: $e');
    }
  }

  Future<void> _refreshData() async {
    await _fetchProfileData(); // Call the fetch function to refresh data
    await _fetchPostData(); // Refresh the post data
    await _fetchStories();
  }

  Future<void> _deleteImageFromFirestore(String photoId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // กำหนดหมวดหมู่ที่มี
        List<String> categories = [
          'Animals',
          'Nature',
          'Architecture',
          'Food',
          'People',
          'Travel'
        ];

        String? categoryToDelete; // ตัวแปรสำหรับเก็บหมวดหมู่ที่จะลบ
        // ตรวจสอบว่า photoId อยู่ในหมวดหมู่ไหน
        for (String category in categories) {
          DocumentSnapshot snapshot = await FirebaseFirestore.instance
              .collection('categories')
              .doc(user.uid)
              .collection('userCategories')
              .doc(category)
              .collection('images')
              .doc(photoId)
              .get();

          if (snapshot.exists) {
            categoryToDelete = category; // หากพบให้กำหนดหมวดหมู่
            break; // ออกจากลูปเมื่อพบหมวดหมู่ที่ตรงกัน
          }
        }

        if (categoryToDelete != null) {
          // ลบรูปภาพจาก Firestore
          await FirebaseFirestore.instance
              .collection('categories')
              .doc(user.uid)
              .collection('userCategories')
              .doc(categoryToDelete) // ใช้หมวดหมู่ที่พบ
              .collection('images')
              .doc(photoId)
              .delete();

          setState(() {
            // อัปเดตสถานะหลังจากลบ
            imageUrls.removeWhere((image) => image['id'] == photoId);
            _postCount--; // ลดจำนวนโพสต์ลง
          });
        } else {
          print('No category found for photo ID: $photoId');
        }
      }
    } catch (e) {
      print('Error deleting image from Firestore: $e');
    }
  }

  void _onNavigation(int index) {
    switch (index) {
      case 0: // Home icon tapped
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
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
        // Do nothing because we are already on ProfilePage
        break;
    }
  }

  Future<List<StoryWidget>> _fetchStories() async {
    List<StoryWidget> stories = [];
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<String> categories = [
          'Animals',
          'Nature',
          'Architecture',
          'Food',
          'People',
          'Travel'
        ];

        // สร้าง Map เพื่อเก็บ URL ของภาพตามช่วงเวลา
        Map<String, List<String>> storiesMap = {
          '1 week ago': [],
          '1 month ago': []
        };

        for (String category in categories) {
          // ดึงข้อมูลจากแต่ละหมวดหมู่ของผู้ใช้งาน
          QuerySnapshot snapshot = await FirebaseFirestore.instance
              .collection('categories')
              .doc(user.uid)
              .collection('userCategories')
              .doc(category)
              .collection('images')
              .get();

          for (var doc in snapshot.docs) {
            String imageUrl = doc['imagePostUrl'];
            Timestamp timestamp = doc['date'];

            // คำนวณระยะห่างระหว่างวันที่ปัจจุบันกับวันเวลาของรูปภาพ
            Duration difference = DateTime.now().difference(timestamp.toDate());

            // เช็คว่าเวลาห่างครบ 1 เดือนหรือ 1 ปี
            if (difference.inDays >= 30) {
              storiesMap['1 month ago']!
                  .add(imageUrl); // เพิ่ม URL สำหรับ 1 เดือน
            } else if (difference.inDays >= 7) {
              storiesMap['1 week ago']!.add(imageUrl); // เพิ่ม URL สำหรับ 1 ปี
            }
          }
        }

        // สร้าง StoryWidget สำหรับแต่ละรายการใน storiesMap
        storiesMap.forEach((timeAgo, imageUrls) {
          if (imageUrls.isNotEmpty) {
            print(
                '$timeAgo: ${imageUrls.length} images'); // แสดงจำนวนภาพในแต่ละช่วงเวลา
            // print('Image URLs: $imageUrls'); // แสดง URL ของภาพ
            stories.add(StoryWidget(imageUrls: imageUrls, timeAgo: timeAgo));
          }
        });
      }
    } catch (e) {
      print('Error fetching stories: $e');
    }

    // คืนค่ารายการ stories ที่มีเฉพาะ 1 สัปดาห์และ 1 เดือน
    return stories;
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
            child: Column(
              children: [
                SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : NetworkImage(
                          'https://cdn-icons-png.flaticon.com/512/61/61205.png'), // Use your default image URL directly
                ),
                SizedBox(height: 5),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            EditProfilePage(),
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
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                Text('$_postCount', // Display the post count
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Posts'),
                SizedBox(height: 10),
                Text(_profileDescription),
                Text(_birthdate),
                SizedBox(height: 5),
                IconButton(
                  icon: Icon(
                    _isStoryVisible
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: _toggleStoryVisibility,
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _isStoryVisible
                      ? Column(
                          key: ValueKey('visible'),
                          children: [
                            SizedBox(height: 8),
                            FutureBuilder<List<StoryWidget>>(
                              future: _fetchStories(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Center(
                                      child: Text('No stories available'));
                                }

                                final List<StoryWidget> stories =
                                    snapshot.data!;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // แสดง StoryWidget สำหรับ 1 week ago
                                    if (stories.any((story) =>
                                        story.timeAgo == '1 week ago'))
                                      stories.firstWhere((story) =>
                                          story.timeAgo == '1 week ago'),
                                    SizedBox(width: 20),
                                    // แสดง StoryWidget สำหรับ 1 month ago
                                    if (stories.any((story) =>
                                        story.timeAgo == '1 month ago'))
                                      stories.firstWhere((story) =>
                                          story.timeAgo == '1 month ago'),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: 20),
                          ],
                        )
                      : SizedBox.shrink(),
                ),
                SizedBox(height: 5),
                StorageUsageWidget(),

                // Code Tab For Here
                TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.portrait)),
                    Tab(icon: Icon(Icons.grid_on)),
                  ],
                ),
                SizedBox(
                    height: 10), // Add spacing between TabBar and TabBarView
                SizedBox(
                  height: 400, // Adjust as needed
                  child: TabBarView(
                    children: [
                      GridImagePage(
                        imageUrls: imageUrls,
                        onDeleteImage: _deleteImageFromFirestore,
                      ),
                      CategoryImagePage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      ),
    );
  }
}
