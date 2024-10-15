import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final GlobalKey<CurvedNavigationBarState> bottomNavigationKey;
  final int currentIndex;
  final Function(int) onTap;
  final Function(int) onNavigation;

  CustomBottomNavigationBar({
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
        Icon(Icons.home, size: 30),
        Icon(Icons.add, size: 30),
        Icon(Icons.person, size: 30),
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
