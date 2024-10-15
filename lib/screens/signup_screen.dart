import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:eternapix/animation/animations.dart';
import 'package:eternapix/screens/login_screen.dart';
// import 'package:eternapix/process/process.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constant.dart';

class SignUPScreen extends StatefulWidget {
  SignUPScreen({Key? key}) : super(key: key);

  @override
  State<SignUPScreen> createState() => _SignUPScreenState();
}

class _SignUPScreenState extends State<SignUPScreen> {
  final feature = ["Login", "Sign Up"];
  final formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // เพิ่ม Firestore instance

  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  int i = 1;

  Future<void> _signUp() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      if (_password != _confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      try {
        // สร้างบัญชีผู้ใช้
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        // ดึง UID ของผู้ใช้ที่สร้างใหม่
        String uid = userCredential.user!.uid;

        // สร้างเอกสารใน Firestore ภายใต้ collection "profiles"
        await _firestore.collection('profiles').doc(uid).set({
          'userID': uid,
          'emailUser': _email,
          'profileName': "Unknown",
          'isAdmin': false,
          'profileDescription': "You Can Edit Profile.",
          'birthdate': "xx / xx / xx",
          'idLine': "00",
          'tel': "xx",
          'imageUrl': "https://freesvg.org/img/abstract-user-flat-4.png",
        });

        await _firestore.collection('storages').doc(uid).set({
          'maxStorage': 50,
          'storageUsed': 0.0,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Successful')),
        );

        // Redirect to login or other page after successful sign up
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
            backgroundColor: Color(0xfffdfdfdf),
            body: i == 1
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.all(25),
                          child: Column(
                            children: [
                              // TabBar Code
                              Row(children: [
                                Container(
                                  height: height / 19,
                                  width: width / 2,
                                  child: TopAnime(
                                    2,
                                    5,
                                    child: ListView.builder(
                                      itemCount: feature.length,
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              i = index;
                                            });
                                          },
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20),
                                                child: Text(
                                                  feature[index],
                                                  style: TextStyle(
                                                    color: i == index
                                                        ? Colors.black
                                                        : Colors.grey,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
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
                                height: 30,
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
                                      RichText(
                                        text: TextSpan(
                                          text: "Hello ",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 40,
                                            fontWeight: FontWeight.w300,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: "Beautiful,",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "Enter your informations below or \nlogin with a social account",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: height / 18,
                              ),

                              // TextFiled
                              Container(
                                width: width / 1.2,
                                height: height / 2.55,
                                child: TopAnime(
                                  1,
                                  16,
                                  curve: Curves.easeInExpo,
                                  child: Form(
                                    key: formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          cursorColor: Colors.black,
                                          style: TextStyle(color: Colors.black),
                                          showCursor: true,
                                          decoration: kTextFiledInputDecoration
                                              .copyWith(
                                            labelText: 'Email',
                                          ),
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          onSaved: (String? email) {
                                            if (email != null) {
                                              _email = email;
                                            }
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(
                                          height: 25,
                                        ),
                                        TextFormField(
                                            cursorColor: Colors.black,
                                            style:
                                                TextStyle(color: Colors.black),
                                            showCursor: true,
                                            obscureText: true,
                                            decoration:
                                                kTextFiledInputDecoration
                                                    .copyWith(
                                                        labelText: "Password"),
                                            onSaved: (String? password) {
                                              if (password != null) {
                                                _password = password;
                                              }
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter your password';
                                              }
                                              return null;
                                            }),
                                        SizedBox(
                                          height: 25,
                                        ),
                                        TextFormField(
                                          cursorColor: Colors.black,
                                          style: TextStyle(color: Colors.black),
                                          showCursor: true,
                                          obscureText: true,
                                          decoration: kTextFiledInputDecoration
                                              .copyWith(
                                                  labelText: "Password again"),
                                          onSaved: (String? passwordAgain) {
                                            if (passwordAgain != null) {
                                              _confirmPassword = passwordAgain;
                                            }
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please confirm your password';
                                            }
                                            return null;
                                          },
                                        ),

                                        SizedBox(
                                          height: 5,
                                        ),

                                        // FaceBook and Google Icon
                                        TopAnime(
                                          1,
                                          11,
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
                                                onPressed: () {},
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom
                        i == 1
                            ? TopAnime(
                                2,
                                29,
                                curve: Curves.fastOutSlowIn,
                                child: Container(
                                  height: height / 6,
                                  child: Stack(
                                    children: [
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
                                          onTap: () {
                                            _signUp();
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Color(0xffEB5757),
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
                            : LoginScreen()
                      ],
                    ),
                  )
                : LoginScreen()),
      ),
    );
  }
}
