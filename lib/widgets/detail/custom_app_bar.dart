import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/main.dart';
import 'package:testabc/utils/session_manager.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? avatarUrl;
  final Function(List<Map<String, String>>, bool) onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onProfileTapped;

  const CustomAppBar({
    super.key,
    this.avatarUrl,
    required this.onSearch,
    required this.onClearSearch,
    required this.onProfileTapped,
  });

  Future<void> _signOut(BuildContext context) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('Không có token để đăng xuất');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/signout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await SessionManager.clear();
        print('Đăng xuất thành công');
      } else {
        throw Exception('Đăng xuất thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi khi đăng xuất: $e');
    }
  }

  Future<Map<String, String>> _fetchUserName(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return {
          'username': userData['metadata']['username']?.toString() ?? 'Unknown User',
          'avatar': userData['metadata']['avatar']?.toString() ?? 'assets/default-avatar.png',
          'email': userData['metadata']['email']?.toString() ?? 'unknown@example.com',
        };
      }
      return {
        'username': 'Unknown User',
        'avatar': 'assets/default-avatar.png',
        'email': 'unknown@example.com',
      };
    } catch (e) {
      return {
        'username': 'Unknown User',
        'avatar': 'assets/default-avatar.png',
        'email': 'unknown@example.com',
      };
    }
  }

  Future<void> _searchEmails(String keyword, String token, BuildContext context) async {
    try {
      onSearch([], true);
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/email/search'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'keyword': keyword}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> emails = data['metadata'] ?? [];

        final uniqueSenderIds = emails.map((email) => email['senderId'].toString()).toSet();
        final senderData = <String, Map<String, String>>{};
        for (final senderId in uniqueSenderIds) {
          final data = await _fetchUserName(senderId, token);
          senderData[senderId] = data;
        }

        final emailList = emails.map((email) {
          final senderId = email['senderId'].toString();
          return {
            'id': email['id']?.toString() ?? '',
            'sender': senderData[senderId]?['username'] ?? 'Unknown User',
            'senderEmail': senderData[senderId]?['email'] ?? 'unknown@example.com',
            'avatar': senderData[senderId]?['avatar'] ?? 'assets/default-avatar.png',
            'subject': email['subject']?.toString() ?? '',
            'body': email['body']?.toString() ?? '',
            'createdAt': email['createdAt']?.toString() ?? '',
            'time': _formatTime(email['createdAt']?.toString() ?? ''),
            'attachments': jsonEncode(email['attachments'] ?? []),
            'isRead': jsonEncode(email['isRead'] ?? true),
          };
        }).toList();

        onSearch(emailList.cast<Map<String, String>>(), false);
      } else {
        onSearch([], false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to search emails: ${response.body}')),
        );
      }
    } catch (e) {
      onSearch([], false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching emails: $e')),
      );
    }
  }

  Future<void> _advancedSearch({
    required String? from,
    required String? to,
    required String? subject,
    required String? keyword,
    required String folder,
    required String token,
    required BuildContext context,
    String? hasAttachments,
  }) async {
    try {
      onSearch([], true);
      final body = {
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        'folder': folder,
        if (hasAttachments != null) 'hasAttachment': hasAttachments,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/email/searchAdvanced'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> emails = data['metadata'] ?? [];

        final uniqueSenderIds = emails.map((email) => email['senderId'].toString()).toSet();
        final senderData = <String, Map<String, String>>{};
        for (final senderId in uniqueSenderIds) {
          final data = await _fetchUserName(senderId, token);
          senderData[senderId] = data;
        }

        final emailList = emails.map((email) {
          final senderId = email['senderId'].toString();
          return {
            'id': email['id']?.toString() ?? '',
            'sender': senderData[senderId]?['username'] ?? 'Unknown User',
            'senderEmail': senderData[senderId]?['email'] ?? 'unknown@example.com',
            'avatar': senderData[senderId]?['avatar'] ?? 'assets/default-avatar.png',
            'subject': email['subject']?.toString() ?? '',
            'body': email['body']?.toString() ?? '',
            'createdAt': email['createdAt']?.toString() ?? '',
            'time': _formatTime(email['createdAt']?.toString() ?? ''),
            'hasAttachment': jsonEncode(email['attachments'] ?? []),
            'isRead': jsonEncode(email['isRead'] ?? true),
          };
        }).toList();

        onSearch(emailList.cast<Map<String, String>>(), false);
      } else {
        onSearch([], false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to search emails: ${response.body}')),
        );
      }
    } catch (e) {
      onSearch([], false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching emails: $e')),
      );
    }
  }

  String _formatTime(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }

  void _showAdvancedSearchDialog(BuildContext context) {
    final fromController = TextEditingController();
    final toController = TextEditingController();
    final subjectController = TextEditingController();
    final keywordController = TextEditingController();
    String selectedFolder = 'all';
    bool hasAttachments = false; // New state for checkbox
    final themeProvider = ThemeProvider.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false; // Track loading state

          return AlertDialog(
            backgroundColor: Theme.of(context).popupMenuTheme.color,
            title: Text(
              'Advanced Search',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fromController,
                    decoration: InputDecoration(
                      labelText: 'From',
                      labelStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: toController,
                    decoration: InputDecoration(
                      labelText: 'To',
                      labelStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      labelStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: keywordController,
                    decoration: InputDecoration(
                      labelText: 'Keyword',
                      labelStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedFolder,
                    decoration: InputDecoration(
                      labelText: 'Folder',
                      labelStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: ['all', 'sent', 'inbox', 'draft', 'trash'].map((folder) {
                      return DropdownMenuItem(
                        value: folder,
                        child: Container(
                          color: themeProvider.isDarkMode
                              ? const Color(0xFF1F1F2A)
                              : const Color.fromARGB(255, 228, 227, 227),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          child: Text(
                            folder.capitalize(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedFolder = value;
                        });
                      }
                    },
                    dropdownColor: themeProvider.isDarkMode
                        ? const Color(0xFF1F1F2A)
                        : const Color.fromARGB(255, 228, 227, 227),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: hasAttachments,
                        onChanged: (value) {
                          setState(() {
                            hasAttachments = value ?? false;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      Text(
                        'Has Attachments',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 10),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });
                        try {
                          final token = await SessionManager.getToken();
                          if (token == null) {
                            setState(() {
                              isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No token found')),
                            );
                            return;
                          }
                          await _advancedSearch(
                            from: fromController.text,
                            to: toController.text,
                            subject: subjectController.text,
                            keyword: keywordController.text,
                            folder: selectedFolder,
                            token: token,
                            context: context,
                            hasAttachments: hasAttachments ? "true" : null,
                          );
                          setState(() {
                            isLoading = false;
                          });
                          Navigator.pop(context);
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                child: Text(
                  isLoading ? 'Searching...' : 'Search',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController _searchController = TextEditingController();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor ??
                (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1F1F2A)
                    : Colors.grey[50]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black54
                    : Colors.black12,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Find email",
                    hintStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              onClearSearch();
                            },
                          )
                        : null,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  onChanged: (value) {
                    if (value.isEmpty) {
                      onClearSearch();
                    }
                  },
                  onSubmitted: (value) async {
                    if (value.isNotEmpty) {
                      try {
                        final token = await SessionManager.getToken();
                        if (token == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No token found')),
                          );
                          return;
                        }
                        await _searchEmails(value, token, context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.tune,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () => _showAdvancedSearchDialog(context),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: PopupMenuButton<String>(
                  color: Theme.of(context).popupMenuTheme.color,
                  onSelected: (value) async {
                    if (value == 'profile') {
                      onProfileTapped();
                    } else if (value == 'logout') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Log out'),
                          content: const Text('Are you sure to log out?', style: TextStyle(color: Colors.black)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  await _signOut(context);
                                  Navigator.pop(context);
                                  Navigator.pushReplacementNamed(context, '/login');
                                } catch (e) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $e')),
                                  );
                                }
                              },
                              child: const Text('Do it!'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Profile',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Log out',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: CircleAvatar(
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl!) as ImageProvider
                        : const AssetImage('assets/default-avatar.png') as ImageProvider,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}