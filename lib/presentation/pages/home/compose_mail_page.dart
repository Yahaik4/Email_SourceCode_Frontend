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
        title: Text('Soạn email', style: TextStyle(color: iconColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.attach_file, color: iconColor),
            onPressed: _attachFile,
            tooltip: 'Đính kèm',
          ),
          IconButton(
            icon: Icon(Icons.send, color: iconColor),
            onPressed: _sendMail,
            tooltip: 'Gửi',
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
              _buildTextField('Đến', toController),
              const SizedBox(height: 8),
              _buildTextField('Cc', ccController),
              const SizedBox(height: 8),
              _buildTextField('Bcc', bccController),
              const SizedBox(height: 8),
              _buildTextField('Tiêu đề', subjectController),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Soạn email',
                  border: OutlineInputBorder(),
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
        border: const OutlineInputBorder(),
      ),
    );
  }
} 