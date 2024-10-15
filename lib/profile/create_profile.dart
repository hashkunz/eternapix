import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:eternapix/home/home.dart';

class CreateProfilePage extends StatefulWidget {
  @override
  _CreateProfilePageState createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String _profileName = '';
  String _profileDescription = '';
  String _birthdate = '';
  String _idLine = '00';
  String _tel = 'xx';
  int _maxStorage = 50;
  int _storageUsed = 0;
  String _imageUrl = '';
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile(); // Load current profile data when page loads
  }

  // Function to load current profile data from Firestore
  Future<void> _loadCurrentProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();

      if (profileSnapshot.exists) {
        Map<String, dynamic> profileData =
            profileSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _profileName = profileData['profileName'] ?? '';
          _profileDescription = profileData['profileDescription'] ?? '';
          _birthdate = profileData['birthdate'] ?? '';
          _imageUrl = profileData['imageUrl'] ?? '';
        });
      }
    }
  }

  // Function to pick image using ImagePicker
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Upload image to Firebase Storage
          String fileName = 'user_profiles/${user.uid}/profile_image.jpg';
          Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
          await storageRef.putFile(File(image.path));

          // Get the download URL and update the _imageUrl state
          String downloadUrl = await storageRef.getDownloadURL();
          setState(() {
            _imageUrl = downloadUrl;
          });

          // Update the Firestore with the image URL
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(user.uid)
              .update({'imageUrl': _imageUrl});
        }
      } catch (e) {
        // Handle the error here
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image')),
        );
      }
    }
  }

  // Function to update profile data
  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // If user is not logged in, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      // Retrieve current email and userID from the authenticated user
      String uid = user.uid;
      String email = user.email ?? '';

      // Create a Map object to store the updated profile data
      Map<String, dynamic> updatedProfileData = {
        'userID': uid,
        'emailUser': email,
        'profileName': _profileName,
        'profileDescription': _profileDescription,
        'birthdate': _birthdate,
        'tel': _tel,
        'idLine': _idLine,
        'imageUrl': _imageUrl,
      };

      Map<String, dynamic> updatedStoragesData = {
        'userID': uid,
        'maxStorage': _maxStorage,
        'storageUsed': _storageUsed,
      };

      // Update the profile data in Firestore
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(uid)
          .update(updatedProfileData);

      // Update the profile data in Firestore
      await FirebaseFirestore.instance
          .collection('storages')
          .doc(uid)
          .update(updatedStoragesData);

      // Notify the user that the profile has been updated
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile Created')),
      );

      // Pop the current page and go back to Home
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40.0),
        child: AppBar(
          title: Text('Create Profile'),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    clipBehavior: Clip.none, // เพื่อให้ไอคอนปากกาไม่ถูกตัด
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(File(_imageFile!.path))
                            : _imageUrl.isNotEmpty
                                ? NetworkImage(_imageUrl)
                                : null,
                        child: _imageFile == null && _imageUrl.isEmpty
                            ? Icon(Icons.add_a_photo, size: 50)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  initialValue: _profileName,
                  decoration: InputDecoration(
                    labelText: 'Profile Name',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // ปรับค่าตามต้องการ
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // ปรับค่าตามต้องการ
                      borderSide: BorderSide(
                          color: Colors.blue,
                          width: 2.0), // ขอบตอนที่มีการโฟกัส
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // ปรับค่าตามต้องการ
                      borderSide: BorderSide(
                          color: Colors.grey, width: 1.0), // ขอบตอนที่ไม่โฟกัส
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a profile name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _profileName = value!;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  initialValue: _profileDescription,
                  decoration: InputDecoration(
                    labelText: 'Profile Description',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // ปรับค่าตามต้องการ
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // ปรับค่าตามต้องการ
                      borderSide: BorderSide(
                          color: Colors.blue,
                          width: 2.0), // ขอบตอนที่มีการโฟกัส
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // ปรับค่าตามต้องการ
                      borderSide: BorderSide(
                          color: Colors.grey, width: 1.0), // ขอบตอนที่ไม่โฟกัส
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a profile description';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _profileDescription = value!;
                  },
                ),
                SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    DateTime? tempPickedDate;

                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled:
                          true, // ให้ BottomSheet สามารถใช้พื้นที่หน้าจอได้มากขึ้น
                      builder: (BuildContext context) {
                        return FractionallySizedBox(
                          heightFactor: 0.5, // ใช้ 50% ของความสูงหน้าจอ
                          child: Wrap(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CalendarDatePicker(
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                      onDateChanged: (DateTime date) {
                                        tempPickedDate = date;
                                      },
                                    ),
                                    SizedBox(height: 16.0),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(
                                                context, tempPickedDate);
                                          },
                                          child: Text('Save'),
                                        ),
                                        SizedBox(width: 10),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).then((pickedDate) {
                      if (pickedDate != null) {
                        setState(() {
                          _birthdate =
                              "${pickedDate!.day.toString().padLeft(2, '0')}/${pickedDate!.month.toString().padLeft(2, '0')}/${pickedDate!.year}";
                        });
                      }
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Birthdate (DD/MM/YYYY)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide(color: Colors.blue, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                    ),
                    child: Text(
                      _birthdate.isNotEmpty
                          ? _birthdate
                          : 'Please select your birthdate',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _updateProfile,
                  child: Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
