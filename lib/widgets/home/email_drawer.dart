import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/main.dart';
import 'package:testabc/utils/session_manager.dart';

class EmailDrawer extends StatelessWidget {
  final Function(int) onItemSelected;
  final Function(String) onLabelSelected;
  final Function(String) onLabelCreated; 
  final Function(String) onLabelDeleted;
  final List<String> labels;

  const EmailDrawer({
    super.key,
    required this.onItemSelected,
    required this.onLabelSelected,
    required this.onLabelCreated,
    required this.onLabelDeleted,
    required this.labels,
  });

  // Function to show the Add Label popup
  void _showAddLabelDialog(BuildContext context) {
    final TextEditingController labelController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeProvider.of(context).isDarkMode
              ? const Color(0xFF3C3C48)
              : Colors.grey[300],
          title: Text(
            'Add New Label',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
          ),
          content: TextField(
            controller: labelController,
            decoration: InputDecoration(
              hintText: 'Enter label name',
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).iconTheme.color ?? Colors.grey,
                ),
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (labelController.text.isNotEmpty) {
                  onLabelCreated(labelController.text); // Call new label creation callback
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Add',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to show the Delete Label confirmation popup
  void _showDeleteLabelDialog(BuildContext context, String labelName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeProvider.of(context).isDarkMode
              ? const Color(0xFF3C3C48)
              : Colors.grey[300],
          title: Text(
            'Delete Label',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
          ),
          content: Text(
            'Are you sure you want to delete the label "$labelName"?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ),
            TextButton(
              onPressed: () {
                onLabelDeleted(labelName); // Call label deletion callback
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Delete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red, // Red color for delete action
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

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
          Divider(
            height: 32,
            thickness: 2,
            color: ThemeProvider.of(context).isDarkMode
                ? const Color(0xFF3C3C48)
                : Colors.grey[300],
          ),
          ListTile(
            leading: Icon(Icons.add_outlined, size: 14, color: Theme.of(context).iconTheme.color),
            title: Text("Add label", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              _showAddLabelDialog(context);
            },
          ),
          ...labels.map((label) => ListTile(
                leading: Icon(Icons.label_outline, color: Theme.of(context).iconTheme.color),
                title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).iconTheme.color,
                    size: 20,
                  ),
                  onPressed: () {
                    _showDeleteLabelDialog(context, label); // Show delete confirmation
                  },
                ),
                onTap: () {
                  onLabelSelected(label);
                  Navigator.pop(context);
                },
              )).toList(),
        ],
      ),
    );
  }
}