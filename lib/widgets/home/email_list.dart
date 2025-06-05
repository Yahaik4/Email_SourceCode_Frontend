import 'package:flutter/material.dart';
import 'package:testabc/widgets/home/email_item.dart';

class EmailList extends StatelessWidget {
  final List<Map<String, String>> emails;
  final VoidCallback? onEmailUpdated;
  final String? currentLabel;

  const EmailList({super.key, required this.emails, this.onEmailUpdated, this.currentLabel});

  @override
  Widget build(BuildContext context) {
    if (emails.isEmpty) {
      return Center(
        child: Text(
          "There's no email in this folder",
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
            "Email list:",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: emails.length,
            itemBuilder: (context, index) {
              return EmailItem(
                key: ValueKey(emails[index]['subject']),
                email: emails[index],
                currentLabel: currentLabel,
                onEmailUpdated: onEmailUpdated,
              );
            },
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey.withOpacity(0.3),
              height: 1,
              thickness: 1,
            ),
          ),
        ),
      ],
    );
  }
}