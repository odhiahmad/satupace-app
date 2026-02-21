import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final String? label;
  final String? imageUrl;
  final double size;

  const Avatar({super.key, this.label, this.imageUrl, this.size = 40});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CircleAvatar(radius: size / 2, backgroundImage: NetworkImage(imageUrl!));
    }
    return CircleAvatar(radius: size / 2, child: Text(label != null && label!.isNotEmpty ? label![0].toUpperCase() : '?'));
  }
}
