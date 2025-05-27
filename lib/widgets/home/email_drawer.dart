import 'package:flutter/material.dart';

class EmailDrawer extends StatelessWidget {
  final Function(int) onItemSelected;

  const EmailDrawer({super.key, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 50,
            child: DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', fit: BoxFit.contain),
                  const SizedBox(width: 10),
                  Text(
                    'Flutter Gmail',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.circle, color: Colors.green, size: 14),
            title: Text("Đang hoạt động", style: Theme.of(context).textTheme.bodyMedium),
            // onTap: () {
            //   onItemSelected(0); // Inbox
            //   Navigator.pop(context);
            // },
          ),
          ListTile(
            leading: Icon(Icons.inbox, color: Theme.of(context).iconTheme.color),
            title: Text("Inbox", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0); // Inbox
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.send, color: Theme.of(context).iconTheme.color),
            title: Text("Sent", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(1); // Sent
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.insert_drive_file, color: Theme.of(context).iconTheme.color),
            title: Text("Draft", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(4); // Draft
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.mark_as_unread_outlined, color: Theme.of(context).iconTheme.color),
            title: Text("Tất cả thư", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(5); // All
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.star_border, color: Theme.of(context).iconTheme.color),
            title: Text("Starred", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(3); // Starred
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).iconTheme.color),
            title: Text("Trash", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(2); // Trash
              Navigator.pop(context);
            },
          ),
           ListTile(
            leading: Icon(Icons.edit, size: 14, color: Theme.of(context).iconTheme.color),
            title: Text("Add label", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0); // Default to inbox (or handle differently if needed)
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}