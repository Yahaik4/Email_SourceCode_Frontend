import 'package:flutter/material.dart';
import 'package:testabc/main.dart';

class EmailActionButtons extends StatelessWidget {
  const EmailActionButtons({Key? key}) : super(key: key);

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
          _ActionButton(
            icon: Icons.reply_outlined,
            label: 'Reply',
            onTap: () {
              // TODO: Implement reply functionality
            },
            isDarkMode: isDarkMode,
            theme: theme,
          ),
          _ActionButton(
            icon: Icons.reply_all_outlined,
            label: 'Reply all',
            onTap: () {
              // TODO: Implement reply all functionality
            },
            isDarkMode: isDarkMode,
            theme: theme,
          ),
          _ActionButton(
            icon: Icons.forward_outlined,
            label: 'Forward',
            onTap: () {
              // TODO: Implement forward functionality
            },
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