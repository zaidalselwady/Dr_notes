import 'package:flutter/material.dart';

class CustomActionButton extends StatefulWidget {
  const CustomActionButton({
    super.key,
  });

  @override
  State<CustomActionButton> createState() => _CustomActionButtonState();
}

class _CustomActionButtonState extends State<CustomActionButton> {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.navigate_next_outlined),
      onPressed: () {},
    );
  }
}
