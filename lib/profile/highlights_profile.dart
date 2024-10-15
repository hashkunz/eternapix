import 'package:flutter/material.dart';

class StoryWidget extends StatelessWidget {
  final List<String> imageUrls; // เปลี่ยนเป็น List ของ URLs
  final String timeAgo;

  const StoryWidget({
    Key? key,
    required this.imageUrls,
    required this.timeAgo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) =>
              StorySlideSheet(imageUrls: imageUrls, timeAgo: timeAgo),
        );
      },
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrls.first, // ใช้ภาพแรกในการแสดง
                  width: 130,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}

class StorySlideSheet extends StatefulWidget {
  final List<String> imageUrls; // เปลี่ยนเป็น List ของ URLs
  final String timeAgo;

  const StorySlideSheet({
    Key? key,
    required this.imageUrls,
    required this.timeAgo,
  }) : super(key: key);

  @override
  _StorySlideSheetState createState() => _StorySlideSheetState();
}

class _StorySlideSheetState extends State<StorySlideSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  int currentIndex = 0; // ใช้เพื่อเก็บ index ของภาพปัจจุบัน

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 4 วินาทีสำหรับแต่ละภาพ
    )..forward(); // เริ่มนับเวลา

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (currentIndex < widget.imageUrls.length - 1) {
          // เปลี่ยนภาพถัดไปถ้ายังไม่ถึงภาพสุดท้าย
          setState(() {
            currentIndex++;
            _progressController.reset(); // รีเซ็ตการนับใหม่
            _progressController.forward(); // เริ่มนับใหม่
          });
        } else {
          Navigator.pop(context); // ปิดเมื่อดูหมดแล้ว
        }
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.6,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            children: [
              GestureDetector(
                onTapUp: (details) {
                  // แบ่งจอเป็นซ้ายและขวาเพื่อตรวจสอบการกด
                  if (details.localPosition.dx <
                      MediaQuery.of(context).size.width / 2) {
                    // กดฝั่งซ้าย
                    _goToPreviousImage();
                  } else {
                    // กดฝั่งขวา
                    _goToNextImage();
                  }
                },
                child: Center(
                  child: Image.network(
                    widget.imageUrls[currentIndex], // แสดงภาพปัจจุบัน
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              // ตัวนับแสดงภาพที่เท่าไหร่แล้ว
              Positioned(
                top: 15, // ปรับตำแหน่งตามที่ต้องการ
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${currentIndex + 1} จาก ${widget.imageUrls.length}', // แสดงผลภาพที่เท่าไหร่จากทั้งหมด
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              // Progress Bar
              Positioned(
                top: 55,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      );
                    },
                  ),
                ),
              ),
              // แสดงข้อความ timeAgo ที่ด้านล่าง
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: Center(
                  child: Text(
                    widget.timeAgo,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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

  void _goToNextImage() {
    if (currentIndex < widget.imageUrls.length - 1) {
      setState(() {
        currentIndex++;
        _progressController.reset();
        _progressController.forward();
      });
    } else {
      Navigator.pop(context); // ปิดเมื่อดูหมดแล้ว
    }
  }

  void _goToPreviousImage() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _progressController.reset();
        _progressController.forward();
      });
    }
  }
}
