import 'package:flutter/material.dart';

/// A horizontal chip group for selecting one option from a list.
class ChoiceChipSelector extends StatelessWidget {
  final List<Map<String, String>> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const ChoiceChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const neonLime = Color(0xFFB8FF00);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt['value'];
        return ChoiceChip(
          label: Text(opt['label']!),
          selected: isSelected,
          selectedColor: neonLime.withValues(alpha: 0.3),
          onSelected: (_) => onChanged(opt['value']!),
          labelStyle: TextStyle(
            color: isSelected ? neonLime : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(color: isSelected ? neonLime : Colors.grey),
        );
      }).toList(),
    );
  }
}
