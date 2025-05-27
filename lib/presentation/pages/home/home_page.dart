import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/session_manager.dart';
import 'package:testabc/widgets/custom_app_bar.dart';
import 'package:testabc/widgets/email_drawer.dart';
import 'package:testabc/widgets/email_list.dart';
import 'package:testabc/widgets/compose_mail_fab.dart';
import 'compose_mail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  bool _isFetchingEmails = false;
  String? _errorMessage;
  String? _avatarUrl;
  String? _userId;
  List<Map<String, String>> _emails = [];
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchEmails('inbox');
    _initWebSocket();
  }

  void _initWebSocket() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      print('No token found for WebSocket connection at ${DateTime.now()}');
      return;
    }

    _socket = IO.io(ApiConfig.webSocketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'token': token},
    });

    _socket.connect();
    print('Attempting to connect WebSocket to ${ApiConfig.webSocketUrl} at ${DateTime.now()}');

    _socket.onConnect((_) {
      print('WebSocket connected at ${DateTime.now()}');
    });

    _socket.onConnectError((error) {
      print('WebSocket connect error at ${DateTime.now()}: $error');
    });

    _socket.on('newEmail', (data) async {
      print('New email notification received at ${DateTime.now()}: $data');
      if (_pages[_selectedIndex] == 'inbox') {
        await _fetchEmails('inbox');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New email received, list updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    _socket.onDisconnect((_) {
      print('WebSocket disconnected at ${DateTime.now()}, attempting to reconnect...');
      _socket.connect();
    });

    _socket.onError((error) {
      print('WebSocket error at ${DateTime.now()}: $error');
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = "No token found";
          _isLoading = false;
        });
        return;
      }

      _userId = JwtDecoder.decode(token)['sub'];

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$_userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          _avatarUrl = userData['metadata']['avatar']?.toString() ?? 'assets/default-avatar.png';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = jsonDecode(response.body)['msg'] ?? 'Failed to fetch user data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
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
      } else {
        return {
          'username': 'Unknown User',
          'avatar': 'assets/default-avatar.png',
          'email': 'unknown@example.com',
        };
      }
    } catch (e) {
      return {
        'username': 'Unknown User',
        'avatar': 'assets/default-avatar.png',
        'email': 'unknown@example.com',
      };
    }
  }

  Future<void> _fetchEmails(String folder) async {
    setState(() {
      _isFetchingEmails = true;
      _errorMessage = null;
      _emails = [];
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = "No token found";
          _isFetchingEmails = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/email/?folder=$folder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> emails = data['metadata'];

        List<dynamic> filteredEmails;
        if (folder == 'sent') {
          filteredEmails = emails.where((email) => email['senderId'] == _userId).toList();
        } else {
          filteredEmails = emails.where((email) {
            final recipients = email['recipients'] as List<dynamic>? ?? [];
            return recipients.any((recipient) => recipient['recipientId'] == _userId);
          }).toList();
        }

        // Sort emails by createdAt, newest first
        filteredEmails.sort((a, b) {
          final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

        final uniqueSenderIds = filteredEmails.map((email) => email['senderId'].toString()).toSet();

        final senderData = <String, Map<String, String>>{};
        for (final senderId in uniqueSenderIds) {
          final data = await _fetchUserName(senderId, token);
          senderData[senderId] = data;
        }

        final emailList = filteredEmails.map((email) {
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
          };
        }).toList();

        setState(() {
          _emails = emailList.cast<Map<String, String>>();
          _isFetchingEmails = false;
        });
      } else {
        setState(() {
          _errorMessage = jsonDecode(response.body)['msg'] ?? 'Failed to fetch emails';
          _isFetchingEmails = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching emails: $e';
        _isFetchingEmails = false;
      });
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

  int _selectedIndex = 0;
  final List<String> _pages = ['inbox', 'sent', 'trash', 'starred', 'draft', 'all'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _fetchEmails(_pages[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(avatarUrl: _avatarUrl),
      drawer: EmailDrawer(
        onItemSelected: _onItemTapped,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchEmails(_pages[_selectedIndex]),
                  child: _isFetchingEmails
                      ? const Center(child: CircularProgressIndicator())
                      : _emails.isEmpty
                          ? Center(
                              child: Text(
                                'No emails in \\${_pages[_selectedIndex]}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : EmailList(emails: _emails),
                ),
      floatingActionButton: ComposeMailFab(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ComposeMailPage(),
            ),
          );
        },
      ),
    );
  }
}