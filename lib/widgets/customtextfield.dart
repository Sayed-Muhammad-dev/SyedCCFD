import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

Widget customTextField(
  String hintText, {
  String? labelText,
  int? maxLines,
  bool isPassword = false,
  String? Function(String?)? validator,
  TextEditingController? controller,
  Icon? prefixIcon,
  TextInputType keyboardType = TextInputType.text,
}) {
  return TextFormField(
    validator: validator,
    controller: controller,
    obscureText: isPassword ? true : false,
    maxLines: maxLines ?? 1,
    autocorrect: true,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hintText,
      labelText: labelText,
      fillColor: Colors.grey[200],
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      prefixIcon: Icon(
        prefixIcon != null ? prefixIcon.icon : Icons.abc,
        color: Colors.grey,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
