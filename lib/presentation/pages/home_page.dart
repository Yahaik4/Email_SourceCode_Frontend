import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _selectedDrawerIndex = 0;

  final List<Map<String, String>> emails = [
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
    {
      "sender": "Hệ thống mail - Môn kỹ năng",
      "title": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "subject": "THÔNG BÁO THỜI GIAN HỌC ONLINE",
      "time": "12:14"
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildEmailList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Hộp thư đến",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: emails.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        emails[index]["sender"]![0],
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  emails[index]["sender"]!,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                emails[index]["time"]!,
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          Text(
                            emails[index]["title"]!,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  emails[index]["subject"]!,
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                              Icon(Icons.star_border, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  final List<String> _pages = ["Hộp thư đến", "Đã gửi", "Cài đặt"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 10),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, color: Colors.black),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Tìm trong thư",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Text('N', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 50,
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://ssl.gstatic.com/ui/v1/icons/mail/rfr/gmail.ico',
                      width: 30,
                      height: 30,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Gmail',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.circle,
                color: Colors.green,
                size: 14,
              ),
              title: Text("Đang hoạt động"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.edit,
                color: Colors.black,
                size: 14,
              ),
              title: Text("Thêm trạng thái"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.all_inbox),
              title: Text("Tất cả hộp thư đến"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.inbox),
              title: Text("Hộp thư đến"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.star_border),
              title: Text("Có gắn dấu sao"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.access_time),
              title: Text("Đã ẩn"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.double_arrow),
              title: Text("Quan trọng"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.send),
              title: Text("Đã gửi"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule_send),
              title: Text("Đã lên lịch"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.forward_to_inbox),
              title: Text("Hộp thư đi"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file),
              title: Text("Thư nháp"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.mark_as_unread_outlined),
              title: Text("Tất cả thư"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.error_outline),
              title: Text("Thư rác"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text("Thùng rác"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _selectedIndex == 0
          ? _buildEmailList()
          : Center(
              child: Text(
                _pages[_selectedIndex],
                style: TextStyle(fontSize: 18),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.email), label: "Mail"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: "Meet"),
        ],
      ),
    );
  }
}