import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/session_manager.dart';
import 'package:testabc/presentation/pages/home/email_detail_screen.dart';
import 'package:testabc/presentation/pages/home/compose_mail_page.dart';

class EmailItem extends StatefulWidget {
  final Map<String, String> email;
  final VoidCallback? onEmailUpdated;

  const EmailItem({super.key, required this.email, this.onEmailUpdated});

  @override
  _EmailItemState createState() => _EmailItemState();
}

class _EmailItemState extends State<EmailItem> {
  bool _isLoadingStar = false; 
  bool _isLoadingRead = false;
  bool _isLoadingTrash = false;
  bool _isLoadingDelete = false; 

  Future<bool> _toggleTrash(BuildContext context) async {
    setState(() {
      _isLoadingTrash = true;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found')),
        );
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/email/moveToTrash'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id': widget.email['id']}),
      );

      if (response.statusCode == 200) {
        final isInTrash = widget.email['folder'] == 'trash';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isInTrash ? 'Email restored' : 'Email moved to trash'),
          ),
        );
        widget.onEmailUpdated?.call();
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonDecode(response.body)['msg'] ?? 'Failed to toggle trash status',
            ),
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTrash = false;
        });
      }
    }
  }

  Future<bool> _deleteEmail(BuildContext context) async {
    setState(() {
      _isLoadingDelete = true;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found')),
        );
        return false;
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/email/${widget.email['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email deleted')),
        );
        widget.onEmailUpdated?.call();
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonDecode(response.body)['msg'] ?? 'Failed to delete email',
            ),
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDelete = false;
        });
      }
    }
  }

  Future<void> _toggleStar(BuildContext context) async {
    setState(() {
      _isLoadingStar = true;
    });

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
        body: jsonEncode({'id': widget.email['id']}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email star status updated')),
        );
        widget.onEmailUpdated?.call();
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStar = false;
        });
      }
    }
  }

  Future<void> _markAsRead(BuildContext context) async {
    if (widget.email['isRead'] == 'true') {
      return;
    }

    setState(() {
      _isLoadingRead = true;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/email/readEmail'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id': widget.email['id']}),
      );

      if (response.statusCode == 200) {
        widget.onEmailUpdated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonDecode(response.body)['msg'] ?? 'Failed to mark email as read',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRead = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.email['avatar'] ?? 'assets/default-avatar.png';
    final imageProvider = avatarUrl.startsWith('http')
        ? NetworkImage(avatarUrl)
        : AssetImage(avatarUrl) as ImageProvider;

    final subject = widget.email['subject'] ?? 'No subject';
    final truncatedSubject = subject.length > 50 ? '${subject.substring(0, 50)}...' : subject;
    final folder = widget.email['folder'];
    final body = widget.email['body'] ?? 'No body';
    final cleanedBody = body.replaceAll('\t', ' ').replaceAll('\n', ' ').trim();
    final truncatedBody = cleanedBody.length > 50 ? '${cleanedBody.substring(0, 50)}...' : cleanedBody;

    final isStarred = widget.email['starred'] == 'true';
    final isRead = widget.email['isRead'] == 'true';
    final isDraft = widget.email['isDraft'] == 'true';

    return InkWell(
      onTap: () async {
        if (isDraft) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComposeMailPage(emailId: widget.email['id']),
            ),
          );
        } else {
          await _markAsRead(context);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailDetailScreen(emailId: widget.email['id']!),
              ),
            );
          }
        }
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
                        child: Row(
                          children: [
                            Text(
                              widget.email['sender'] ?? 'Unknown',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!isRead)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF9146FF),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        widget.email['time'] ?? '',
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
                      _isLoadingStar || _isLoadingTrash || _isLoadingDelete
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                size: 20,
                              ),
                              color: Theme.of(context).popupMenuTheme.color,
                              onSelected: (value) async {
                                if (value == 'star') {
                                  await _toggleStar(context);
                                } else if (value == 'trash') {
                                  await _toggleTrash(context);
                                } else if (value == 'delete') {
                                  await _deleteEmail(context);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'star',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: isStarred ? Colors.amber : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isStarred ? 'Unstar' : 'Star',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'trash',
                                  child: Row(
                                    children: [
                                      Icon(
                                        folder == 'trash' ? Icons.restore_from_trash : Icons.delete,
                                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        folder == 'trash' ? 'Restore' : 'Move to Trash',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                if (folder == 'trash')
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_forever,
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
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