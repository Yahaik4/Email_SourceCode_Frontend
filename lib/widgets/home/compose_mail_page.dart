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

  @override
  void dispose() {
    toController.dispose();
    ccController.dispose();
    bccController.dispose();
    subjectController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  void _sendMail() {
    // TODO: Implement send mail logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi email (demo)')),
    );
  }

  void _attachFile() {
    // TODO: Implement attach file logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đính kèm (demo)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Đồng bộ với theme
        foregroundColor: Theme.of(context).iconTheme.color, // Màu icon và tiêu đề
        title: Text(
          'Compose email',
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
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
              _buildTextField('To', toController),
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
                decoration: InputDecoration(
                  labelText: 'Body',
                  // Sử dụng inputDecorationTheme từ theme
                  border: Theme.of(context).inputDecorationTheme.border,
                  enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                  filled: Theme.of(context).inputDecorationTheme.filled,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  labelStyle: Theme.of(context).inputDecorationTheme.labelStyle,
                  prefixIconColor: Theme.of(context).inputDecorationTheme.prefixIconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        // Sử dụng inputDecorationTheme từ theme
        border: Theme.of(context).inputDecorationTheme.border,
        enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
        filled: Theme.of(context).inputDecorationTheme.filled,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        labelStyle: Theme.of(context).inputDecorationTheme.labelStyle,
        prefixIconColor: Theme.of(context).inputDecorationTheme.prefixIconColor,
      ),
    );
  }
}