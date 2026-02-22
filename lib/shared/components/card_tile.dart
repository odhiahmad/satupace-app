import 'package:flutter/material.dart';
import 'avatar.dart';

class CardTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? avatarLabel;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CardTile({super.key, required this.title, this.subtitle, this.avatarLabel, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Avatar(label: avatarLabel),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing,
      ),
    );
  }
}
