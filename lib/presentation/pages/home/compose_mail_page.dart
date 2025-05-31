import 'package:flutter/material.dart';

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

  void _sendMail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email sent (demo)')),
    );
  }

  void _attachFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attachment feature (demo)')),
    );
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
    final isDark = theme.brightness == Brightness.dark;
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
                  side: BorderSide(
                    color: theme.primaryColor, // Sử dụng màu tím (hoặc màu chính của theme)
                  ),
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