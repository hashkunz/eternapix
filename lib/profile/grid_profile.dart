import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GridImagePage extends StatelessWidget {
  final List<Map<String, dynamic>> imageUrls; // เปลี่ยนประเภทเป็น dynamic
  final Future<void> Function(String photoId) onDeleteImage;

  GridImagePage({
    required this.imageUrls,
    required this.onDeleteImage,
  });

  @override
  Widget build(BuildContext context) {
    // จัดเรียง imageUrls จากล่าสุดไปเก่าสุด
    List<Map<String, dynamic>> sortedImageUrls = List.from(imageUrls);
    sortedImageUrls.sort((a, b) {
      // ตรวจสอบว่า timestamp ไม่เป็น null
      var timestampA = a['timestamp'];
      var timestampB = b['timestamp'];

      // หาก timestamp เป็น null ให้คืนค่า 0 เพื่อไม่ให้เกิดข้อผิดพลาด
      if (timestampA == null) return 1; // ให้รายการที่มี null ไปอยู่ด้านล่าง
      if (timestampB == null) return -1; // ให้รายการที่มี null ไปอยู่ด้านล่าง

      // เปรียบเทียบ timestamp โดยตรง
      return timestampB
          .toString()
          .compareTo(timestampA.toString()); // เรียงจากล่าสุดไปเก่าสุด
    });

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // จำนวนคอลัมน์
        childAspectRatio: 1, // อัตราส่วนของ Child
        crossAxisSpacing: 2, // ช่องว่างระหว่างคอลัมน์
        mainAxisSpacing: 2, // ช่องว่างระหว่างแถว
      ),
      itemCount: sortedImageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                // ใช้ timestamp ตรงๆ
                var timestamp = sortedImageUrls[index]['timestamp'];
                String formattedDate =
                    timestamp.toString(); // หรือแสดง timestamp ตามต้องการ

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Container(
                        color: const Color.fromARGB(255, 242, 242, 242),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Image.network(
                            sortedImageUrls[index]['url']!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    // เพิ่ม Text Widget เพื่อแสดงวันที่
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Uploaded on: $formattedDate',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      height: 50,
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.download_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Handle download action
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.delete,
                                    color: Colors.white, size: 24),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  print(
                                      'Deleting image with ID: ${sortedImageUrls[index]['id']}');
                                  await onDeleteImage(
                                      sortedImageUrls[index]['id']!);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: CachedNetworkImage(
                imageUrl: sortedImageUrls[index]['url']!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    Center(child: Icon(Icons.error, color: Colors.red)),
              ),
            ),
          ),
        );
      },
    );
  }
}
