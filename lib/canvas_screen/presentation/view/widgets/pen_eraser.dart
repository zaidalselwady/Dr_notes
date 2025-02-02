import 'package:flutter/material.dart';

class PenAndEraser extends StatefulWidget {
  const PenAndEraser({
    super.key,
    required this.isErasing,
    required this.onToggle,
  });
  final bool isErasing;
  final VoidCallback onToggle;

  @override
  State<PenAndEraser> createState() => _PenAndEraserState();
}

class _PenAndEraserState extends State<PenAndEraser> {
  // late bool _isErasing;
  // @override
  // void initState() {
  //   _isErasing = widget.isErasing;
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300), // Smooth animation duration
      transitionBuilder: (Widget child, Animation<double> animation) {
        return RotationTransition(
          turns: animation,
          child: child,
        );
      },
      child: IconButton(
          key: ValueKey<bool>(
              widget.isErasing), // Ensures unique identity for each state
          icon: Icon(widget.isErasing ? Icons.brush : Icons.clear),
          onPressed: widget.onToggle),
    );
  }
}
