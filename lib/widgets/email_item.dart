import 'package:flutter/material.dart';

class EmailItem extends StatelessWidget {
  final Map<String, String> email;

  const EmailItem({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    // Determine the image provider based on the avatar field
    final avatarUrl = email['avatar'] ?? 'assets/default-avatar.png';
    final imageProvider = avatarUrl.startsWith('http')
        ? NetworkImage(avatarUrl)
        : AssetImage(avatarUrl) as ImageProvider;

    // Limit body text to 100 characters
    final body = email['body'] ?? '';
    final truncatedBody = body.length > 100 ? '${body.substring(0, 100)}...' : body;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: imageProvider,
            backgroundColor: Theme.of(context).primaryColor, // Fallback if image fails to load
            onBackgroundImageError: (error, stackTrace) {
              print('Error loading avatar: $error');
            },
          ),
          const SizedBox(width: 10),
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
                            ),
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
                Text(
                  email['subject'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        truncatedBody,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                      ),
                    ),
                    Icon(
                      Icons.star_border,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}