import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:testabc/main.dart';
import 'attachment_item.dart';

class EmailContent extends StatelessWidget {
  final Map<String, dynamic> email;
  final Function(BuildContext, Map<String, dynamic>) onDownload;

  const EmailContent({
    Key? key,
    required this.email,
    required this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    // Phân tích body thành Quill Delta
    quill.Document document;
    try {
      final deltaJson = jsonDecode(email['body']);
      document = quill.Document.fromJson(deltaJson);
    } catch (e) {
      // Nếu body không phải JSON, hiển thị dưới dạng văn bản thuần
      document = quill.Document()..insert(0, email['body']?.toString() ?? '');
    }

    // Tạo QuillController
    final quillController = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Tạo FocusNode
    final focusNode = FocusNode();

    // Phân tích attachments
    List<Map<String, dynamic>> attachments = [];
    if (email['attachments'] != null && email['attachments'].toString().isNotEmpty) {
      try {
        attachments = (jsonDecode(email['attachments'].toString()) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      } catch (e) {
        print('Error parsing attachments: $e');
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị nội dung email bằng QuillEditor
            Container(
              decoration: BoxDecoration(
                color: (isDarkMode ? const Color(0xFF2C2C38) : Colors.white),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8.0),
              child: quill.QuillEditor(
                focusNode: focusNode,
                configurations: quill.QuillEditorConfigurations(
                  controller: quillController,
                  enableInteractiveSelection: false,
                  scrollable: false,
                  autoFocus: false,
                  expands: false,
                  padding: const EdgeInsets.all(8.0),
                  customStyles: quill.DefaultStyles(
                    paragraph: quill.DefaultTextBlockStyle(
                      TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.0,
                        height: 1.5,
                        color: theme.textTheme.bodyMedium!.color,
                      ),
                      const quill.HorizontalSpacing(0, 0),
                      const quill.VerticalSpacing(4, 4),
                      const quill.VerticalSpacing(0, 0),
                      null,
                    ),
                  ),
                ),
                scrollController: ScrollController(),
              ),
            ),
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Attachments:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(height: 12),
              ...attachments.map((attachment) => AttachmentItem(
                    attachment: attachment,
                    isDarkMode: isDarkMode,
                    theme: theme,
                    onDownload: () => onDownload(context, attachment),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}