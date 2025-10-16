import 'package:flutter/material.dart';

class OnlineIcon extends StatelessWidget {
  const OnlineIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main icon
          const Icon(
            Icons.person,
            size: 40,
            color: Color(0xFFDDA853),
          ),
          // Green notch
          Positioned(
            bottom: -5, // Adjust position as needed
            right: -5, // Adjust position as needed
            child: Container(
              width: 15, // Size of the green dot
              height: 15, // Size of the green dot
              decoration: BoxDecoration(
                color: Color(0xFF00695C),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFFFBF5DD), // Border color to separate dot from icon
                  width: 2,
                ),
              ),
            ),
          ),
          // Positioned(
          //   top: -5, // Adjust position as needed
          //   left: -7, // Adjust position as needed
          //   child: Text(numberOfPatients.toString()),
          // ),
        ],
      ),
    );
  }
}
