// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:eternapix/animation/animations.dart';
import 'package:eternapix/screens/signup_screen.dart';
import 'package:eternapix/home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eternapix/for_admin/list/list_users.dart';

import '../constant.dart';
// import '../firebase_options.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final feature = ["Login", "Sign Up"];

  int i = 0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
            backgroundColor: Color(0xfffdfdfdf),
            body: i == 0
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.all(25),
                          child: Column(
                            children: [
                              Row(
                                  // TabBar Code
                                  children: [
                                    Container(
                                      height: height / 19,
                                      width: width / 2,
                                      child: TopAnime(
                                        2,
                                        5,
                                        child: ListView.builder(
                                          itemCount: feature.length,
                                          scrollDirection: Axis.horizontal,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  i = index;
                                                });
                                              },
                                              child: Column(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20),
                                                    child: Text(
                                                      feature[index],
                                                      style: TextStyle(
                                                        color: i == index
                                                            ? Colors.black
                                                            : Colors.grey,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 8,
                                                  ),
                                                  i == index
                                                      ? Container(
                                                          height: 3,
                                                          width: width / 9,
                                                          color: Colors.black,
                                                        )
                                                      : Container(),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Container()),

                                    // Profile
                                    RightAnime(
                                      1,
                                      15,
                                      curve: Curves.easeInOutQuad,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.red[400],
                                          child: i == 0
                                              ? Image(
                                                  image: NetworkImage(
                                                      "https://i.pinimg.com/564x/5d/a3/d2/5da3d22d08e353184ca357db7800e9f5.jpg"),
                                                )
                                              : Icon(
                                                  Icons.account_circle_outlined,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ]),

                              SizedBox(
                                height: 50,
                              ),

                              // Top Text
                              Container(
                                padding: EdgeInsets.only(left: 15),
                                width: width,
                                child: TopAnime(
                                  1,
                                  20,
                                  curve: Curves.fastOutSlowIn,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Welcome To",
                                          style: TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w300,
                                          )),
                                      Text(
                                        "EternaPix",
                                        style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: height / 14,
                              ),

                              // TextField
                              Column(
                                children: [
                                  Container(
                                    width: width / 1.2,
                                    height: height / 3.10,
                                    child: TopAnime(
                                      1,
                                      15,
                                      curve: Curves.easeInExpo,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: _emailController,
                                            cursorColor: Colors.black,
                                            style:
                                                TextStyle(color: Colors.black),
                                            showCursor: true,
                                            decoration:
                                                kTextFiledInputDecoration
                                                    .copyWith(
                                                        labelText: "Email"),
                                          ),
                                          SizedBox(
                                            height: 25,
                                          ),
                                          TextField(
                                              controller: _passwordController,
                                              cursorColor: Colors.black,
                                              style: TextStyle(
                                                  color: Colors.black),
                                              showCursor: true,
                                              obscureText: true,
                                              decoration:
                                                  kTextFiledInputDecoration
                                                      .copyWith(
                                                          labelText:
                                                              "Password")),

                                          SizedBox(
                                            height: 5,
                                          ),

                                          // Facebook and Google Icons
                                          TopAnime(
                                            1,
                                            10,
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: FaIcon(
                                                    FontAwesomeIcons.facebookF,
                                                    size: 30,
                                                  ),
                                                  onPressed: () {},
                                                ),
                                                SizedBox(
                                                  width: 15,
                                                ),
                                                IconButton(
                                                  icon: FaIcon(
                                                      FontAwesomeIcons
                                                          .googlePlusG,
                                                      size: 35),
                                                  onPressed:
                                                      _loginWithGoogle, // ฟังก์ชันล็อกอินด้วย Google
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),

                        // Bottom
                        i == 0
                            ? TopAnime(
                                2,
                                42,
                                curve: Curves.fastOutSlowIn,
                                child: Container(
                                  height: height / 6,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 30,
                                        top: 15,
                                        child: Text(
                                          "Forgot Password?",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 43),
                                        child: Container(
                                            height: height / 9,
                                            color:
                                                Colors.grey.withOpacity(0.4)),
                                      ),
                                      Positioned(
                                        left: 280,
                                        top: 10,
                                        child: GestureDetector(
                                          onTap: _login,
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Color(0xffF2C94C),
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            width: width / 4,
                                            height: height / 12,
                                            child: Icon(
                                              Icons.arrow_forward,
                                              size: 35,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SignUPScreen()
                      ],
                    ),
                  )
                : SignUPScreen()),
      ),
    );
  }

  Future<void> _login() async {
    try {
      print('Logging in with email: ${_emailController.text}'); // log email

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      print(
          'Login successful, User: ${userCredential.user?.uid}'); // log user UID

      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;

        // Check role in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final role = userDoc.data()?['isAdmin'];

          if (role == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ListUsersPage()), // Change this to your admin page
            );
          } else if (role == false) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
        } else {
          // Handle case when user document does not exist in Firestore
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User role not found in Firestore.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code: ${e.code}'); // log error code
      debugPrint(
          'FirebaseAuthException message: ${e.message}'); // log error message

      if (e.code == 'user-not-found') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignUPScreen()),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incorrect password. Please try again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e, stacktrace) {
      // Log other errors
      debugPrint('Error occurred: $e');
      debugPrint('Stacktrace: $stacktrace');
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the login
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      print('Login with Google successful, User: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;

        // Check role in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final role = userDoc.data()?['roles'];

          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ListUsersPage()), // Change this to your admin page
            );
          } else if (role == 'user') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
        } else {
          // Handle case when user document does not exist in Firestore
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User role not found in Firestore.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code: ${e.code}');
      debugPrint('FirebaseAuthException message: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e, stacktrace) {
      debugPrint('Error occurred: $e');
      debugPrint('Stacktrace: $stacktrace');
    }
  }
}
