import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryImagePage extends StatefulWidget {
  @override
  _CategoryImagePageState createState() => _CategoryImagePageState();
}

class _CategoryImagePageState extends State<CategoryImagePage> {
  final List<String> _categories = [
    'Nature',
    'Animals',
    'Architecture',
    'People',
    'Food',
    'Travel'
  ];

  Map<String, List<String>> _categoryImages = {};
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      _fetchCategoryImages();
    }
  }

  Future<void> _fetchCategoryImages() async {
    if (_userId == null) return;

    try {
      for (String category in _categories) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('categories')
            .doc(_userId!)
            .collection('userCategories')
            .doc(category)
            .collection('images')
            .get();

        List<String> imageUrls =
            snapshot.docs.map((doc) => doc['imagePostUrl'] as String).toList();

        setState(() {
          if (imageUrls.isNotEmpty) {
            _categoryImages[category] = imageUrls;
          }
        });
      }
    } catch (e) {
      print('Error fetching category images: $e');
    }
  }

  void _showCategoryImages(String category, List<String> images) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: ScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              images[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.85,
            ),
            itemCount: _categoryImages.keys.length,
            itemBuilder: (context, index) {
              String category = _categoryImages.keys.elementAt(index);
              List<String>? images = _categoryImages[category];

              // Placeholder URL
              const String placeholderUrl = 'https://via.placeholder.com/150';

              // Fill with placeholder if there are fewer than 4 images
              List<String> displayImages = images != null ? [...images] : [];
              while (displayImages.length < 4) {
                displayImages.add(placeholderUrl);
              }

              return GestureDetector(
                onTap: () {
                  if (images != null && images.isNotEmpty) {
                    _showCategoryImages(category, images);
                  }
                },
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          child: GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 4.0,
                              mainAxisSpacing: 4.0,
                              childAspectRatio: 1,
                            ),
                            itemCount: displayImages.length,
                            itemBuilder: (context, idx) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  displayImages[idx],
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
