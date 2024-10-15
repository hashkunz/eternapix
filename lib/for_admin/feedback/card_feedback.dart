import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackCard extends StatefulWidget {
  final String userName;
  final String feedback;
  final Timestamp date;
  final int star;

  FeedbackCard({
    required this.userName,
    required this.feedback,
    required this.date,
    required this.star,
  });

  @override
  _FeedbackCardState createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<FeedbackCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      if (_isExpanded) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        widget.date.toDate().toLocal().toString().split(' ')[0];

    List<Widget> starWidgets = List.generate(
      5,
      (index) => Icon(
        index < widget.star ? Icons.star : Icons.star_border,
        color: index < widget.star
            ? const Color.fromARGB(255, 49, 149, 231)
            : Colors.grey,
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                widget.userName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formattedDate),
                  Row(
                    children: starWidgets,
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: _toggleExpansion,
              ),
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.feedback),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
