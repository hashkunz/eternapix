import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eternapix/profile/profile.dart';
import 'package:eternapix/home/home.dart';
import 'package:eternapix/bottomnavigationbar/custom_bottom_navigation_bar.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:eternapix/photo/select_category.dart';

class PickerPage extends StatefulWidget {
  @override
  _PickerPageState createState() => _PickerPageState();
}

class _PickerPageState extends State<PickerPage>
    with SingleTickerProviderStateMixin {
  // int _page = 1; // Default to 'add' icon
  int _currentIndex = 1;
  String info = 'Select Category And Upload Picture';
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _controller;
  late Animation<double> _animation;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  bool _isCategoryVisible = false; // State to control visibility
  IconData? selectedIcon;
  String? selectedCategory;

  void selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 10).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) async {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SizeTransition(
              sizeFactor: animation.drive(Tween(begin: 0.0, end: 1.0)),
              child: child,
            );
          },
        ),
      );
    } else if (index == 1) {
      _showImageSourceBottomSheet();
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ProfilePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SizeTransition(
              sizeFactor: animation.drive(Tween(begin: 0.0, end: 1.0)),
              child: child,
            );
          },
        ),
      );
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.25,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.camera_alt, size: 40),
                          onPressed: () {
                            _pickImage(ImageSource.camera);
                            Navigator.of(context).pop();
                          },
                        ),
                        Text('Camera'),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.photo_library, size: 40),
                          onPressed: () {
                            _pickImage(ImageSource.gallery);
                            Navigator.of(context).pop();
                          },
                        ),
                        Text('Gallery'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          info = 'Here is the image you selected';
        });
      } else {
        setState(() {
          info = 'No image selected';
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        info = 'Error selecting image';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage != null) {
      // Check if selectedCategory is null or empty
      if (selectedCategory == null || selectedCategory!.isEmpty) {
        // Show Snackbar if selectedCategory is null or empty
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a category before uploading.'),
          ),
        );
        return; // Exit the function if selectedCategory is null or empty
      }

      try {
        // Get the current user's UID
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String uid = user.uid;

          // Create a reference to the location in Firebase Storage
          Reference storageReference = FirebaseStorage.instance.ref().child(
              'user_posts/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');

          // Upload the file to Firebase Storage
          UploadTask uploadTask = storageReference.putFile(_selectedImage!);
          TaskSnapshot taskSnapshot = await uploadTask;

          // Get the download URL
          String downloadUrl = await taskSnapshot.ref.getDownloadURL();

          // Save the download URL to Firestore
          await FirebaseFirestore.instance
              .collection('categories')
              .doc(uid)
              .collection('userCategories')
              .doc(selectedCategory!)
              .collection('images')
              .add({
            'imagePostUrl': downloadUrl,
            'date': DateTime.now(),
          });

          // Clear the selected image and show confirmation message
          setState(() {
            _selectedImage = null; // Clear the selected image
            info = 'Your image posted now';
          });
        } else {
          setState(() {
            info = 'User not signed in';
          });
        }
      } catch (e) {
        print('Error uploading image: $e');
        setState(() {
          info = 'Error uploading image';
        });
      }
    } else {
      setState(() {
        info = 'No image selected';
      });
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
        _showImageSourceBottomSheet();
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

  void _toggleCategoryVisibility() {
    setState(() {
      _isCategoryVisible = !_isCategoryVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Picker',
            style: TextStyle(
              fontSize: 24,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              IconButton(
                icon: Icon(
                  _isCategoryVisible
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                onPressed: _toggleCategoryVisibility,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: _isCategoryVisible
                              ? Column(
                                  key: ValueKey('visible'),
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        SelectCategory(
                                          icon: Icons.landscape,
                                          onSelect: () =>
                                              selectCategory('Nature'),
                                          isSelected:
                                              selectedCategory == 'Nature',
                                        ),
                                        SelectCategory(
                                          icon: Icons.pets,
                                          onSelect: () =>
                                              selectCategory('Animals'),
                                          isSelected:
                                              selectedCategory == 'Animals',
                                        ),
                                        SelectCategory(
                                          icon: Icons.architecture,
                                          onSelect: () =>
                                              selectCategory('Architecture'),
                                          isSelected: selectedCategory ==
                                              'Architecture',
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        SelectCategory(
                                          icon: Icons.people,
                                          onSelect: () =>
                                              selectCategory('People'),
                                          isSelected:
                                              selectedCategory == 'People',
                                        ),
                                        SelectCategory(
                                          icon: Icons.local_dining,
                                          onSelect: () =>
                                              selectCategory('Food'),
                                          isSelected:
                                              selectedCategory == 'Food',
                                        ),
                                        SelectCategory(
                                          icon: Icons.travel_explore,
                                          onSelect: () =>
                                              selectCategory('Travel'),
                                          isSelected:
                                              selectedCategory == 'Travel',
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : SizedBox.shrink(),
                        ),
                        SizedBox(height: 16),
                        Text(
                          info,
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 16),
                        if (_selectedImage != null)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text('Error loading image');
                                  },
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _uploadImage,
                                child: Text('Upload'),
                              ),
                              SizedBox(height: 50),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom:
                10, // Adjust this value to position the arrow above the bottomNavigationBar
            left: MediaQuery.of(context).size.width * 0.5 -
                22.5, // Center horizontally
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_animation.value),
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 45,
                    color: Colors.black,
                  ),
                );
              },
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
