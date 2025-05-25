import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:testabc/main.dart'; // Import để sử dụng ThemeProvider

class EmailDetailScreen extends StatelessWidget {
  final Map<String, String> email;

  const EmailDetailScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy theme từ ThemeProvider
    final themeProvider = ThemeProvider.of(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context); // Lấy ThemeData hiện tại

    // Parse timestamp
    String formattedTime = '';
    try {
      final timestamp = DateTime.tryParse(email['createdAt'] ?? '');
      if (timestamp != null) {
        formattedTime = DateFormat('MMM d, h:mm a').format(timestamp.toLocal());
      }
    } catch (e) {
      formattedTime = email['time'] ?? '';
    }

    // Parse attachments
    List<Map<String, dynamic>> attachments = [];
    if (email['attachments'] != null && email['attachments']!.isNotEmpty) {
      try {
        attachments = (jsonDecode(email['attachments']!) as List<dynamic>).cast<Map<String, dynamic>>();
      } catch (e) {
        print('Error parsing attachments: $e');
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Sử dụng màu nền từ theme
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? (isDarkMode ? const Color(0xFF1F1F2A) : Colors.white),
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
            Text(
              'Email',
              style: TextStyle(
                color: theme.textTheme.bodyMedium!.color,
                fontSize: 18,
                fontWeight: FontWeight.w500,
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
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.iconTheme.color),
            onPressed: () {
              // TODO: Implement delete functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.mail_outline, color: theme.iconTheme.color),
            onPressed: () {
              // TODO: Implement mark as unread functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.schedule_outlined, color: theme.iconTheme.color),
            onPressed: () {
              // TODO: Implement snooze functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Email header
          Container(
            color: isDarkMode ? const Color(0xFF2C2C38) : Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject
                Text(
                  email['subject'] ?? '',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium!.color,
                  ),
                ),
                const SizedBox(height: 16),
                // Sender info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primaryColor,
                      radius: 20,
                      child: Text(
                        (email['sender'] ?? 'U')[0].toUpperCase(),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                email['sender'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodyMedium!.color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '<${email['senderEmail'] ?? 'unknown@example.com'}>',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.white60 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'To me',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDarkMode ? const Color(0xFF3C3C48) : Colors.grey[300]),
          // Email body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email content
                  Text(
                    email['body'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium!.color,
                      height: 1.5,
                    ),
                  ),
                  if (attachments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyMedium!.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...attachments.map((attachment) => Container(
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
                                onPressed: () {
                                  // TODO: Implement download functionality using attachment['fileUrl']
                                  print('Download: ${attachment['fileUrl']}');
                                },
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
          // Action buttons
          Container(
            color: isDarkMode ? const Color(0xFF1F1F2A) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.reply_outlined,
                  label: 'Reply',
                  onTap: () {
                    // TODO: Implement reply functionality
                  },
                  isDarkMode: isDarkMode,
                  theme: theme,
                ),
                _buildActionButton(
                  icon: Icons.reply_all_outlined,
                  label: 'Reply all',
                  onTap: () {
                    // TODO: Implement reply all functionality
                  },
                  isDarkMode: isDarkMode,
                  theme: theme,
                ),
                _buildActionButton(
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
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
    required ThemeData theme,
  }) {
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