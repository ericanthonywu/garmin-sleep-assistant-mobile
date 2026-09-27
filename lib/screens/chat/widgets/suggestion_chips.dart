import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class SuggestionChips extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const SuggestionChips({
    super.key,
    required this.onSelected,
  });

  static const _suggestions = [
    'Why was my deep sleep low?',
    'Suggest a wind-down routine',
    'How is my weekly sleep trend?',
    'Why do I feel tired today?',
    'Tips to sleep before midnight',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final item = _suggestions[idx];
          return ActionChip(
            label: Text(
              item,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.surfaceElevated,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => onSelected(item),
          );
        },
      ),
    );
  }
}
