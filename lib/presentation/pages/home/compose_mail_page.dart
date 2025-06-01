import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

// Assuming these are defined elsewhere
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/session_manager.dart';

// Updated Attachment class to handle both web and mobile
class Attachment {
  final String originalName;
  final File? file; // For mobile (dart:io File)
  final List<int>? bytes; // For web (file bytes)

  Attachment({
    required this.originalName,
    this.file,
    this.bytes,
  });
}

class ComposeMailPage extends StatefulWidget {
  const ComposeMailPage({Key? key}) : super(key: key);

  @override
  State<ComposeMailPage> createState() => _ComposeMailPageState();
}

class _ComposeMailPageState extends State<ComposeMailPage> {
  final TextEditingController toController = TextEditingController();
  final TextEditingController ccController = TextEditingController();
  final TextEditingController bccController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  final List<String> toRecipients = [];
  final List<String> ccRecipients = [];
  final List<String> bccRecipients = [];
  final List<Attachment> attachments = [];
  final FocusNode toFocusNode = FocusNode();
  final FocusNode ccFocusNode = FocusNode();
  final FocusNode bccFocusNode = FocusNode();

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

  Future<void> _sendMail() async {
    try {
      // Retrieve JWT token from SessionManager
      String? token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found. Please log in again.')),
        );
        return;
      }

      // Prepare recipients
      List<Map<String, String>> recipients = [];
      recipients.addAll(toRecipients.map((email) => {
            "recipientId": email,
            "recipientType": "to",
          }));
      recipients.addAll(ccRecipients.map((email) => {
            "recipientId": email,
            "recipientType": "cc",
          }));
      recipients.addAll(bccRecipients.map((email) => {
            "recipientId": email,
            "recipientType": "bcc",
          }));

      // Validate recipients
      if (recipients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one recipient in To, Cc, or Bcc.')),
        );
        return;
      }

      String recipientsJson = jsonEncode(recipients);

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/email/creatAndSendEmail'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['subject'] = subjectController.text;
      request.fields['body'] = bodyController.text;
      request.fields['recipients'] = recipientsJson;

      // Handle attachments based on platform
      if (attachments.isNotEmpty) {
        if (kIsWeb) {
          // Web platform: Use bytes from Attachment
          for (var attachment in attachments) {
            if (attachment.bytes != null) {
              request.files.add(http.MultipartFile.fromBytes(
                'attachments',
                attachment.bytes!,
                filename: attachment.originalName,
                contentType: MediaType.parse(_getMimeType(attachment.originalName)),
              ));
            } else {
              throw Exception('No bytes found for attachment on web');
            }
          }
        } else {
          // Mobile platform: Use file path
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
            } else {
              throw Exception('No file found for attachment on mobile');
            }
          }
        }
      }

      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email sent successfully with ${attachments.length} attachment(s)'),
          ),
        );
        // Clear fields after successful send
        setState(() {
          toRecipients.clear();
          ccRecipients.clear();
          bccRecipients.clear();
          subjectController.clear();
          bodyController.clear();
          attachments.clear();
        });
      } else {
        // Attempt to parse response body for detailed error (if JSON)
        String errorMessage = 'Failed to send email: $responseBody';
        try {
          final errorJson = jsonDecode(responseBody);
          errorMessage = errorJson['message'] ?? errorMessage;
        } catch (_) {
          // Fallback to raw responseBody if not JSON
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending email: $e'),
        ),
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
          // Web: Store bytes directly
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
          // Mobile: Store File object
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

  void _addRecipient(String email, String field) {
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email format')),
      );
      return;
    }

    setState(() {
      if (email.isNotEmpty) {
        if (field == 'to' && !toRecipients.contains(email)) {
          toRecipients.add(email);
          toController.clear();
        } else if (field == 'cc' && !ccRecipients.contains(email)) {
          ccRecipients.add(email);
          ccController.clear();
        } else if (field == 'bcc' && !bccRecipients.contains(email)) {
          bccRecipients.add(email);
          bccController.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium!.copyWith(fontFamily: 'Inter');
    final contentPadding = const EdgeInsets.symmetric(vertical: 14, horizontal: 16);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Compose email',
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
      body: Padding(
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
    );
  }

  Widget _buildRecipientField(
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    List<String> recipients,
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
                    icon: Icon(Icons.check, color: theme.brightness == Brightness.dark ? Colors.green[300] : Colors.green[700]),
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
              children: recipients.map((email) => Chip(
                label: Text(
                  email,
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
                    recipients.remove(email);
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