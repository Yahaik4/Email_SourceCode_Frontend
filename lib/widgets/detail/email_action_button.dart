import 'package:flutter/material.dart';
import 'package:testabc/main.dart';

class EmailActionButtons extends StatelessWidget {
  final VoidCallback? onReply;
  final VoidCallback? onReplyAll;
  final VoidCallback? onForward;
  final bool isSentByUser;
  final bool hasReplies;

  const EmailActionButtons({
    Key? key,
    this.onReply,
    this.onReplyAll,
    this.onForward,
    required this.isSentByUser,
    required this.hasReplies,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return Container(
      color: isDarkMode ? const Color(0xFF1F1F2A) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Show Reply and Reply All for received emails or sent emails with replies
          if (!isSentByUser || hasReplies) ...[
            _ActionButton(
              icon: Icons.reply_outlined,
              label: 'Reply',
              onTap: onReply ?? () {},
              isDarkMode: isDarkMode,
              theme: theme,
            ),
            _ActionButton(
              icon: Icons.reply_all_outlined,
              label: 'Reply all',
              onTap: onReplyAll ?? () {},
              isDarkMode: isDarkMode,
              theme: theme,
            ),
          ],
          _ActionButton(
            icon: Icons.forward_outlined,
            label: 'Forward',
            onTap: onForward ?? () {},
            isDarkMode: isDarkMode,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDarkMode;
  final ThemeData theme;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.iconTheme.color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium!.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}