import 'package:flutter/material.dart';
import 'package:testabc/widgets/email_item.dart';

class EmailList extends StatelessWidget {
  final List<Map<String, String>> emails;

  const EmailList({super.key, required this.emails});

  @override
  Widget build(BuildContext context) {
    if (emails.isEmpty) {
      return Center(
        child: Text(
          "Không có email nào",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Hộp thư đến",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: emails.length,
            itemBuilder: (context, index) {
              return EmailItem(
                key: ValueKey(emails[index]["title"]),
                email: emails[index],
              );
            },
          ),
        ),
      ],
    );
  }
}