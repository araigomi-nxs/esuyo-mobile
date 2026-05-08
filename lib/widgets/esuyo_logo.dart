import 'package:flutter/material.dart';

class EsuyoLogo extends StatelessWidget {
  static const double aspectRatio = 245 / 174;

  final double? width;
  final double? height;
  final double padding;

  const EsuyoLogo({super.key, this.width, this.height, this.padding = 0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.asset(
          'assets/esuyo_logo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
