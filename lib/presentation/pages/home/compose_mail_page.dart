import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:testabc/main.dart';
import 'dart:io';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/session_manager.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:jwt_decoder/jwt_decoder.dart'; // Added for decoding JWT

class Attachment {
  final String originalName;
  final File? file; // For mobile (dart:io File)
  final List<int>? bytes; // For web (file bytes)
  final String? fileUrl; // For draft attachments
  final String? mimeType; // For draft attachments

  Attachment({
    required this.originalName,
    this.file,
    this.bytes,
    this.fileUrl,
    this.mimeType,
  });
}

class ComposeMailPage extends StatefulWidget {
  final String? emailId; // For editing drafts
  final String? replyToEmailId; // For replying to an email
  final String? initialSubject; // Pre-filled subject for replies/forwards
  final List<String>? initialTo; // Pre-filled "To" recipients for replies
  final List<String>? initialCc; // Pre-filled "CC" recipients for replies
  final String? initialBody; // Pre-filled body for replies/forwards
  final List<Attachment>? initialAttachments; // Pre-filled attachments for forwards

  const ComposeMailPage({
    Key? key,
    this.emailId,
    this.replyToEmailId,
    this.initialSubject,
    this.initialTo,
    this.initialCc,
    this.initialBody,
    this.initialAttachments,
  }) : super(key: key);

  @override
  State<ComposeMailPage> createState() => _ComposeMailPageState();
}

class _ComposeMailPageState extends State<ComposeMailPage> {
  final TextEditingController toController = TextEditingController();
  final TextEditingController ccController = TextEditingController();
  final TextEditingController bccController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final quill.QuillController _quillController = quill.QuillController.basic();
  final List<Map<String, String>> toRecipients = [];
  final List<Map<String, String>> ccRecipients = [];
  final List<Map<String, String>> bccRecipients = [];
  bool _isLoading = false;
  bool _isSending = false;
  final List<Attachment> attachments = [];
  final FocusNode toFocusNode = FocusNode();
  final FocusNode ccFocusNode = FocusNode();
  final FocusNode bccFocusNode = FocusNode();
  String _defaultFontFamily = 'Inter';
  double _defaultFontSize = 16.0;
  final List<String> _fontFamilyOptions = ['Roboto', 'Inter', 'OpenSans', 'Lato'];

  @override
  void initState() {
    super.initState();
    _fetchUserSettings(); // Fetch user settings
    if (widget.emailId != null) {
      _fetchEmailDetails(widget.emailId!);
    }
    if (widget.initialSubject != null) {
      subjectController.text = widget.initialSubject!;
    }
    if (widget.initialBody != null) {
      // Initialize Quill editor with plain text
      _quillController.document = quill.Document()..insert(0, widget.initialBody!);
    }
    if (widget.initialTo != null && widget.initialTo!.isNotEmpty) {
      _initializeRecipients();
    }
    if (widget.initialCc != null && widget.initialCc!.isNotEmpty) {
      _initializeRecipients();
    }
    if (widget.initialAttachments != null) {
      setState(() {
        attachments.addAll(widget.initialAttachments!);
      });
    }
  }

  Future<void> _fetchUserSettings() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found')),
        );
        return;
      }

      // Decode JWT to get userId from 'sub' claim
      final decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['sub']?.toString();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found in token')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body)['metadata'];
        final settings = userData['setting'];
        setState(() {
          // Ensure font family is in supported options
          _defaultFontFamily = _fontFamilyOptions.contains(settings['font_family'])
              ? settings['font_family']
              : 'Inter';
          _defaultFontSize = (settings['font_size'] ?? 16).toDouble();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch user settings')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user settings: $e')),
      );
    }
  }

  Future<void> _initializeRecipients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Map<String, String>> newToRecipients = [];
      if (widget.initialTo != null && widget.initialTo!.isNotEmpty) {
        for (final email in widget.initialTo!) {
          if (_isValidEmail(email)) {
            final userId = await _fetchUserIdByEmail(email);
            if (userId != null && !newToRecipients.any((r) => r['email'] == email)) {
              newToRecipients.add({'id': userId, 'email': email});
            }
          }
        }
      }

      final List<Map<String, String>> newCcRecipients = [];
      if (widget.initialCc != null && widget.initialCc!.isNotEmpty) {
        for (final email in widget.initialCc!) {
          if (_isValidEmail(email)) {
            final userId = await _fetchUserIdByEmail(email);
            if (userId != null &&
                !newToRecipients.any((r) => r['email'] == email) &&
                !newCcRecipients.any((r) => r['email'] == email)) {
              newCcRecipients.add({'id': userId, 'email': email});
            }
          }
        }
      }

      setState(() {
        toRecipients.clear();
        ccRecipients.clear();
        toRecipients.addAll(newToRecipients);
        ccRecipients.addAll(newCcRecipients);
        toController.clear();
        ccController.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing recipients: $e')),
      );
    }
  }

  Future<Map<String, String>> _fetchUserById(String userId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        return {'id': userId, 'email': userId};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body)['metadata'];
        return {
          'id': userId,
          'email': userData['email']?.toString() ?? userId,
        };
      }
      return {'id': userId, 'email': userId};
    } catch (e) {
      return {'id': userId, 'email': userId};
    }
  }

  Future<String?> _fetchUserIdByEmail(String email) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found')),
        );
        return null;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/email'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body)['metadata'];
        return userData['id']?.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found for this email')),
      );
      return null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user: $e')),
      );
      return null;
    }
  }

  Future<void> _fetchEmailDetails(String emailId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/email/$emailId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final emailData = jsonDecode(response.body)['metadata'];
        final recipients = (emailData['recipients'] as List? ?? []);

        final uniqueRecipientIds = recipients.map((r) => r['recipientId'].toString()).toSet();
        final recipientData = <String, Map<String, String>>{};
        for (final id in uniqueRecipientIds) {
          final data = await _fetchUserById(id);
          recipientData[id] = data;
        }

        setState(() {
          toRecipients.addAll(recipients
              .where((r) => r['recipientType'] == 'to')
              .map((r) => {
                    'id': r['recipientId'].toString(),
                    'email': recipientData[r['recipientId']]!['email']!,
                  }));
          ccRecipients.addAll(recipients
              .where((r) => r['recipientType'] == 'cc')
              .map((r) => {
                    'id': r['recipientId'].toString(),
                    'email': recipientData[r['recipientId']]!['email']!,
                  }));
          bccRecipients.addAll(recipients
              .where((r) => r['recipientType'] == 'bcc')
              .map((r) => {
                    'id': r['recipientId'].toString(),
                    'email': recipientData[r['recipientId']]!['email']!,
                  }));
          subjectController.text = emailData['subject'] ?? '';

          // Khôi phục nội dung richtext từ Quill Delta JSON
          if (emailData['body'] != null && emailData['body'].isNotEmpty) {
            try {
              final deltaJson = jsonDecode(emailData['body']);
              _quillController.document = quill.Document.fromJson(deltaJson);
            } catch (e) {
              // Nếu không phải JSON hợp lệ, chèn văn bản thuần (hỗ trợ tương thích ngược)
              _quillController.document = quill.Document()..insert(0, emailData['body']);
            }
          } else {
            _quillController.document = quill.Document();
          }

          attachments.addAll((emailData['attachments'] as List? ?? [])
              .map((a) => Attachment(
                    originalName: a['fileName'],
                    fileUrl: a['fileUrl'],
                    mimeType: a['mimeType'],
                  ))
              .toList());
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonDecode(response.body)['msg'] ?? 'Failed to fetch email details',
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching email: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    toController.dispose();
    ccController.dispose();
    bccController.dispose();
    subjectController.dispose();
    _quillController.dispose();
    toFocusNode.dispose();
    ccFocusNode.dispose();
    bccFocusNode.dispose();
    super.dispose();
  }

  String _getMimeType(String fileName) {
    return lookupMimeType(fileName) ?? 'application/octet-stream';
  }

  bool _hasContent() {
    return toRecipients.isNotEmpty ||
        ccRecipients.isNotEmpty ||
        bccRecipients.isNotEmpty ||
        subjectController.text.isNotEmpty ||
        !_quillController.document.isEmpty() ||
        attachments.isNotEmpty ||
        toController.text.isNotEmpty ||
        ccController.text.isNotEmpty ||
        bccController.text.isNotEmpty;
  }

  String _getQuillDeltaJson() {
    return jsonEncode(_quillController.document.toDelta().toJson());
  }

  Future<void> _sendMail() async {
    if (_isSending) return; // Ngăn gửi nhiều lần khi đang loading

    setState(() {
      _isSending = true; // Bật trạng thái loading
    });

    try {
      String? token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found. Please log in again.')),
        );
        setState(() {
          _isSending = false; // Tắt loading nếu có lỗi
        });
        return;
      }

      List<Map<String, String>> recipients = [];
      recipients.addAll(toRecipients.map((r) => {
            "recipientId": r['email']!,
            "recipientType": "to",
          }));
      recipients.addAll(ccRecipients.map((r) => {
            "recipientId": r['email']!,
            "recipientType": "cc",
          }));
      recipients.addAll(bccRecipients.map((r) => {
            "recipientId": r['email']!,
            "recipientType": "bcc",
          }));

      if (recipients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one recipient in To, Cc, or Bcc.')),
        );
        setState(() {
          _isSending = false; // Tắt loading nếu có lỗi
        });
        return;
      }

      String recipientsJson = jsonEncode(recipients);

      if (widget.emailId != null) {
        var updateRequest = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/api/email/updateDraft'),
        );

        updateRequest.headers['Authorization'] = 'Bearer $token';
        updateRequest.fields['id'] = widget.emailId!;
        updateRequest.fields['subject'] = subjectController.text;
        updateRequest.fields['body'] = _getQuillDeltaJson();
        updateRequest.fields['recipients'] = recipientsJson;
        if (widget.replyToEmailId != null) {
          updateRequest.fields['replyToEmailId'] = widget.replyToEmailId!;
        }

        if (attachments.isNotEmpty) {
          if (kIsWeb) {
            for (var attachment in attachments.where((a) => a.fileUrl == null)) {
              if (attachment.bytes != null) {
                updateRequest.files.add(http.MultipartFile.fromBytes(
                  'attachments',
                  attachment.bytes!,
                  filename: attachment.originalName,
                  contentType: MediaType.parse(_getMimeType(attachment.originalName)),
                ));
              }
            }
          } else {
            for (var attachment in attachments.where((a) => a.fileUrl == null)) {
              if (attachment.file != null) {
                updateRequest.files.add(
                  await http.MultipartFile.fromPath(
                    'attachments',
                    attachment.file!.path,
                    filename: attachment.originalName,
                    contentType: MediaType.parse(_getMimeType(attachment.originalName)),
                  ),
                );
              }
            }
          }
        }

        final updateResponse = await updateRequest.send();
        final updateResponseBody = await updateResponse.stream.bytesToString();

        if (updateResponse.statusCode != 200) {
          String errorMessage = 'Failed to update draft: $updateResponseBody';
          try {
            final errorJson = jsonDecode(updateResponseBody);
            errorMessage = errorJson['message'] ?? errorMessage;
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
          setState(() {
            _isSending = false; // Tắt loading
          });
          return;
        }

        final sendResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/email/sent'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'id': widget.emailId}),
        );

        if (sendResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email sent successfully with ${attachments.length} attachment(s)'),
            ),
          );
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          String errorMessage = 'Failed to send email: ${sendResponse.body}';
          try {
            final errorJson = jsonDecode(sendResponse.body);
            errorMessage = errorJson['message'] ?? errorMessage;
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } else {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/api/email/creatAndSendEmail'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        request.fields['subject'] = subjectController.text;
        request.fields['body'] = _getQuillDeltaJson();
        request.fields['recipients'] = recipientsJson;
        if (widget.replyToEmailId != null) {
          request.fields['replyToEmailId'] = widget.replyToEmailId!;
        }

        if (attachments.isNotEmpty) {
          if (kIsWeb) {
            for (var attachment in attachments) {
              if (attachment.bytes != null) {
                request.files.add(http.MultipartFile.fromBytes(
                  'attachments',
                  attachment.bytes!,
                  filename: attachment.originalName,
                  contentType: MediaType.parse(_getMimeType(attachment.originalName)),
                ));
              }
            }
          } else {
            for (var attachment in attachments) {
              if (attachment.file != null) {
                request.files.add(
                  await http.MultipartFile.fromPath(
                    'attachments',
                    attachment.file!.path,
                    filename: attachment.originalName,
                    contentType: MediaType.parse(_getMimeType(attachment.originalName)),
                  ),
                );
              }
            }
          }
        }

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          print(_getQuillDeltaJson);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email sent successfully with ${attachments.length} attachment(s)'),
            ),
          );
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          String errorMessage = 'Failed to send email: $responseBody';
          try {
            final errorJson = jsonDecode(responseBody);
            errorMessage = errorJson['message'] ?? errorMessage;
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email: $e')),
      );
    } finally {
      setState(() {
        _isSending = false; // Tắt loading sau khi hoàn thành
      });
    }
  }

  Future<void> _saveDraft() async {
    try {
      String? token = await SessionManager.getToken();
      if (token == null) {
        return;
      }

      List<Map<String, String>> recipients = [];
      recipients.addAll(toRecipients.map((r) => {
            "recipientId": r['email']!,
            "recipientType": "to",
          }));
      recipients.addAll(ccRecipients.map((r) => {
            "recipientId": r['email']!,
            "recipientType": "cc",
          }));
      recipients.addAll(bccRecipients.map((r) => {
            "recipientId": r['email']!,
            "recipientType": "bcc",
          }));

      String recipientsJson = jsonEncode(recipients);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(widget.emailId != null
            ? '${ApiConfig.baseUrl}/api/email/updateDraft'
            : '${ApiConfig.baseUrl}/api/email/saveDraft'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      if (widget.emailId != null) {
        request.fields['id'] = widget.emailId!;
      }
      if (subjectController.text.isNotEmpty) {
        request.fields['subject'] = subjectController.text;
      }
      if (!_quillController.document.isEmpty()) {
        request.fields['body'] = _getQuillDeltaJson();
      }
      if (recipients.isNotEmpty) {
        request.fields['recipients'] = recipientsJson;
      }
      if (widget.replyToEmailId != null) {
        request.fields['replyToEmailId'] = widget.replyToEmailId!;
      }

      if (attachments.isNotEmpty) {
        if (kIsWeb) {
          for (var attachment in attachments.where((a) => a.fileUrl == null)) {
            if (attachment.bytes != null) {
              request.files.add(http.MultipartFile.fromBytes(
                'attachments',
                attachment.bytes!,
                filename: attachment.originalName,
                contentType: MediaType.parse(_getMimeType(attachment.originalName)),
              ));
            }
          }
        } else {
          for (var attachment in attachments.where((a) => a.fileUrl == null)) {
            if (attachment.file != null) {
              request.files.add(
                await http.MultipartFile.fromPath(
                  'attachments',
                  attachment.file!.path,
                  filename: attachment.originalName,
                  contentType: MediaType.parse(_getMimeType(attachment.originalName)),
                ),
              );
            }
          }
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved successfully')),
        );
      } else {
        String errorMessage = 'Failed to save draft: $responseBody';
        try {
          final errorJson = jsonDecode(responseBody);
          errorMessage = errorJson['message'] ?? errorMessage;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving draft: $e')),
      );
    }
  }

  Future<void> _attachFile() async {
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      for (PlatformFile file in result.files) {
        if (file.size > maxSizeInBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${file.name} exceeds 5MB limit')),
          );
          continue;
        }

        if (kIsWeb) {
          if (file.bytes != null) {
            setState(() {
              attachments.add(Attachment(
                originalName: file.name,
                bytes: file.bytes,
              ));
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to read file: ${file.name}')),
            );
          }
        } else {
          if (file.path != null) {
            setState(() {
              attachments.add(Attachment(
                originalName: file.name,
                file: File(file.path!),
              ));
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to read file path: ${file.name}')),
            );
          }
        }
      }
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _addRecipient(String email, String field) async {
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email format')),
      );
      return;
    }

    final userId = await _fetchUserIdByEmail(email);
    if (userId == null) return;

    setState(() {
      final recipient = {'id': userId, 'email': email};
      if (field == 'to' && !toRecipients.any((r) => r['email'] == email)) {
        toRecipients.add(recipient);
        toController.clear();
      } else if (field == 'cc' && !ccRecipients.any((r) => r['email'] == email)) {
        ccRecipients.add(recipient);
        ccController.clear();
      } else if (field == 'bcc' && !bccRecipients.any((r) => r['email'] == email)) {
        bccRecipients.add(recipient);
        bccController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = ThemeProvider.of(context).isDarkMode;
    final textStyle = theme.textTheme.bodyMedium!.copyWith(fontFamily: 'Inter');
    final contentPadding = const EdgeInsets.symmetric(vertical: 14, horizontal: 16);

    return WillPopScope(
      onWillPop: () async {
        if (_hasContent()) {
          await _saveDraft();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            widget.emailId != null
                ? 'Edit Draft'
                : widget.replyToEmailId != null
                    ? 'Reply'
                    : 'Compose email',
            style: theme.textTheme.titleLarge!.copyWith(
              fontSize: 22,
              fontFamily: 'Inter',
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _attachFile,
              tooltip: 'Attachments',
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _isSending ? null : _sendMail,
              tooltip: 'Send',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRecipientField('To', toController, toFocusNode, toRecipients, 'to', contentPadding),
                      const SizedBox(height: 8),
                      _buildRecipientField('Cc', ccController, ccFocusNode, ccRecipients, 'cc', contentPadding),
                      const SizedBox(height: 8),
                      _buildRecipientField('Bcc', bccController, bccFocusNode, bccRecipients, 'bcc', contentPadding),
                      const SizedBox(height: 8),
                      _buildTextField('Subject', subjectController, contentPadding),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: quill.QuillToolbar.simple(
                                configurations: quill.QuillSimpleToolbarConfigurations(
                                  controller: _quillController,
                                  multiRowsDisplay: false,
                                  showBoldButton: true,
                                  showItalicButton: true,
                                  showUnderLineButton: true,
                                  showFontFamily: false,
                                  showFontSize: true,
                                  showListCheck: false,
                                  showBackgroundColorButton: false,
                                  showColorButton: false,
                                  showListBullets: false,
                                  showSearchButton: false,
                                  // fontFamilyValues: {'Roboto' : 'Roboto', 'Inter' : 'Inter', 'OpenSans' : 'OpenSans', 'Lato' : 'Lato'},
                                  fontSizesValues: {'10': '10', '12': '12', '14': '14', '17': '17', '24': '24'},
                                  showClipboardCut: false,
                                  showClipboardCopy: false,
                                  showClipboardPaste: false,
                                  showListNumbers: false,
                                  showAlignmentButtons: false,
                                  showHeaderStyle: false,
                                  showLink: false,
                                  showCodeBlock: false,
                                  showInlineCode: false,
                                  showQuote: false,
                                  showIndent: false,
                                  showUndo: false,
                                  showSubscript: false,
                                  
                                  showSuperscript: false,
                                  showRedo: false,
                                  color: isDarkMode ? Colors.black87 : const Color.fromARGB(195, 184, 183, 183),
                                ),
                              ),
                            ),
                            Container(
                              height: 200,
                              padding: contentPadding,
                              child: quill.QuillEditor.basic(
                                configurations: quill.QuillEditorConfigurations(
                                  controller: _quillController,
                                  placeholder: widget.replyToEmailId != null ? 'Reply' : 'Compose email',
                                  customStyles: quill.DefaultStyles(
                                    paragraph: quill.DefaultTextBlockStyle(
                                      TextStyle( // Use TextStyle directly
                                        fontFamily: _defaultFontFamily,
                                        fontSize: _defaultFontSize,
                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                      ),
                                      const quill.HorizontalSpacing(8, 8),
                                      const quill.VerticalSpacing(4, 4),
                                      const quill.VerticalSpacing(0, 0),
                                      BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Colors.blueGrey)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (attachments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Attachments',
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontSize: 16,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: attachments.map((attachment) => Chip(
                            label: Text(
                              attachment.originalName,
                              style: theme.textTheme.bodyMedium!.copyWith(fontFamily: 'Inter'),
                            ),
                            backgroundColor: theme.inputDecorationTheme.fillColor,
                            deleteIcon: Icon(
                              Icons.close,
                              size: 18,
                              color: theme.iconTheme.color,
                            ),
                            onDeleted: () {
                              setState(() {
                                attachments.remove(attachment);
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: theme.primaryColor),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRecipientField(
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    List<Map<String, String>> recipients,
    String field,
    EdgeInsets contentPadding,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          style: theme.textTheme.bodyMedium!.copyWith(fontFamily: 'Inter'),
          cursorColor: theme.iconTheme.color,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: theme.inputDecorationTheme.labelStyle,
            border: theme.inputDecorationTheme.border,
            enabledBorder: theme.inputDecorationTheme.enabledBorder,
            focusedBorder: theme.inputDecorationTheme.focusedBorder,
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor,
            contentPadding: contentPadding,
            prefixIconColor: theme.inputDecorationTheme.prefixIconColor,
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.add, color: theme.brightness == Brightness.dark ? Colors.green[300] : Colors.green[700]),
                    onPressed: () => _addRecipient(controller.text, field),
                    tooltip: 'Add $label',
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
        if (recipients.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 2, bottom: 2),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recipients.map((r) => Chip(
                label: Text(
                  r['email']!,
                  style: theme.textTheme.bodyMedium!.copyWith(fontFamily: 'Inter'),
                ),
                backgroundColor: theme.inputDecorationTheme.fillColor,
                deleteIcon: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.iconTheme.color,
                ),
                onDeleted: () {
                  setState(() {
                    recipients.remove(r);
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: theme.primaryColor),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    EdgeInsets contentPadding,
  ) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: theme.inputDecorationTheme.border,
        enabledBorder: theme.inputDecorationTheme.enabledBorder,
        focusedBorder: theme.inputDecorationTheme.focusedBorder,
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        labelStyle: theme.inputDecorationTheme.labelStyle,
        contentPadding: contentPadding,
      ),
      style: theme.textTheme.bodyMedium!.copyWith(fontFamily: 'Inter'),
    );
  }
}