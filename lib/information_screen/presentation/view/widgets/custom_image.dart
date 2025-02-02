import 'package:flutter/material.dart';

class AnimatedImageWidget extends StatefulWidget {
  const AnimatedImageWidget({super.key});

  @override
  _AnimatedImageWidgetState createState() => _AnimatedImageWidgetState();
}

class _AnimatedImageWidgetState extends State<AnimatedImageWidget>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0; // Start with an opacity of 0 (invisible)
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Duration of the animation
    );

    // Trigger the animation after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0; // Set opacity to 1 (fully visible)
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(seconds: 2), // Duration of the fade-in effect
      child: Image.asset(
        "assets/test2.png",
        height: height * 0.2,
      ),
    );
  }
}
