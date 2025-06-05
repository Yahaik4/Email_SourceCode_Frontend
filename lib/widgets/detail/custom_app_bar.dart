import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/session_manager.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? avatarUrl;
  final Function(List<Map<String, String>>, bool) onSearch; // Callback để gửi kết quả tìm kiếm và trạng thái loading
  final VoidCallback onClearSearch; // Callback để hủy tìm kiếm

  const CustomAppBar({
    super.key,
    this.avatarUrl,
    required this.onSearch,
    required this.onClearSearch,
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
      onSearch([], true); // Bật trạng thái loading
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

        onSearch(emailList.cast<Map<String, String>>(), false); // Tắt trạng thái loading
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
                              onClearSearch(); // Gọi callback để hủy tìm kiếm
                            },
                          )
                        : null,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  onChanged: (value) {
                    if (value.isEmpty) {
                      onClearSearch(); // Hủy tìm kiếm khi TextField rỗng
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
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: PopupMenuButton<String>(
                  color: Theme.of(context).popupMenuTheme.color,
                  onSelected: (value) async {
                    if (value == 'profile') {
                      Navigator.pushNamed(context, '/profile');
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