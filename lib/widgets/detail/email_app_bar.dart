import 'package:flutter/material.dart';
import 'package:testabc/main.dart';

class EmailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, dynamic> email;

  const EmailAppBar({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ??
          (isDarkMode ? const Color(0xFF1F1F2A) : Colors.white),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF3C3C48) : const Color(0xFFE8EAED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.email_outlined,
              color: isDarkMode ? Colors.white70 : const Color(0xFF5F6368),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              email['subject']?.toString() ?? 'No Subject',
              style: TextStyle(
                color: theme.textTheme.bodyMedium!.color,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.archive_outlined, color: theme.iconTheme.color),
          onPressed: () {
            // TODO: Implement archive functionality
          },
          tooltip: 'Archive',
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: theme.iconTheme.color),
          onPressed: () {
            // TODO: Implement delete functionality
          },
          tooltip: 'Delete',
        ),
        IconButton(
          icon: Icon(Icons.mail_outline, color: theme.iconTheme.color),
          onPressed: () {
            // TODO: Implement mark as unread functionality
          },
          tooltip: 'Mark as Unread',
        ),
        IconButton(
          icon: Icon(Icons.schedule_outlined, color: theme.iconTheme.color),
          onPressed: () {
            // TODO: Implement snooze functionality
          },
          tooltip: 'Snooze',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
