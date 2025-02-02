import 'package:flutter/material.dart';

class DecoratedTextField extends StatefulWidget {
  const DecoratedTextField({
    super.key,
    required this.controller,
    required this.keyboardType,
    required this.labelText,
    required this.prefixIcon,
    this.isPassword = false,
    this.onTap,
    this.readOnly = false,
  });
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String labelText;
  final Icon prefixIcon;
  final bool isPassword;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  State<DecoratedTextField> createState() => _DecoratedTextFieldState();
}

class _DecoratedTextFieldState extends State<DecoratedTextField> {
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: width * 0.05, vertical: height * 0.02),
      child: TextFormField(
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter some text';
          }
          return null;
        },
        obscureText: widget.isPassword ? _obscureText : false,
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: "Type something...",
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText; // Toggle visibility
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blue, width: 2.0),
            borderRadius: BorderRadius.circular(15.0),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }
}
