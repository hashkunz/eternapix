import 'package:flutter/material.dart';
import 'package:eternapix/screens/login_screen.dart'; // Import LoginScreen
import 'package:firebase_core/firebase_core.dart';
import 'service/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Failed to initialize Firebase: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login', // Set initial route
      routes: {
        '/login': (context) => LoginScreen(), // Define your login route here
      },
    );
  }
}
