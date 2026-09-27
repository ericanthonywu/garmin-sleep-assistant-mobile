import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class MomMorningNote extends StatelessWidget {
  final String? noteContent;
  final String? verdict;
  final VoidCallback onTalkToMom;

  const MomMorningNote({
    super.key,
    this.noteContent,
    this.verdict,
    required this.onTalkToMom,
  });

  @override
  Widget build(BuildContext context) {
    if (noteContent == null || noteContent!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final emojis = {
      'good': '☀️',
      'okay': '🌤️',
      'bad': '😤',
      'terrible': '🚨',
    };
    final emoji = emojis[verdict] ?? '🧡';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.momCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.momBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.momWarm.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Morning Briefing',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.momWarm,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (verdict != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.verdictColor(verdict).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.verdictColor(verdict).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    verdict!.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.verdictColor(verdict),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            noteContent!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onTalkToMom,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ask Assistant',
                      style: TextStyle(
                        color: AppColors.momWarm,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.momWarm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
