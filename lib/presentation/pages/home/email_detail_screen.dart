import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:testabc/config/api_config.dart';
import 'package:testabc/presentation/pages/home/compose_mail_page.dart';
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
  Map<String, dynamic>? email;
  Map<String, dynamic>? originalEmail;
  List<Map<String, dynamic>> replies = [];
  String? _errorMessage;
  bool _isLoading = false;
  String? userId;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _fetchEmailData();
  }

  Future<void> _fetchEmailData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final decodedToken = JwtDecoder.decode(token);
      userId = decodedToken['sub'];
      final userResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (userResponse.statusCode == 200) {
        userEmail = jsonDecode(userResponse.body)['metadata']['email'];
      } else {
        throw Exception('Failed to fetch user: ${userResponse.statusCode}');
      }

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
          throw Exception('Sender metadata not found');
        }

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
            'groupedRecipientEmails': groupedRecipientEmails,
            'isSentByUser': isSentByUser.toString(),
            'replyToEmailId': metadata['replyToEmailId']?.toString(),
          };
        });

        final repliesResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/email/replies'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'id': widget.emailId}),
        );

        if (repliesResponse.statusCode == 200) {
          final repliesData = jsonDecode(repliesResponse.body)['metadata'] as List<dynamic>;
          final List<Map<String, dynamic>> tempReplies = [];
          for (var reply in repliesData) {
            final replySenderResponse = await http.get(
              Uri.parse('${ApiConfig.baseUrl}/api/users/${reply['senderId']}'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            );
            final replySenderData = jsonDecode(replySenderResponse.body)['metadata'];
            tempReplies.add({
              'senderEmail': replySenderData['email']?.toString() ?? 'unknown@example.com',
              'body': reply['body']?.toString() ?? '',
              'date': reply['createdAt']?.toString() ?? '',
              'subject': reply['subject']?.toString() ?? '',
              'id': reply['id']?.toString() ?? '',
              'attachments': jsonEncode(reply['attachments'] ?? []),
            });
          }
          try {
            tempReplies.sort((a, b) {
              try {
                return DateTime.parse(a['date']).compareTo(DateTime.parse(b['date']));
              } catch (e) {
                print('Error parsing date: $e, a: ${a['date']}, b: ${b['date']}');
                return 0;
              }
            });
          } catch (e) {
            print('Error sorting replies: $e');
          }
          setState(() {
            replies = tempReplies;
          });
        } else {
          throw Exception('Failed to fetch replies: ${repliesResponse.statusCode}');
        }

        if (metadata['replyToEmailId'] != null) {
          final originalEmailResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/email/${metadata['replyToEmailId']}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (originalEmailResponse.statusCode == 200) {
            final originalData = jsonDecode(originalEmailResponse.body)['metadata'];
            final originalSenderResponse = await http.get(
              Uri.parse('${ApiConfig.baseUrl}/api/users/${originalData['senderId']}'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            );
            final originalSenderData = jsonDecode(originalSenderResponse.body)['metadata'];

            setState(() {
              originalEmail = {
                'senderEmail': originalSenderData['email']?.toString() ?? 'unknown@example.com',
                'subject': originalData['subject']?.toString() ?? '',
                'body': originalData['body']?.toString() ?? '',
                'date': originalData['createdAt']?.toString() ?? '',
                'attachments': jsonEncode(originalData['attachments'] ?? []),
              };
            });
          }
        }
      } else {
        throw Exception('Failed to load email: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching email: $e';
      });
      CustomSnackBar.show(
        context,
        message: _errorMessage!,
        backgroundColor: const Color.fromARGB(255, 204, 204, 233),
        borderColor: const Color.fromARGB(255, 105, 8, 250),
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _replyToEmail() {
    if (email == null || userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeMailPage(
          replyToEmailId: email!['id'],
          initialSubject: email!['subject'].startsWith('Re:') ? email!['subject'] : 'Re: ${email!['subject']}',
          initialTo: [email!['senderEmail']],
          initialBody: '\n\nOn ${email!['date']}, ${email!['senderEmail']} wrote:\n> ${email!['body'].replaceAll('\n', '\n> ')}',
        ),
      ),
    ).then((value) {
      _fetchEmailData();
    });
  }

  void _replyAllToEmail() {
    if (email == null || userId == null || userEmail == null) return;

    final recipients = email!['groupedRecipientEmails'] as Map<String, List<String>>;

    final allEmails = <String, String>{};

    if (email!['senderEmail'] != userEmail) {
      allEmails[email!['senderEmail']] = 'to';
    }

    for (var email in recipients['to'] ?? []) {
      if (email != userEmail) {
        allEmails[email] = 'to';
      }
    }

    for (var email in recipients['cc'] ?? []) {
      if (email != userEmail && !allEmails.containsKey(email)) {
        allEmails[email] = 'cc';
      }
    }

    for (var email in recipients['bcc'] ?? []) {
      if (email != userEmail && !allEmails.containsKey(email)) {
        allEmails[email] = 'cc';
      }
    }

    final toRecipients = allEmails.entries
        .where((entry) => entry.value == 'to')
        .map((entry) => entry.key)
        .toList();
    final ccRecipients = allEmails.entries
        .where((entry) => entry.value == 'cc')
        .map((entry) => entry.key)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeMailPage(
          replyToEmailId: email!['id'],
          initialSubject: email!['subject'].startsWith('Re:') ? email!['subject'] : 'Re: ${email!['subject']}',
          initialTo: toRecipients.isNotEmpty ? toRecipients : [email!['senderEmail']],
          initialCc: ccRecipients,
          initialBody: '\n\nOn ${email!['date']}, ${email!['senderEmail']} wrote:\n> ${email!['body'].replaceAll('\n', '\n> ')}',
        ),
      ),
    ).then((value) {
      _fetchEmailData();
    });
  }

  void _forwardEmail() {
    if (email == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeMailPage(
          initialSubject: email!['subject'].startsWith('Fwd:') ? email!['subject'] : 'Fwd: ${email!['subject']}',
          initialBody: '\n\n---------- Forwarded message ---------\nFrom: ${email!['senderEmail']}\nDate: ${email!['date']}\nSubject: ${email!['subject']}\n\n${email!['body']}',
          initialAttachments: (jsonDecode(email!['attachments']) as List<dynamic>)
              .map((a) => Attachment(
                    originalName: a['fileName'],
                    fileUrl: a['fileUrl'],
                    mimeType: a['mimeType'],
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: email != null
          ? EmailAppBar(email: email!)
          : AppBar(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : email == null
                  ? const Center(child: Text('Email not found'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EmailHeader(email: email!),
                        Divider(
                          height: 32,
                          thickness: 2,
                          color: ThemeProvider.of(context).isDarkMode
                              ? const Color(0xFF3C3C48)
                              : Colors.grey[300],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Original Email (if exists)
                                if (originalEmail != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'From: ${originalEmail!['senderEmail']}',
                                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                      fontFamily: 'Inter',
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 16,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('MMM d, h:mm a').format(DateTime.parse(originalEmail!['date'] ?? '')),
                                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                    fontFamily: 'Inter',
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        EmailContent(
                                          email: {
                                            'body': originalEmail!['body'] ?? '',
                                            'attachments': originalEmail!['attachments'] ?? '[]',
                                          },
                                          onDownload: _downloadAttachment,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    height: 32,
                                    thickness: 2,
                                    color: ThemeProvider.of(context).isDarkMode
                                        ? const Color(0xFF3C3C48)
                                        : Colors.grey[300],
                                  ),
                                ],
                                // Main Email
                                EmailContent(
                                  email: email!,
                                  onDownload: _downloadAttachment,
                                ),
                                Divider(
                                  height: 32,
                                  thickness: 2,
                                  color: ThemeProvider.of(context).isDarkMode
                                      ? const Color(0xFF3C3C48)
                                      : Colors.grey[300],
                                ),
                                // Replies
                                if (replies.isNotEmpty) ...[
                                  ...replies.map((reply) {
                                    String formattedTime = '';
                                    try {
                                      final timestamp = DateTime.tryParse(reply['date'] ?? '');
                                      if (timestamp != null) {
                                        formattedTime = DateFormat('MMM d, h:mm a').format(timestamp.toLocal());
                                      }
                                    } catch (e) {
                                      formattedTime = reply['date']?.toString() ?? '';
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'From: ${reply['senderEmail']}',
                                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                        fontFamily: 'Inter',
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 16,
                                                      ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                formattedTime,
                                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                      fontFamily: 'Inter',
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          EmailContent(
                                            email: {
                                              'body': reply['body'] ?? '',
                                              'attachments': reply['attachments'] ?? '[]',
                                            },
                                            onDownload: _downloadAttachment,
                                          ),
                                          Divider(
                                            height: 32,
                                            thickness: 2,
                                            color: ThemeProvider.of(context).isDarkMode
                                                ? const Color(0xFF3C3C48)
                                                : Colors.grey[300],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ),
                        EmailActionButtons(
                          onReply: _replyToEmail,
                          onReplyAll: _replyAllToEmail,
                          onForward: _forwardEmail,
                          isSentByUser: email?['isSentByUser'] == 'true',
                          hasReplies: replies.isNotEmpty,
                        ),
                      ],
                    ),
    );
  }
}