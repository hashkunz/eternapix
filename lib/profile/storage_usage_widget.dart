import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StorageUsageWidget extends StatefulWidget {
  @override
  _StorageUsageWidgetState createState() => _StorageUsageWidgetState();
}

class _StorageUsageWidgetState extends State<StorageUsageWidget> {
  double? usedStorageInMB;
  double _totalSizeInBytes = 0.0;
  double maxStorageInMB = 50.0; // ค่าตั้งต้น

  List<String> categories = [
    'Animals',
    'Nature',
    'Architecture',
    'Food',
    'People',
    'Travel'
  ]; // หมวดหมู่ทั้งหมด

  @override
  void initState() {
    super.initState();
    _fetchMaxStorage();
    _calculateUsedStorage();
  }

  Future<void> _fetchMaxStorage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('storages')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

          setState(() {
            maxStorageInMB = data?['maxStorage']?.toDouble() ??
                50.0; // ถ้าไม่พบให้ใช้ค่าเริ่มต้นที่ 50.0
          });
        } else {
          print('No storage document found for user: ${user.uid}');
        }
      }
    } catch (e) {
      print('Error fetching max storage: $e');
    } finally {
      _calculateUsedStorage(); // คำนวณพื้นที่ใช้หลังจากดึง maxStorage
    }
  }

  Future<void> _calculateUsedStorage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        _totalSizeInBytes = 0.0;

        for (String category in categories) {
          QuerySnapshot snapshot = await FirebaseFirestore.instance
              .collection('categories')
              .doc(user.uid)
              .collection('userCategories')
              .doc(category)
              .collection('images')
              .orderBy('date', descending: true)
              .get();

          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;

            if (data != null && data.containsKey('imagePostUrl')) {
              final imageUrl = data['imagePostUrl'];

              // แปลง imageUrl เป็น Uri
              final uri = Uri.parse(imageUrl); // แปลง String เป็น Uri

              final response = await http.head(uri); // ใช้ Uri แทน String

              if (response.headers['content-length'] != null) {
                final size = int.parse(response.headers['content-length']!);
                _totalSizeInBytes += size.toDouble();
              }
            } else {
              print('Field "imageUrl" does not exist in document: ${doc.id}');
            }
          }
        }

        setState(() {
          usedStorageInMB = _totalSizeInBytes / (1024 * 1024);
        });

        // ส่งค่า usedStorageInMB ไปเก็บใน Firestore
        await _updateUsedStorageInFirestore(user.uid, usedStorageInMB);
        print('Total used storage in MB: $usedStorageInMB');
      } else {
        print('No user is signed in.');
      }
    } catch (e) {
      print('Error calculating storage usage: $e');
    }
  }

  Future<void> _updateUsedStorageInFirestore(
      String uid, double? usedStorage) async {
    try {
      if (usedStorage != null) {
        await FirebaseFirestore.instance
            .collection('storages')
            .doc(uid)
            .update({'storageUsed': usedStorage});
      }
    } catch (e) {
      print('Error updating storageUsed in Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double usagePercentage = (usedStorageInMB ?? 0) / maxStorageInMB;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: usagePercentage.clamp(0.0, 1.0),
              backgroundColor: const Color.fromARGB(255, 232, 232, 232),
              valueColor: AlwaysStoppedAnimation<Color>(
                usagePercentage >= 0.8 ? Colors.red : Colors.blue,
              ),
              minHeight: 10,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${(usedStorageInMB ?? 0).toStringAsFixed(1)} MB / $maxStorageInMB MB (${(usagePercentage * 100).toStringAsFixed(1)}% used)',
          ),
        ],
      ),
    );
  }
}
