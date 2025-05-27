import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/session_manager.dart';
import 'package:testabc/widgets/home/custom_snackbar.dart';
import 'package:testabc/widgets/detail/email_action_button.dart';
import 'package:testabc/widgets/detail/email_app_bar.dart';
import 'package:testabc/widgets/detail/email_content.dart';
import 'package:testabc/widgets/detail/email_header.dart';
import 'package:universal_html/html.dart' as html;
import 'package:testabc/main.dart';

class EmailDetailScreen extends StatefulWidget {
  final String emailId;

  const EmailDetailScreen({
    Key? key,
    required this.emailId,
  }) : super(key: key);

  @override
  _EmailDetailScreenState createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  Map<String, dynamic>? email; // Store fetched email data
  String? _errorMessage;
  bool _isLoading = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchEmailData(); // Fetch email data when the widget is initialized
  }

  Future<void> _fetchEmailData() async {
    setState(() {
      _isLoading = true;
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

      // Lấy userId từ token
      userId = JwtDecoder.decode(token)['sub'];

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/email/${widget.emailId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final metadata = data['metadata'];
        if (metadata == null) {
          throw Exception('Metadata not found in response');
        }

        final senderResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/users/${metadata['senderId']}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        final senderData = jsonDecode(senderResponse.body)['metadata'];
        if (senderData == null) {
          throw Exception('Metadata not found in response');
        }

        // Lấy danh sách email của tất cả recipients, nhóm theo recipientType
        Map<String, List<String>> groupedRecipientEmails = {
          'to': [],
          'cc': [],
          'bcc': [],
        };
        final recipients = List<Map<String, dynamic>>.from(metadata['recipients'] ?? []);
        for (var recipient in recipients) {
          final recipientResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/users/${recipient['recipientId']}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          final recipientData = jsonDecode(recipientResponse.body)['metadata'];
          if (recipientData != null) {
            final recipientEmail = recipientData['email'] ?? 'unknown@example.com';
            final recipientType = recipient['recipientType']?.toLowerCase() ?? 'unknown';
            if (groupedRecipientEmails.containsKey(recipientType)) {
              groupedRecipientEmails[recipientType]!.add(recipientEmail);
            }
          }
        }

        // Kiểm tra xem email là do người dùng gửi hay nhận
        final isSentByUser = metadata['senderId'] == userId;

        setState(() {
          email = {
            'avatar': senderData['avatar']?.toString() ?? 'assets/default-avatar.png',
            'senderEmail': senderData['email']?.toString() ?? 'test@gmail.com',
            'id': metadata['id']?.toString() ?? '',
            'subject': metadata['subject']?.toString() ?? '',
            'sender': metadata['senderId']?.toString() ?? '',
            'date': metadata['createdAt']?.toString() ?? '',
            'body': metadata['body']?.toString() ?? '',
            'attachments': jsonEncode(metadata['attachments'] ?? []),
            'groupedRecipientEmails': groupedRecipientEmails, // Lưu danh sách recipients theo nhóm
            'isSentByUser': isSentByUser.toString(), // Lưu trạng thái gửi/nhận
          };
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load email: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching email: $e';
      });
      CustomSnackBar.show(
        context,
        message: _errorMessage!,
        backgroundColor: const Color.fromARGB(255, 204, 204, 233),
        borderColor: const Color.fromARGB(255, 105, 8, 250),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        final status = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();
        return status.values.every((s) => s.isGranted);
      } else {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          return true;
        } else if (status.isPermanentlyDenied) {
          CustomSnackBar.show(
            context,
            message: 'Storage permission is required to save files. Please enable it in settings.',
            backgroundColor: const Color.fromARGB(255, 204, 204, 233),
            borderColor: const Color.fromARGB(255, 105, 8, 250),
            duration: const Duration(seconds: 3),
          );
          return false;
        } else {
          CustomSnackBar.show(
            context,
            message: 'Storage permission denied',
            backgroundColor: const Color.fromARGB(255, 204, 204, 233),
            borderColor: const Color.fromARGB(255, 105, 8, 250),
            duration: const Duration(seconds: 3),
          );
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _downloadAttachment(BuildContext context, Map<String, dynamic> attachment) async {
    final fileUrl = attachment['fileUrl']?.toString();
    final fileName = attachment['fileName']?.toString() ?? 'downloaded_file';

    if (fileUrl == null || fileUrl.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Invalid file URL',
        backgroundColor: const Color.fromARGB(255, 204, 204, 233),
        borderColor: const Color.fromARGB(255, 105, 8, 250),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Downloading...',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final response = await http.get(Uri.parse(fileUrl));
      Navigator.of(context).pop();

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      if (kIsWeb) {
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        if (await _requestStoragePermission()) {
          Directory? saveDir;
          try {
            saveDir = await getExternalStorageDirectory();
            if (saveDir == null) {
              saveDir = await getTemporaryDirectory();
            }
          } catch (e) {
            saveDir = await getTemporaryDirectory();
          }

          final filePath = '${saveDir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          CustomSnackBar.show(
            context,
            message: 'File downloaded to $filePath',
            backgroundColor: const Color.fromARGB(255, 204, 204, 233),
            borderColor: const Color.fromARGB(255, 105, 8, 250),
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      CustomSnackBar.show(
        context,
        message: 'Error downloading file: $e',
        backgroundColor: const Color.fromARGB(255, 204, 204, 233),
        borderColor: const Color.fromARGB(255, 105, 8, 250),
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: email != null ? EmailAppBar(email: email!) : AppBar(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    EmailHeader(email: email!),
                    Divider(
                      height: 1,
                      color: ThemeProvider.of(context).isDarkMode
                          ? const Color(0xFF3C3C48)
                          : Colors.grey[300],
                    ),
                    Expanded(
                      child: EmailContent(
                        email: email!,
                        onDownload: _downloadAttachment,
                      ),
                    ),
                    EmailActionButtons(),
                  ],
                ),
    );
  }
}