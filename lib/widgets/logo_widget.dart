import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;

  const LogoWidget({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/logotype_eira.png',
      height: size,
      fit: BoxFit.contain,
    );
  }
}
