import 'package:flutter/material.dart';

class ButtonDls {
  const ButtonDls({
    required this.text,
    // required this.textColor,
    // required this.backgroundColor,
    required this.onPressed,
    this.heigh = 40.0,
    required this.width,
    this.fontSize = 12.0,
  });

  final String text;
  // final Color textColor;
  // final Color backgroundColor;
  final VoidCallback onPressed;
  final double heigh;
  final double width;
  final double fontSize;

  SizedBox getButtonPrimary(BuildContext context) {
    return SizedBox(
      height: heigh,
      width: width,
      child: TextButton(
        onPressed: () => onPressed(),
        style: ButtonStyle(
          // backgroundColor: WidgetStateProperty.all<Color>(backgroundColor),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: Theme.of(context).colorScheme.outline)),
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
      ),
    );
  }
}
