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
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit, size: 14, color: Theme.of(context).iconTheme.color),
            title: Text("Thêm trạng thái", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.all_inbox, color: Theme.of(context).iconTheme.color),
            title: Text("Tất cả hộp thư đến", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.inbox, color: Theme.of(context).iconTheme.color),
            title: Text("Hộp thư đến", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.star_border, color: Theme.of(context).iconTheme.color),
            title: Text("Có gắn dấu sao", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.access_time, color: Theme.of(context).iconTheme.color),
            title: Text("Đã ẩn", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.double_arrow, color: Theme.of(context).iconTheme.color),
            title: Text("Quan trọng", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.send, color: Theme.of(context).iconTheme.color),
            title: Text("Đã gửi", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.schedule_send, color: Theme.of(context).iconTheme.color),
            title: Text("Đã lên lịch", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.forward_to_inbox, color: Theme.of(context).iconTheme.color),
            title: Text("Hộp thư đi", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.insert_drive_file, color: Theme.of(context).iconTheme.color),
            title: Text("Thư nháp", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.mark_as_unread_outlined, color: Theme.of(context).iconTheme.color),
            title: Text("Tất cả thư", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.error_outline, color: Theme.of(context).iconTheme.color),
            title: Text("Thư rác", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).iconTheme.color),
            title: Text("Thùng rác", style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              onItemSelected(0);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}