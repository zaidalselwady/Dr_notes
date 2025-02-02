import 'package:flutter/material.dart';


class ColorfulBackground extends StatefulWidget {
  const ColorfulBackground({super.key, required this.child});
  final Widget child;

  @override
  State<ColorfulBackground> createState() => _ColorfulBackgroundState();
}

class _ColorfulBackgroundState extends State<ColorfulBackground> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFB7E0FF),
            Color(0xffFFF5CD),
            Color(0xffFFCFB3),
            Color(0xffE78F81)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: widget.child,
    );
  }
}
