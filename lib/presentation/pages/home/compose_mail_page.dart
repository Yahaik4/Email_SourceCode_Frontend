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
    // TODO: Implement send mail logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email sent (demo)')),
    );
  }

  void _attachFile() {
    // TODO: Implement attach file logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attachment feature (demo)')),
    );
  }

  // Mock function to get email suggestions
  List<String> _getEmailSuggestions(String query) {
    // TODO: Replace with actual API call
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
    final iconColor = isDark ? Colors.white : Colors.black87;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.close, color: iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Compose', style: TextStyle(color: iconColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.attach_file, color: iconColor),
            onPressed: _attachFile,
            tooltip: 'Attach',
          ),
          IconButton(
            icon: Icon(Icons.send, color: iconColor),
            onPressed: _sendMail,
            tooltip: 'Send',
          ),
        ],
        iconTheme: IconThemeData(color: iconColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecipientField(),
              const SizedBox(height: 8),
              _buildTextField('Cc', ccController),
              const SizedBox(height: 8),
              _buildTextField('Bcc', bccController),
              const SizedBox(height: 8),
              _buildTextField('Subject', subjectController),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                maxLines: 10,
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontFamily: 'Inter'),
                decoration: InputDecoration(
                  labelText: 'Compose email',
                  labelStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey.shade600, fontFamily: 'Inter'),
                  hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey.shade600, fontFamily: 'Inter'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF9146FF), width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A2E) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
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
    final fillColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
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

  Widget _buildTextField(String label, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final focusColor = const Color(0xFF9146FF);
    final fillColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor, fontFamily: 'Inter'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontFamily: 'Inter'),
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
    );
  }
} 