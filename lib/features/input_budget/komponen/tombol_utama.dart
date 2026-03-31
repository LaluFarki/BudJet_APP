import 'package:flutter/material.dart';

class TombolUtama extends StatelessWidget {
  final String teks;
  final VoidCallback onTap;

  const TombolUtama({super.key, 
    required this.teks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFD4E858),
        minimumSize: Size(double.infinity, 75),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(1000),
        ),
      ),
      onPressed: onTap,
      child: Text(
        teks,
        style: TextStyle(
          color: Colors.black,
          fontSize: 35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}