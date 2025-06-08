import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:http/http.dart' as http;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/session_manager.dart';
import 'package:testabc/presentation/pages/home/email_detail_screen.dart';
import 'package:testabc/presentation/pages/home/compose_mail_page.dart';
import 'package:testabc/main.dart';

class EmailItem extends StatefulWidget {
  final Map<String, String> email;
  final VoidCallback? onEmailUpdated;
  final String? currentLabel;

  const EmailItem({
    super.key,
    required this.email,
    this.onEmailUpdated,
    this.currentLabel,
  });

  @override
  _EmailItemState createState() => _EmailItemState();
}

class _EmailItemState extends State<EmailItem> {
  bool _isLoadingStar = false;
  bool _isLoadingRead = false;
  bool _isLoadingTrash = false;
  bool _isLoadingDelete = false;
  bool _isLoadingAddLabel = false;
  bool _isLoadingRemoveLabel = false;

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

  Future<List<String>> _fetchLabels() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found')),
        );
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/label'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> labels = data['metadata'] ?? [];
        return labels.map((label) => label['labelName'].toString()).toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonDecode(response.body)['msg'] ?? 'Failed to fetch labels',
            ),
          ),
        );
        return [];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching labels: $e')),
      );
      return [];
    }
  }

  Future<void> _addToLabel(String labelName) async {
    setState(() {
      _isLoadingAddLabel = true;
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
        Uri.parse('${ApiConfig.baseUrl}/api/label/addEmail'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'labelName': labelName,
          'emailIds': [widget.email['id']],
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email added to label "$labelName"')),
        );
        widget.onEmailUpdated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonDecode(response.body)['msg'] ?? 'Failed to add email to label',
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
          _isLoadingAddLabel = false;
        });
      }
    }
  }

  Future<void> _removeFromLabel(String labelName) async {
    setState(() {
      _isLoadingRemoveLabel = true;
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
        Uri.parse('${ApiConfig.baseUrl}/api/label/removeEmail'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'labelName': labelName,
          'emailIds': [widget.email['id']],
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email removed from label "$labelName"')),
        );
        widget.onEmailUpdated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonDecode(response.body)['msg'] ?? 'Failed to remove email from label',
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
          _isLoadingRemoveLabel = false;
        });
      }
    }
  }

  void _showAddLabelDialog(BuildContext context) async {
    final labels = await _fetchLabels();
    if (labels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No labels available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeProvider.of(context).isDarkMode
              ? const Color(0xFF3C3C48)
              : Colors.grey[300],
          title: Text(
            'Add to Label',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: labels.length,
              itemBuilder: (context, index) {
                final label = labels[index];
                return ListTile(
                  title: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () {
                    _addToLabel(label);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.email['avatar'] ?? 'assets/default-avatar.png';
    final imageProvider = avatarUrl.startsWith('http')
        ? NetworkImage(avatarUrl)
        : AssetImage(avatarUrl) as ImageProvider;

    final subject = widget.email['subject'] ?? 'No subject';
    // Làm sạch và cắt ngắn subject
    final cleanedSubject = subject.replaceAll(RegExp(r'[\n\t]'), ' ').trim();
    final truncatedSubject =
        cleanedSubject.length > 50 ? '${cleanedSubject.substring(0, 50)}...' : cleanedSubject;
    final folder = widget.email['folder'];
    final body = widget.email['body'] ?? 'No body';

    // Phân tích body thành Quill Delta
    quill.Document document;
    try {
      final deltaJson = jsonDecode(body);
      document = quill.Document.fromJson(deltaJson);
    } catch (e) {
      document = quill.Document()..insert(0, body);
    }

    // Chuyển QuillDocument thành văn bản thuần để cắt ngắn
    String plainText = document.toPlainText().replaceAll(RegExp(r'[\n\t]'), ' ').trim();
    if (plainText.length > 50) {
      plainText = '${plainText.substring(0, 50)}...';
      // Tạo lại document với văn bản đã cắt ngắn
      document = quill.Document()..insert(0, plainText);
    }

    // Tạo QuillController
    final quillController = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Tạo FocusNode
    final focusNode = FocusNode();

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
                builder: (context) =>
                    EmailDetailScreen(emailId: widget.email['id']!),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
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
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.6),
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
                  SizedBox(
                    height: 40, // Giới hạn chiều cao cho 2 dòng
                    child: quill.QuillEditor(
                      focusNode: focusNode,
                      configurations: quill.QuillEditorConfigurations(
                        controller: quillController,
                        scrollable: false,
                        autoFocus: false,
                        expands: false,
                        enableInteractiveSelection: false, // Vô hiệu hóa chọn văn bản
                        disableClipboard: true, // Vô hiệu hóa clipboard
                        padding: const EdgeInsets.all(0),
                        customStyles: quill.DefaultStyles(
                          paragraph: quill.DefaultTextBlockStyle(
                            TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              height: 1.2,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                            const quill.HorizontalSpacing(0, 0),
                            const quill.VerticalSpacing(0, 0),
                            const quill.VerticalSpacing(0, 0),
                            null,
                          ),
                        ),
                      ),
                      scrollController: ScrollController(),
                    ),
                  ),
                ],
              ),
            ),
            _isLoadingStar ||
                    _isLoadingTrash ||
                    _isLoadingDelete ||
                    _isLoadingAddLabel ||
                    _isLoadingRemoveLabel
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.6),
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
                      } else if (value == 'add_label') {
                        _showAddLabelDialog(context);
                      } else if (value == 'remove_label') {
                        await _removeFromLabel(widget.currentLabel!);
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
                              folder == 'trash'
                                  ? Icons.restore_from_trash
                                  : Icons.delete,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.6),
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
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'add_label',
                        child: Row(
                          children: [
                            Icon(
                              Icons.label_outline,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add to Label',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (widget.currentLabel != null)
                        PopupMenuItem(
                          value: 'remove_label',
                          child: Row(
                            children: [
                              Icon(
                                Icons.label_off_outlined,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remove from Label',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

}