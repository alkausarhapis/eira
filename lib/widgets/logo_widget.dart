import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;

  const LogoWidget({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9747FF), Color(0xFFB47FFF)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Eira',
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
