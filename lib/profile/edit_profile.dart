import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:eternapix/profile/profile.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String _profileName = '';
  String _profileDescription = '';
  String _birthdate = '';
  String _imageUrl = '';
  String? _email;
  String? _uid;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  TextEditingController _profileNameController = TextEditingController();
  TextEditingController _profileDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _uid = user.uid;
      _email = user.email;

      DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(_uid)
          .get();

      if (profileSnapshot.exists) {
        Map<String, dynamic> profileData =
            profileSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _profileNameController.text = profileData['profileName'] ?? '';
          _profileDescriptionController.text =
              profileData['profileDescription'] ?? '';
          _birthdate = profileData['birthdate'] ?? '';
          _imageUrl = profileData['imageUrl'] ?? '';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Set selected image to state
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _uploadImageAndSaveProfile() async {
    if (_imageFile != null && _uid != null) {
      // Delete the old image from Storage if it exists
      if (_imageUrl.isNotEmpty) {
        try {
          // Create a reference from the old image URL
          Reference oldImageRef =
              FirebaseStorage.instance.refFromURL(_imageUrl);
          await oldImageRef.delete();
        } catch (e) {
          print('Error deleting old image: $e');
          // Optionally, show a message to the user or handle the error as needed
        }
      }

      try {
        // Upload the new image to Storage
        Reference storageRef = FirebaseStorage.instance.ref().child(
            'user_profiles/$_uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
        UploadTask uploadTask = storageRef.putFile(File(_imageFile!.path));
        TaskSnapshot storageSnapshot =
            await uploadTask.whenComplete(() => null);

        // Get the URL of the newly uploaded image
        String downloadUrl = await storageSnapshot.ref.getDownloadURL();

        // Update the new URL in Firestore
        setState(() {
          _imageUrl = downloadUrl;
        });
      } catch (e) {
        print('Error uploading new image: $e');
        // Handle upload errors here, maybe show an error message to the user
      }
    }

    // Call _saveProfile to update the profile with the new image URL
    _saveProfile();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_uid != null) {
        Map<String, dynamic> updatedProfileData = {
          'userID': _uid,
          'emailUser': _email,
          'profileName': _profileNameController.text,
          'profileDescription': _profileDescriptionController.text,
          'birthdate': _birthdate,
          'imageUrl': _imageUrl,
        };

        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(_uid)
            .update(updatedProfileData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile Updated')),
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProfilePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: Tween(begin: 1.0, end: 1.0).animate(animation),
                child: child,
              );
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40.0),
        child: AppBar(
          title: Text('Edit Profile'),
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
                  controller: _profileNameController,
                  decoration: InputDecoration(
                    labelText: 'Profile Name',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // Adjust as needed
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // Adjust as needed
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide(color: Colors.grey, width: 1.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      print(_profileName);
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
                  controller: _profileDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Profile Description',
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
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      print(_profileDescription);
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
                  onPressed: _uploadImageAndSaveProfile,
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
