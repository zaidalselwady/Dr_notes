import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyCustomTextField extends StatelessWidget {
  const MyCustomTextField(
      {super.key,
      required this.controller,
      required this.icon,
      required this.lableText,
      required this.warning,
      required this.type,
      required this.invisible,
      required this.suffixIcon,
      required this.onTapOnSuffexIcon});
  final TextEditingController controller;
  final String warning;
  final String lableText;
  final IconData icon;
  final TextInputType type;
  final bool invisible;
  final Icon suffixIcon;
  final Function onTapOnSuffexIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: TextFormField(
        obscureText: invisible,
        controller: controller,
        keyboardType: type,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return warning;
          }
          return null;
        },
        inputFormatters: const <TextInputFormatter>[],
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xffFFFFFF),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          labelStyle: const TextStyle(color: Colors.black, fontSize: 20),
          labelText: lableText,
          //prefixIcon: Icon(icon),
          suffixIcon: IconButton(
            icon: suffixIcon,
            onPressed: () {
              onTapOnSuffexIcon();
            },
          ),

          border: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xff000000))),
          prefixIconColor: Colors.black,
        ),
      ),
    );
  }
}
