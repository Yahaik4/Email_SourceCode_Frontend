import 'package:flutter/material.dart';
import 'package:testabc/core/models/email_model.dart';
import 'package:intl/intl.dart';

class EmailDetailScreen extends StatelessWidget {
  final Email email;

  const EmailDetailScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.email_outlined,
                color: Color(0xFF5F6368),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Email',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: Color(0xFF5F6368)),
            onPressed: () {
              // TODO: Implement archive functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF5F6368)),
            onPressed: () {
              // TODO: Implement delete functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.mail_outline, color: Color(0xFF5F6368)),
            onPressed: () {
              // TODO: Implement mark as unread functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.schedule_outlined, color: Color(0xFF5F6368)),
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
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject
                Text(
                  email.subject,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // Sender info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1A73E8),
                      radius: 20,
                      child: Text(
                        email.senderName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
                                email.senderName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '<${email.senderEmail}>',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'To me',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, h:mm a').format(email.timestamp),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Email body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email content
                  Text(
                    email.body,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  if (email.attachments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...email.attachments.map((attachment) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EAED),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.insert_drive_file,
                                  color: Color(0xFF5F6368),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attachment,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PDF • 2.4 MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.download_outlined,
                                  color: Color(0xFF5F6368),
                                ),
                                onPressed: () {
                                  // TODO: Implement download functionality
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
          // Action buttons at the bottom
          Container(
            color: Colors.white,
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
                ),
                _buildActionButton(
                  icon: Icons.reply_all_outlined,
                  label: 'Reply all',
                  onTap: () {
                    // TODO: Implement reply all functionality
                  },
                ),
                _buildActionButton(
                  icon: Icons.forward_outlined,
                  label: 'Forward',
                  onTap: () {
                    // TODO: Implement forward functionality
                  },
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
              color: const Color(0xFF5F6368),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 