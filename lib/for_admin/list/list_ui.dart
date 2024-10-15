// lib/widgets/list_ui.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eternapix/for_admin/details/details_user.dart'; // Import your DetailsUser page

class ListUI extends StatefulWidget {
  final List<DocumentSnapshot> usersList;

  ListUI({required this.usersList});

  @override
  _ListUIState createState() => _ListUIState();
}

class _ListUIState extends State<ListUI> {
  String searchTerm = '';

  @override
  Widget build(BuildContext context) {
    // Filter users based on searchTerm
    List<DocumentSnapshot> filteredUsers = widget.usersList.where((userDoc) {
      String name = userDoc['profileName']?.toLowerCase() ?? '';
      String uid = userDoc.id.toLowerCase();
      return name.contains(searchTerm.toLowerCase()) ||
          uid.contains(searchTerm.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Display the number of users at the top
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.usersList.length}', // Display the total number of users
                style: TextStyle(
                  fontSize: 100, // Large number size
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'users',
                style: TextStyle(
                  fontSize: 24, // Size of the word 'users'
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 25),
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchTerm = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Search by name or UID',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    30), // Rounded corners for the search box
              ),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              var userDoc = filteredUsers[index];
              String imageUrl = userDoc['imageUrl'] ?? ''; // Get image URL
              String uid = userDoc.id; // Get UID from document ID
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16), // Padding inside the tile
                  leading: CircleAvatar(
                    backgroundImage: imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : NetworkImage(
                            'https://freesvg.org/img/abstract-user-flat-4.png'), // Default image if URL is empty
                  ),
                  title: Text(
                    userDoc['profileName'] ?? 'No Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(userDoc['emailUser'] ?? 'No Email'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _navigateToDetails(context, uid),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToDetails(BuildContext context, String uid) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailsUserPage(uid: uid),
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
