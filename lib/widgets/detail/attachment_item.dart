import 'package:flutter/material.dart';

class AttachmentItem extends StatelessWidget {
  final Map<String, dynamic> attachment;
  final bool isDarkMode;
  final ThemeData theme;
  final VoidCallback onDownload;

  const AttachmentItem({
    Key? key,
    required this.attachment,
    required this.isDarkMode,
    required this.theme,
    required this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F1F2A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF3C3C48) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF3C3C48) : const Color(0xFFE8EAED),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.insert_drive_file,
              color: isDarkMode ? Colors.white70 : const Color(0xFF5F6368),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment['fileName']?.toString() ?? 'Unknown File',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium!.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${attachment['mimeType'] ?? 'Unknown'} • ${(int.parse(attachment['size']?.toString() ?? '0') / 1024 / 1024).toStringAsFixed(1)} MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.download_outlined,
              color: theme.iconTheme.color,
            ),
            onPressed: onDownload,
          ),
        ],
      ),
    );
  }
}