import 'package:flutter/material.dart';

class AllPatientsIcon extends StatelessWidget {
  const AllPatientsIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background Circle
          Container(
            width: 40, // Adjust size to fit in AppBar
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFDDA853),
              shape: BoxShape.circle,
            ),
          ),
          // First Person Icon
          Positioned(
            top: 6,
            left: 6,
            child: Icon(
              Icons.person,
              size: 15, // Adjust size
              color: Colors.teal[800],
            ),
          ),
          // Second Person Icon
          Positioned(
            top: 6,
            right: 6,
            child: Icon(
              Icons.person,
              size: 15, // Adjust size
              color: Colors.teal[800],
            ),
          ),
          // Third Person Icon
          Positioned(
            bottom: 6,
            child: Icon(
              Icons.person,
              size: 20, // Adjust size
              color: Colors.teal[900],
            ),
          ),
        ],
      ),
    );
  }
}
