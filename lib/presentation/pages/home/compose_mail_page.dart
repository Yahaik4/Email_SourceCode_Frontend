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
  final List<String> selectedRecipients = [];
  final FocusNode toFocusNode = FocusNode();

  @override
  void dispose() {
    toController.dispose();
    ccController.dispose();
    bccController.dispose();
    subjectController.dispose();
    bodyController.dispose();
    toFocusNode.dispose();
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

  List<String> _getEmailSuggestions(String query) {
    final mockEmails = [
      'john.doe@gmail.com',
      'jane.smith@yahoo.com',
      'alice.wonderland@company.com',
      'bob.builder@outlook.com',
      'charlie.brown@mail.com',
      'david.jones@company.com',
      'eve.adams@company.com',
      'frank.miller@company.com',
      'grace.hopper@company.com',
      'henry.ford@company.com',
    ];
    return mockEmails.where((email) =>
      email.toLowerCase().contains(query.toLowerCase()) ||
      email.split('@')[0].toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF23232B) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final focusColor = const Color(0xFF9146FF);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: focusColor, width: 2),
    );
    final labelStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.grey.shade700,
      fontFamily: 'Inter',
    );
    final textStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black87,
      fontFamily: 'Inter',
    );
    final contentPadding = const EdgeInsets.symmetric(vertical: 14, horizontal: 16);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        title: Text(
          'Compose email',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
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
              _buildRecipientField(),
              const SizedBox(height: 8),
              _buildTextField('Cc', ccController, fillColor, border, focusedBorder, labelStyle, textStyle, contentPadding),
              const SizedBox(height: 8),
              _buildTextField('Bcc', bccController, fillColor, border, focusedBorder, labelStyle, textStyle, contentPadding),
              const SizedBox(height: 8),
              _buildTextField('Subject', subjectController, fillColor, border, focusedBorder, labelStyle, textStyle, contentPadding),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: 'Compose email',
                  border: border,
                  enabledBorder: border,
                  focusedBorder: focusedBorder,
                  filled: true,
                  fillColor: isDark ? Color(0xFF23232B) : Colors.white,
                  labelStyle: labelStyle,
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

  Widget _buildRecipientField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final focusColor = const Color(0xFF9146FF);
    final fillColor = isDark ? const Color(0xFF23232B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    double inputWidth = 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('To', style: TextStyle(fontSize: 16, color: labelColor, fontFamily: 'Inter')),
        const SizedBox(height: 8),
        SizedBox(
          width: inputWidth,
          child: TextField(
            controller: toController,
            focusNode: toFocusNode,
            style: TextStyle(color: textColor, fontFamily: 'Inter'),
            cursorColor: textColor,
            decoration: InputDecoration(
              labelText: 'To',
              labelStyle: TextStyle(color: labelColor, fontFamily: 'Inter'),
              hintText: 'Enter recipient email',
              hintStyle: TextStyle(color: labelColor, fontFamily: 'Inter'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: focusColor, width: 2),
              ),
              filled: true,
              fillColor: fillColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        if (selectedRecipients.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 2, bottom: 2),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedRecipients.map((email) => Chip(
                label: Text(email, style: TextStyle(color: textColor, fontFamily: 'Inter')),
                backgroundColor: fillColor,
                deleteIcon: Icon(Icons.close, size: 18, color: textColor),
                onDeleted: () {
                  setState(() {
                    selectedRecipients.remove(email);
                  });
                },
              )).toList(),
            ),
          ),
        if (toController.text.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: inputWidth,
              margin: const EdgeInsets.only(top: 4, left: 2),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _getEmailSuggestions(toController.text).map((email) => ListTile(
                  dense: true,
                  minVerticalPadding: 0,
                  isThreeLine: false,
                  title: Text(
                    email,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontFamily: 'Inter',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green, size: 20),
                        tooltip: 'Add',
                        onPressed: () {
                          setState(() {
                            if (!selectedRecipients.contains(email)) {
                              selectedRecipients.add(email);
                            }
                            toController.clear();
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 20),
                        tooltip: 'Dismiss',
                        onPressed: () {
                          setState(() {
                            toController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Color? fillColor,
    OutlineInputBorder border,
    OutlineInputBorder focusedBorder,
    TextStyle labelStyle,
    TextStyle textStyle,
    EdgeInsets contentPadding,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
        filled: true,
        fillColor: fillColor,
        labelStyle: labelStyle,
        contentPadding: contentPadding,
      ),
      style: textStyle,
    );
  }
}
