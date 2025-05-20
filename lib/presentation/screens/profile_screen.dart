import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:testabc/utils/session_manager.dart';
import 'package:testabc/config/api_config.dart';
import 'dart:convert';
import 'package:testabc/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Map<String, dynamic>? _userData; // Lưu dữ liệu người dùng từ API
  bool _twoFactorEnabled = false;
  bool _notificationEnabled = false;
  double _fontSize = 14; // Giá trị mặc định
  String _fontFamily = 'Roboto'; // Giá trị mặc định

  // Danh sách tùy chọn cho font size và font family
  final List<double> _fontSizeOptions = [12, 14, 16, 18];
  final List<String> _fontFamilyOptions = ['Roboto', 'Inter', 'OpenSans', 'Lato'];

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Gọi API để lấy thông tin người dùng, bao gồm avatar
  }

  // Hàm lấy thông tin người dùng từ API
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Lấy token từ SessionManager
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'No token found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      // Giải mã token để lấy userId
      final decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['sub'];

      // Gọi API lấy thông tin người dùng
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          _userData = userData;
          // Cập nhật các controller và settings với dữ liệu từ API
          _usernameController.text = userData['metadata']['username'] ?? 'Unknown';
          _emailController.text = userData['metadata']['email'] ?? '';
          _phoneController.text = userData['metadata']['phoneNumber'] ?? '';
          _twoFactorEnabled = userData['metadata']['setting']['two_factor_enabled'] ?? false;
          _notificationEnabled = userData['metadata']['setting']['notification_enabled'] ?? false;
          _fontSize = (userData['metadata']['setting']['font_size'] ?? 14).toDouble();
          _fontFamily = userData['metadata']['setting']['font_family'] ?? 'Roboto';
          // Avatar được lấy từ userData['metadata']['avatar'] và sử dụng trong _buildAvatar
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = jsonDecode(response.body)['msg'] ?? 'Failed to fetch user data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final themeProvider = ThemeProvider.of(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? const Color(0xFF2C2C38) : Colors.white,
      body: SafeArea(
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeProvider.isDarkMode
                  ? [const Color(0xFF1F1F2A), const Color(0xFF2C2C38)]
                  : [Colors.blue.shade900, Colors.blue.shade500],
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeader(),
                          SizedBox(height: isSmallScreen ? 20 : 40),
                          _buildProfileCard(isSmallScreen),
                          SizedBox(height: isSmallScreen ? 20 : 40),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
          ),
          const Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isSmallScreen) {
    final size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : size.width * 0.1,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: isSmallScreen ? 20 : 40),
          _buildAvatar(isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 40),
          _buildUserId(isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 40),
          _buildForm(isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 40),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isSmallScreen) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: CircleAvatar(
              radius: isSmallScreen ? 60 : 80,
              backgroundImage: 
                      _userData != null && _userData!['metadata']['avatar'] != null
                      ? NetworkImage(_userData!['metadata']['avatar']) as ImageProvider // Ảnh từ API
                      : AssetImage('assets/default-avatar.png') as ImageProvider, // Ảnh mặc định từ assets
              backgroundColor: Colors.grey[200],
            ),
          ),
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserId(bool isSmallScreen) {
    final themeProvider = ThemeProvider.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF3C3C48) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: themeProvider.isDarkMode ? const Color(0xFF9146FF) : Colors.blue.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.badge_outlined,
            color: Theme.of(context).primaryColor,
            size: isSmallScreen ? 20 : 24,
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Text(
            'ID: ${_userData != null ? _userData!['metadata']['id'] : "N/A"}',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isSmallScreen) {
    final themeProvider = ThemeProvider.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 40,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Email',
              icon: Icons.email_outlined,
              controller: _emailController,
              enabled: false, // Không cho chỉnh sửa
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildTextField(
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              controller: _phoneController,
              enabled: false, // Không cho chỉnh sửa
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildTextField(
              label: 'Username',
              icon: Icons.person_outline,
              controller: _usernameController,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            SwitchListTile(
              title: Text(
                'Two Factor Authentication',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              value: _twoFactorEnabled,
              onChanged: _isEditing
                  ? (value) {
                      setState(() {
                        _twoFactorEnabled = value;
                      });
                    }
                  : null,
              activeColor: Theme.of(context).primaryColor,
            ),
            SwitchListTile(
              title: Text(
                'Notifications',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              value: _notificationEnabled,
              onChanged: _isEditing
                  ? (value) {
                      setState(() {
                        _notificationEnabled = value;
                      });
                    }
                  : null,
              activeColor: Theme.of(context).primaryColor,
            ),
            ListTile(
              title: Text(
                'Font Size',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              trailing: DropdownButton<double>(
                value: _fontSize,
                items: _fontSizeOptions.map((size) {
                  return DropdownMenuItem<double>(
                    value: size,
                    child: Text('$size'),
                  );
                }).toList(),
                onChanged: _isEditing
                    ? (value) {
                        if (value != null) {
                          setState(() {
                            _fontSize = value;
                          });
                        }
                      }
                    : null,
              ),
            ),
            ListTile(
              title: Text(
                'Font Family',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              trailing: DropdownButton<String>(
                value: _fontFamily,
                items: _fontFamilyOptions.map((font) {
                  return DropdownMenuItem<String>(
                    value: font,
                    child: Text(font),
                  );
                }).toList(),
                onChanged: _isEditing
                    ? (value) {
                        if (value != null) {
                          setState(() {
                            _fontFamily = value;
                          });
                        }
                      }
                    : null,
              ),
            ),
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              value: themeProvider.isDarkMode,
              onChanged: _isEditing
                  ? (value) {
                      themeProvider.toggleTheme();
                    }
                  : null,
              activeColor: Theme.of(context).primaryColor,
            ),
            if (_isEditing) ...[
              SizedBox(height: isSmallScreen ? 24 : 32),
              SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 50 : 60,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isEditing = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Profile updated successfully'),
                          backgroundColor: themeProvider.isDarkMode ? const Color(0xFF9146FF) : Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    final themeProvider = ThemeProvider.of(context);
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(
        color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: validator,
    );
  }
}