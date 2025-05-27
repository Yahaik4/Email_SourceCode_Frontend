import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:testabc/main.dart';
import 'attachment_item.dart';

class EmailContent extends StatelessWidget {
  final Map<String, dynamic> email;
  final Function(BuildContext, Map<String, dynamic>) onDownload;

  const EmailContent({Key? key, required this.email, required this.onDownload}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    List<Map<String, dynamic>> attachments = [];
    if (email['attachments'] != null && email['attachments'].toString().isNotEmpty) {
      try {
        attachments = (jsonDecode(email['attachments'].toString()) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      } catch (e) {
        print('Error parsing attachments: $e');
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email['body']?.toString() ?? '',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium!.color,
                height: 1.5,
              ),
            ),
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Attachments:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(height: 12),
              ...attachments.map((attachment) => AttachmentItem(
                    attachment: attachment,
                    isDarkMode: isDarkMode,
                    theme: theme,
                    onDownload: () => onDownload(context, attachment),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}