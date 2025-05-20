class Email {
  final String id;
  final String senderName;
  final String senderEmail;
  final String subject;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final List<String> attachments;

  Email({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    required this.subject,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.attachments = const [],
  });
}