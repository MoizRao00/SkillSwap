import 'package:flutter/material.dart';

class SkillChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;

  const SkillChip({
    super.key,
    required this.label,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: onDeleted != null ? const Icon(Icons.close) : null,
      onDeleted: onDeleted,
    );
  }
}
