import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/session_manager.dart';
import 'package:testabc/presentation/pages/home/email_detail_screen.dart';

class EmailItem extends StatelessWidget {
  final Map<String, String> email;
  final VoidCallback? onStarToggled; // Add callback for star toggle

  const EmailItem({super.key, required this.email, this.onStarToggled});

  Future<void> _toggleStar(BuildContext context) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/email/starredEmail'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id': email['id']}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email star status updated')),
        );
        if (onStarToggled != null) {
          onStarToggled!(); // Notify parent to refresh email list if needed
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonDecode(response.body)['msg'] ?? 'Failed to update star status',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = email['avatar'] ?? 'assets/default-avatar.png';
    final imageProvider = avatarUrl.startsWith('http')
        ? NetworkImage(avatarUrl)
        : AssetImage(avatarUrl) as ImageProvider;

    final subject = email['subject'] ?? '';
    final truncatedSubject = subject.length > 50 ? '${subject.substring(0, 50)}...' : subject;

    final body = email['body'] ?? '';
    final cleanedBody = body.replaceAll('\t', ' ').replaceAll('\n', ' ').trim();
    final truncatedBody = cleanedBody.length > 50 ? '${cleanedBody.substring(0, 50)}...' : cleanedBody;

    // Determine if email is starred (assuming API returns a 'starred' field)
    final isStarred = email['starred'] == 'true'; // Adjust based on your API response

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailDetailScreen(emailId: email['id']!),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: imageProvider,
              backgroundColor: Theme.of(context).primaryColor,
              radius: 20,
              onBackgroundImageError: (error, stackTrace) {
                print('Error loading avatar: $error');
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          email['sender'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        email['time'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    truncatedSubject,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          truncatedBody,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                fontSize: 13,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _toggleStar(context),
                        child: Icon(
                          isStarred ? Icons.star : Icons.star_border,
                          color: isStarred
                              ? Colors.yellow[700]
                              : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}