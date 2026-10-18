import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class CommentsSkeleton extends StatelessWidget {
  const CommentsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.darkGrey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.darkGrey,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
