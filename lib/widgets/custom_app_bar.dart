import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/session_manager.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? avatarUrl;

  const CustomAppBar({super.key, this.avatarUrl});

  Future<void> _signOut() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        print("Token is null");
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
        print('Phản hồi từ server: ${response.statusCode} - ${response.body}');
        throw Exception('Đăng xuất thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi đăng xuất: $e');
      throw Exception('Lỗi khi đăng xuất: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  decoration: InputDecoration(
                    hintText: "Find email",
                    hintStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                    border: InputBorder.none, // No border in all states
                    enabledBorder: InputBorder.none, // No border when not focused
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
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
                          content: const Text('Are you sure to log out?', style: TextStyle(color: Colors.black),),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  await _signOut();
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