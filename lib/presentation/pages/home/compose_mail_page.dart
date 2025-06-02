import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/session_manager.dart';

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

  const ComposeMailPage({Key? key, this.emailId}) : super(key: key);

  @override
  State<ComposeMailPage> createState() => _ComposeMailPageState();
}

class _ComposeMailPageState extends State<ComposeMailPage> {
  final TextEditingController toController = TextEditingController();
  final TextEditingController ccController = TextEditingController();
  final TextEditingController bccController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  final List<Map<String, String>> toRecipients = []; // Store {id, email}
  final List<Map<String, String>> ccRecipients = [];
  final List<Map<String, String>> bccRecipients = [];
  final List<Attachment> attachments = [];
  final FocusNode toFocusNode = FocusNode();
  final FocusNode ccFocusNode = FocusNode();
  final FocusNode bccFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.emailId != null) {
      _fetchEmailDetails(widget.emailId!);
    }
  }

  Future<Map<String, String>> _fetchUserById(String userId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        return {'id': userId, 'email': userId}; // Fallback
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
      return {'id': userId, 'email': userId}; // Fallback
    } catch (e) {
      return {'id': userId, 'email': userId}; // Fallback
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
        body: jsonEncode({'email': email})
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

        // Fetch user emails for recipients
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
          bodyController.text = emailData['body'] ?? '';
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
    bodyController.dispose();
    toFocusNode.dispose();
    ccFocusNode.dispose();
    bccFocusNode.dispose();
    super.dispose();
  }

  String _getMimeType(String fileName) {
    return lookupMimeType(fileName) ?? 'application/octet-stream';
  }

  // Check if any fields are filled
  bool _hasContent() {
    return toRecipients.isNotEmpty ||
        ccRecipients.isNotEmpty ||
        bccRecipients.isNotEmpty ||
        subjectController.text.isNotEmpty ||
        bodyController.text.isNotEmpty ||
        attachments.isNotEmpty ||
        toController.text.isNotEmpty ||
        ccController.text.isNotEmpty ||
        bccController.text.isNotEmpty;
  }

  Future<void> _sendMail() async {
    try {
      String? token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found. Please log in again.')),
        );
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
        return;
      }

      String recipientsJson = jsonEncode(recipients);

      if (widget.emailId != null) {
        // Update draft first
        var updateRequest = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/api/email/updateDraft'),
        );

        updateRequest.headers['Authorization'] = 'Bearer $token';
        updateRequest.fields['id'] = widget.emailId!;
        updateRequest.fields['subject'] = subjectController.text;
        updateRequest.fields['body'] = bodyController.text;
        updateRequest.fields['recipients'] = recipientsJson;

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
        request.fields['body'] = bodyController.text;
        request.fields['recipients'] = recipientsJson;

        // Include attachments
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
      if (bodyController.text.isNotEmpty) {
        request.fields['body'] = bodyController.text;
      }
      if (recipients.isNotEmpty) {
        request.fields['recipients'] = recipientsJson;
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

    setState(() {
      final recipient = {'id': email, 'email': email}; // Use email as id for drafts
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
    final textStyle = theme.textTheme.bodyMedium!.copyWith(fontFamily: 'Inter');
    final contentPadding = const EdgeInsets.symmetric(vertical: 14, horizontal: 16);

    return WillPopScope(
      onWillPop: () async {
        if (_hasContent()) {
          await _saveDraft();
        }
        return true; // Allow navigation back
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            widget.emailId != null ? 'Edit Draft' : 'Compose email',
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
              onPressed: _sendMail,
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
                      TextField(
                        controller: bodyController,
                        maxLines: 10,
                        decoration: InputDecoration(
                          labelText: 'Compose email',
                          border: theme.inputDecorationTheme.border,
                          enabledBorder: theme.inputDecorationTheme.enabledBorder,
                          focusedBorder: theme.inputDecorationTheme.focusedBorder,
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor,
                          labelStyle: theme.inputDecorationTheme.labelStyle,
                          contentPadding: contentPadding,
                        ),
                        style: textStyle,
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