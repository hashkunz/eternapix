import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DetailsUserPage extends StatefulWidget {
  final String uid; // รับ uid ผ่านคอนสตรัคเตอร์

  DetailsUserPage({required this.uid});

  @override
  _DetailsUserPageState createState() => _DetailsUserPageState();
}

class _DetailsUserPageState extends State<DetailsUserPage> {
  late TextEditingController _controller;
  double _textFieldValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadInitialValues(); // Load initial values from Firestore
    _checkUserRole();
  }

  Future<bool> _checkUserRole() async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc['isAdmin'] == true) {
          // Admin role confirmed
          return true;
        } else {
          // If not an admin, navigate to Unauthorized page
          Navigator.pushReplacementNamed(context, '/unauthorized');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Error checking user role: $e');
      return false;
    }
  }

  void _loadInitialValues() async {
    try {
      var storageDoc = await FirebaseFirestore.instance
          .collection('storages')
          .doc(widget.uid)
          .get();
      double initialMaxStorage = storageDoc['maxStorage']?.toDouble() ?? 1;
      setState(() {
        _textFieldValue = initialMaxStorage;
        _controller.text = _textFieldValue.toString();
      });
    } catch (e) {
      print('Error loading initial values: $e');
    }
  }

  @override
  void dispose() {
    _controller
        .dispose(); // Clean up the controller when the widget is disposed
    super.dispose();
  }

  void _showEditBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Storage',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Adjust the storage (MB):',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1.00 MB', style: TextStyle(fontSize: 14)),
                      Text('${_textFieldValue.toStringAsFixed(2)} MB',
                          style: TextStyle(fontSize: 14)),
                      Text('100.00 MB', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  Slider(
                    value: _textFieldValue,
                    min: 1, // Set minimum value
                    max: 100, // Set maximum value
                    divisions:
                        99, // Create 99 discrete values between 1 and 100
                    label: _textFieldValue.toStringAsFixed(
                        2), // Display value with 2 decimal places
                    onChanged: (value) {
                      setState(() {
                        _textFieldValue = value;
                        _controller.text = _textFieldValue
                            .toStringAsFixed(2); // Update the TextField value
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          bool isAdmin = await _checkUserRole();
                          if (isAdmin) {
                            try {
                              print(
                                  'Updating maxStorage to: ${_textFieldValue.toStringAsFixed(2)}');
                              await FirebaseFirestore.instance
                                  .collection('storages')
                                  .doc(widget.uid)
                                  .update({'maxStorage': _textFieldValue});
                              print('Storage updated successfully');

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Storage updated successfully.'),
                                ),
                              );

                              Navigator.pop(context); // ปิด bottom sheet

                              setState(() {
                                _loadInitialValues(); // รีเฟรชหน้าโดยโหลดค่าใหม่
                              });
                            } catch (e) {
                              print('Failed to update storage: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update storage: $e'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor:
                              const Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: Text('Save'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: Future.wait([
          FirebaseFirestore.instance
              .collection('profiles')
              .doc(widget.uid)
              .get(),
          FirebaseFirestore.instance
              .collection('storages')
              .doc(widget.uid)
              .get(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.any((doc) => !doc.exists)) {
            return Center(child: Text('User not found'));
          }

          var profileDoc = snapshot.data![0];
          var storageDoc = snapshot.data![1];

          String profileImageUrl = profileDoc['imageUrl'] ?? '';
          String formattedDate = '';
          if (storageDoc['lastPost'] is Timestamp) {
            Timestamp timestamp = storageDoc['lastPost'] as Timestamp;
            DateTime dateTime = timestamp.toDate();
            formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      profileDoc['profileName'] ?? 'No Name',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          profileImageUrl.isNotEmpty
                              ? profileImageUrl
                              : 'https://freesvg.org/img/abstract-user-flat-4.png',
                          height: 300,
                          width: screenWidth,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Last Post:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Date: $formattedDate',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Max Storage:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Have: ${storageDoc['maxStorage']?.toString() ?? 'No Max Storage'} MB',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Storage Used:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Used: ${storageDoc['storageUsed']?.toString() ?? 'No Storage Used'} MB',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Profile Description:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      profileDoc['profileDescription'] ?? 'No Description',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Birthday:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      profileDoc['birthdate'] ?? 'No Birthdate',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Email:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      profileDoc['emailUser'] ?? 'No Email',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 70),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: ElevatedButton(
                          onPressed: () {
                            _showEditBottomSheet(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () {
                            // Add functionality for deletion
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
