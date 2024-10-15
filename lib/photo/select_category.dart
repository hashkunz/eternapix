import 'package:flutter/material.dart';

class SelectCategory extends StatefulWidget {
  final IconData icon;
  final VoidCallback onSelect;
  final bool isSelected;

  SelectCategory({
    required this.icon,
    required this.onSelect,
    required this.isSelected,
  });

  @override
  _SelectCategoryState createState() => _SelectCategoryState();
}

class _SelectCategoryState extends State<SelectCategory> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSelect,
      child: Container(
        width: 100,
        height: 40,
        padding: EdgeInsets.all(5.0),
        margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Colors.blue // สีเมื่อถูกเลือก
              : const Color.fromARGB(255, 255, 255, 255), // สีเริ่มต้น
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            widget.icon,
            size: 20,
            color: widget.isSelected
                ? Colors.white // สีของไอคอนเมื่อถูกเลือก
                : const Color.fromARGB(255, 0, 0, 0), // สีของไอคอนเริ่มต้น
          ),
        ),
      ),
    );
  }
}
