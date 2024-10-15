import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:eternapix/screens/login_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  Future<void> _submitFeedback(
      BuildContext context, String feedback, double rating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in");
      return;
    }

    final uid = user.uid;
    final profileName = await _fetchProfileName(uid);

    if (profileName == null) {
      print("Profile not found");
      return;
    }

    if (rating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Please select a star rating before submitting")),
      );
      return;
    }

    final feedbackData = {
      'profileName': profileName,
      'date': Timestamp.now(),
      'feedback': feedback,
      'star': rating.toInt(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(uid)
          .collection('user_feedback')
          .add(feedbackData);
      print("Feedback submitted successfully");
    } catch (e) {
      print('Error submitting feedback: $e');
    }
  }

  Future<String?> _fetchProfileName(String uid) async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(uid)
          .get();
      if (profileDoc.exists) {
        return profileDoc.data()?['profileName'] as String?;
      }
    } catch (e) {
      print('Error fetching profile name: $e');
    }
    return null;
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      print('User signed out successfully');
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign out failed")),
      );
    }
  }

  Future<void> _reauthenticateUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No user logged in")),
      );
      return;
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: 'user-password-here', // Fetch or request the user's password
    );

    try {
      await user.reauthenticateWithCredential(credential);
      print('User reauthenticated successfully.');
    } catch (e) {
      print('Error reauthenticating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Reauthentication required. Please log in again.")),
      );
      // Optionally redirect to login screen
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User is not authenticated")),
      );
      return;
    }

    // Reauthenticate the user before proceeding with sensitive operations
    await _reauthenticateUser(context);

    final String? uid = user.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User is not authenticated")),
      );
      return;
    }

    try {
      // Proceed with deleting user collections and account
      await _deleteUserCollections(uid);

      await user.delete();
      print('User account deleted successfully');

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      print('Error deleting account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account deletion failed")),
      );
    }
  }

  Future<void> _deleteUserCollections(String uid) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      Future<void> deleteSubcollections(
          DocumentReference docRef, List<String> subcollectionNames) async {
        for (var subcollection in subcollectionNames) {
          final subDocs = await docRef.collection(subcollection).get();
          for (var subDoc in subDocs.docs) {
            await subDoc.reference.delete();
            print('${subDoc.reference.path} subdocument deleted successfully.');
          }
        }
      }

      final collections = [
        {
          'ref': firestore.collection('profiles').doc(uid),
          'subcollections': <String>[],
        },
        {
          'ref': firestore.collection('storages').doc(uid),
          'subcollections': <String>[],
        },
        {
          'ref': firestore.collection('categories').doc(uid),
          'subcollections': <String>['userCategories'],
        },
        {
          'ref': firestore.collection('feedbacks').doc(uid),
          'subcollections': <String>['user_feedback'],
        },
        {
          'ref': firestore.collection('photos').doc(uid),
          'subcollections': <String>['user_photos'],
        },
      ];

      for (var entry in collections) {
        final docRef = entry['ref'] as DocumentReference;
        final subcollections =
            (entry['subcollections'] as List<dynamic>).cast<String>();

        await deleteSubcollections(docRef, subcollections);

        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          await docRef.delete();
          print('${docRef.path} document deleted successfully.');
        }
      }

      print('All user data processed for deletion.');
    } catch (e) {
      print('Error deleting user data: $e');
      throw e;
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    final _feedbackController = TextEditingController();
    double _rating = 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 500,
                ),
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Send Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'Please enter your feedback below:',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Expanded(
                      child: SingleChildScrollView(
                        child: TextField(
                          controller: _feedbackController,
                          decoration: InputDecoration(
                            hintText: 'Enter your feedback here',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'Rate your experience:',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    RatingBar.builder(
                      initialRating: 0,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancel'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        TextButton(
                          onPressed: _feedbackController.text.isNotEmpty &&
                                  _rating > 0
                              ? () {
                                  final feedback = _feedbackController.text;
                                  _submitFeedback(context, feedback, _rating);
                                  Navigator.of(context).pop();
                                }
                              : null,
                          child: Text('Submit'),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                _feedbackController.text.isNotEmpty &&
                                        _rating > 0
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login': (context) => LoginScreen(), // Define your login page here
      },
      home: Scaffold(
        backgroundColor:
            const Color.fromARGB(255, 255, 255, 255).withOpacity(.94),
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            "Settings",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView(
            children: [
              SettingsGroup(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                items: [
                  SettingsItem(
                    onTap: () {},
                    icons: CupertinoIcons.pencil_outline,
                    iconStyle: IconStyle(),
                    title: 'Appearance',
                    subtitle: "Make Ziar'App yours",
                  ),
                  SettingsItem(
                    onTap: () {},
                    icons: Icons.dark_mode_rounded,
                    iconStyle: IconStyle(
                      iconsColor: Colors.white,
                      withBackground: true,
                      backgroundColor: Colors.red,
                    ),
                    title: 'Dark mode',
                    subtitle: "Automatic",
                    trailing: Switch.adaptive(
                      value: false,
                      onChanged: (value) {},
                    ),
                  ),
                ],
              ),
              SettingsGroup(
                items: [
                  SettingsItem(
                    onTap: () {
                      _showFeedbackDialog(context);
                    },
                    icons: Icons.feedback,
                    iconStyle: IconStyle(
                      backgroundColor: const Color.fromARGB(255, 31, 157, 19),
                    ),
                    title: 'Feedback',
                    subtitle: "send your feedback",
                  ),
                  SettingsItem(
                    onTap: () {},
                    icons: Icons.info_rounded,
                    iconStyle: IconStyle(
                      backgroundColor: Colors.purple,
                    ),
                    title: 'About',
                    subtitle: "Learn more about EternaPix'App",
                  ),
                ],
              ),
              SettingsGroup(
                settingsGroupTitle: "Account",
                items: [
                  SettingsItem(
                    onTap: () => _signOut(context),
                    icons: Icons.exit_to_app_rounded,
                    title: "Sign Out",
                  ),
                  SettingsItem(
                    onTap: () async {
                      bool confirm = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Confirm Delete Account"),
                            content: Text(
                                "Are you sure you want to delete your account? This action cannot be undone."),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                                child: Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: Text("Delete"),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        await _deleteAccount(context);
                      }
                    },
                    icons: CupertinoIcons.delete_solid,
                    title: "Delete Account",
                    iconStyle: IconStyle(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
