import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:testabc/main.dart';

class EmailHeader extends StatelessWidget {
  final Map<String, dynamic> email;

  const EmailHeader({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    String formattedTime = '';
    try {
      final timestamp = DateTime.tryParse(email['date'] ?? '');
      if (timestamp != null) {
        formattedTime = DateFormat('MMM d, h:mm a').format(timestamp.toLocal());
      }
    } catch (e) {
      formattedTime = email['date']?.toString() ?? '';
    }

    final isSentByUser = email['isSentByUser'] == 'true';
    final groupedRecipientEmails = email['groupedRecipientEmails'] as Map<String, List<String>>? ?? {
      'to': [],
      'cc': [],
      'bcc': [],
    };

    return Container(
      color: isDarkMode ? const Color(0xFF2C2C38) : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            email['subject']?.toString() ?? '',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium!.color,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.primaryColor,
                radius: 20,
                child: email['avatar'] != null && email['avatar']!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          email['avatar']!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            (email['sender'] ?? 'U')[0].toUpperCase(),
                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                          ),
                        ),
                      )
                    : Text(
                        (email['sender'] ?? 'U')[0].toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email['senderEmail']?.toString() ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyMedium!.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        title: Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
                        iconColor: isDarkMode ? Colors.white70 : Colors.grey[700],
                        collapsedIconColor: isDarkMode ? Colors.white70 : Colors.grey[700],
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF3C3C48) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode ? Colors.white12 : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (groupedRecipientEmails['to']!.isNotEmpty) ...[
                                  Text(
                                    'To:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                                    ),
                                  ),
                                  ...groupedRecipientEmails['to']!.map((email) => Padding(
                                        padding: const EdgeInsets.only(left: 8, top: 4),
                                        child: Text(
                                          email,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white60 : Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                  const SizedBox(height: 8),
                                ],
                                if (groupedRecipientEmails['cc']!.isNotEmpty) ...[
                                  Text(
                                    'Cc:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                                    ),
                                  ),
                                  ...groupedRecipientEmails['cc']!.map((email) => Padding(
                                        padding: const EdgeInsets.only(left: 8, top: 4),
                                        child: Text(
                                          email,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white60 : Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                  const SizedBox(height: 8),
                                ],
                                if (groupedRecipientEmails['bcc']!.isNotEmpty) ...[
                                  Text(
                                    'Bcc:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                                    ),
                                  ),
                                  ...groupedRecipientEmails['bcc']!.map((email) => Padding(
                                        padding: const EdgeInsets.only(left: 8, top: 4),
                                        child: Text(
                                          email,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white60 : Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                ],
                                if (groupedRecipientEmails['to']!.isEmpty &&
                                    groupedRecipientEmails['cc']!.isEmpty &&
                                    groupedRecipientEmails['bcc']!.isEmpty)
                                  Text(
                                    isSentByUser ? 'Sent' : 'Unknown',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.white60 : Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
