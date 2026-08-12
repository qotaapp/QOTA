import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/comment_models.dart';

class ReplyTile extends StatelessWidget {
  final QotaCommentReply reply;
  final VoidCallback onToggleLike;

  const ReplyTile({super.key, required this.reply, required this.onToggleLike});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reply.authorName,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text(reply.text, style: const TextStyle(fontSize: 13.5)),
          const SizedBox(height: 4),
          InkWell(
            onTap: onToggleLike,
            child: Row(
              children: [
                Icon(
                  Icons.thumb_up_alt_rounded,
                  size: 14,
                  color: reply.likedByMe
                      ? AppColors.primaryOrange
                      : AppColors.iconInactive,
                ),
                const SizedBox(width: 4),
                Text('${reply.likesCount}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
