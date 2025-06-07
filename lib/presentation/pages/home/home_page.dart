import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/presentation/pages/home/compose_mail_page.dart';
import 'package:testabc/utils/session_manager.dart';
import 'package:testabc/widgets/detail/custom_app_bar.dart';
import 'package:testabc/widgets/home/email_drawer.dart';
import 'package:testabc/widgets/home/email_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  bool _isFetchingEmails = false;
  bool _isSearching = false;
  String? _errorMessage;
  String? _avatarUrl;
  String? _userId;
  List<Map<String, String>> _emails = [];
  List<String> _labels = [];
  late IO.Socket _socket;
  bool _isSearchMode = false;
  int _selectedIndex = 0;
  String? _selectedLabel;

  final List<String> _pages = ['inbox', 'sent', 'trash', 'starred', 'draft'];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchEmails('inbox');
    _fetchLabels();
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
      if (_pages[_selectedIndex] == 'inbox' && !_isSearchMode && _selectedLabel == null) {
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

  Future<void> _fetchLabels() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = "No token found";
        });
        return;
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
        setState(() {
          _labels = labels.map((label) => label['labelName'].toString()).toList();
        });
      } else {
        setState(() {
          _errorMessage = jsonDecode(response.body)['msg'] ?? 'Failed to fetch labels';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching labels: $e';
      });
    }
  }

  Future<void> _createLabel(String labelName) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = "No token found";
        });
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/label'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'labelName': labelName}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await _fetchLabels();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Label "$labelName" created successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _errorMessage = jsonDecode(response.body)['msg'] ?? 'Failed to create label';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating label: $e';
      });
    }
  }

  Future<void> _deleteLabel(String labelName) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = "No token found";
        });
        return;
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/label/$labelName'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await _fetchLabels();
        if (_selectedLabel == labelName) {
          setState(() {
            _selectedLabel = null;
          });
          _fetchEmails('inbox');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Label "$labelName" deleted successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _errorMessage = jsonDecode(response.body)['msg'] ?? 'Failed to delete label';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting label: $e';
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

  Future<void> _fetchEmails(String folder, {String? labelName}) async {
    setState(() {
      _isFetchingEmails = true;
      _errorMessage = null;
      _emails = [];
      _isSearchMode = false;
      _isSearching = false;
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

      String apiUrl;
      if (labelName != null) {
        apiUrl = '${ApiConfig.baseUrl}/api/label/$labelName/emails';
      } else if (folder == 'starred') {
        apiUrl = '${ApiConfig.baseUrl}/api/email/starred';
      } else {
        apiUrl = '${ApiConfig.baseUrl}/api/email/?folder=$folder';
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> emails = data['metadata'] ?? [];

        List<dynamic> filteredEmails;
        if (folder == 'starred' || labelName != null) {
          filteredEmails = emails;
        } else {
          filteredEmails = emails.where((email) => email['folder'] == folder).toList();
        }

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
            'subject': email['subject']?.toString() ?? 'No subject',
            'body': email['body']?.toString() ?? '',
            'createdAt': email['createdAt']?.toString() ?? '',
            'time': _formatTime(email['createdAt']?.toString() ?? ''),
            'attachments': jsonEncode(email['attachments'] ?? []),
            'starred': email['isStarred']?.toString() ?? 'false',
            'isDraft': email['isDraft']?.toString() ?? 'false',
            'isRead': email['isRead']?.toString() ?? 'false',
            'folder': email['folder']?.toString() ?? folder,
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

  void _handleSearchResults(List<Map<String, String>> searchResults, bool isSearching) {
    setState(() {
      _emails = searchResults;
      _isSearching = isSearching;
      _isSearchMode = true;
      _errorMessage = searchResults.isEmpty && !isSearching ? 'No emails found' : null;
    });
  }

  void _clearSearch() {
    setState(() {
      _isSearchMode = false;
      _isSearching = false;
      _errorMessage = null;
      _selectedLabel = null;
    });
    _fetchEmails(_pages[_selectedIndex]);
  }

  String _formatTime(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isSearchMode = false;
      _isSearching = false;
      _selectedLabel = null;
    });
    _fetchEmails(_pages[index]);
  }

  void _onLabelSelected(String labelName) {
    setState(() {
      _selectedIndex = 0;
      _isSearchMode = false;
      _isSearching = false;
      _selectedLabel = labelName;
    });
    _fetchEmails('inbox', labelName: labelName);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fabColor = isDark ? Colors.grey[800] : const Color.fromARGB(255, 165, 193, 235);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        avatarUrl: _avatarUrl,
        onSearch: _handleSearchResults,
        onClearSearch: _clearSearch,
      ),
      drawer: EmailDrawer(
        onItemSelected: _onItemTapped,
        onLabelSelected: _onLabelSelected,
        onLabelCreated: _createLabel,
        onLabelDeleted: _deleteLabel,
        labels: _labels,
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
                  onRefresh: () => _selectedLabel != null
                      ? _fetchEmails('inbox', labelName: _selectedLabel)
                      : _fetchEmails(_pages[_selectedIndex]),
                  child: _isFetchingEmails || _isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : _emails.isEmpty
                          ? Center(
                              child: Text(
                                _isSearchMode
                                    ? 'No emails found'
                                    : _selectedLabel != null
                                        ? 'No emails in label $_selectedLabel'
                                        : 'No emails in ${_pages[_selectedIndex]}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : EmailList(
                              emails: _emails,
                              currentLabel: _selectedLabel, // Pass currentLabel to EmailList
                              onEmailUpdated: () => _selectedLabel != null
                                  ? _fetchEmails('inbox', labelName: _selectedLabel)
                                  : _fetchEmails(_pages[_selectedIndex]),
                            ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ComposeMailPage()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        tooltip: 'Compose Email',
        child: const Icon(Icons.edit),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}