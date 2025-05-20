import 'package:flutter/material.dart';
import 'package:testabc/widgets/custom_app_bar.dart';
import 'package:testabc/widgets/email_drawer.dart';
import 'package:testabc/widgets/email_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Map<String, String>> emails = List.generate(
    15,
    (index) => {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14",
    },
  );

  final List<String> _pages = ["Hộp thư đến", "Đã gửi", "Cài đặt"];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(),
      drawer: EmailDrawer(
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: _selectedIndex == 0
          ? EmailList(emails: emails)
          : Center(
              child: Text(
                _pages[_selectedIndex],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.email), label: "Mail"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: "Meet"),
        ],
      ),
    );
  }
}