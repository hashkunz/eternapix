import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class CustomBottomNavigationAdminBar extends StatelessWidget {
  final GlobalKey<CurvedNavigationBarState> bottomNavigationKey;
  final int currentIndex;
  final Function(int) onTap;
  final Function(int) onNavigation;

  CustomBottomNavigationAdminBar({
    required this.bottomNavigationKey,
    required this.currentIndex,
    required this.onTap,
    required this.onNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      key: bottomNavigationKey,
      index: currentIndex,
      height: 60.0,
      items: <Widget>[
        Icon(Icons.view_list, size: 30),
        Icon(Icons.comment, size: 30),
        Icon(Icons.account_circle, size: 30),
      ],
      color: Colors.white,
      buttonBackgroundColor: Colors.white,
      backgroundColor: Colors.blueAccent,
      animationCurve: Curves.easeInOut,
      animationDuration: Duration(milliseconds: 300),
      onTap: (index) {
        onTap(index);
        onNavigation(index); // Trigger navigation logic
      },
    );
  }
}
