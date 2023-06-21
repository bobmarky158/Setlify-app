import 'package:flutter/material.dart';

Color hexStringToColor(String hexColor) {
  // ignore: parameter_assignments
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    // ignore: parameter_assignments
    hexColor = "FF$hexColor";
  }
  return Color(int.parse(hexColor, radix: 16));
}
