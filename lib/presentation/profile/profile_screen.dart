import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:testabc/utils/session_manager.dart';
import 'package:testabc/config/api_config.dart';
import 'dart:convert';
import 'package:testabc/main.dart';
import 'package:flutter/foundation.dart';

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
  Uint8List? _imageBytes;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Map<String, dynamic>? _userData;
  bool _twoFactorEnabled = false;
  bool _notificationEnabled = false;
  double _fontSize = 14;
  String _fontFamily = 'Roboto';
  bool _tempDarkMode = false;

  final List<double> _fontSizeOptions = [12, 14, 16, 18];
  final List<String> _fontFamilyOptions = ['Roboto', 'Inter', 'OpenSans', 'Lato'];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'No token found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/${JwtDecoder.decode(token)['sub']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final themeProvider = ThemeProvider.of(context);
        setState(() {
          _userData = userData;
          _usernameController.text = userData['metadata']['username'] ?? 'Unknown';
          _emailController.text = userData['metadata']['email'] ?? '';
          _phoneController.text = userData['metadata']['phoneNumber'] ?? '';
          _twoFactorEnabled = userData['metadata']['setting']['two_factor_enabled'] ?? false;
          _notificationEnabled = userData['metadata']['setting']['notification_enabled'] ?? false;
          _fontSize = (userData['metadata']['setting']['font_size'] ?? 14).toDouble();
          _fontFamily = userData['metadata']['setting']['font_family'] ?? 'Roboto';
          _tempDarkMode = userData['metadata']['setting']['theme'] == 'Dark';
          if (userData['metadata']['setting']['theme'] == 'Dark') {
            if (!themeProvider.isDarkMode) themeProvider.toggleTheme();
          } else {
            if (themeProvider.isDarkMode) themeProvider.toggleTheme();
          }
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'No token found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final themeProvider = ThemeProvider.of(context);
      final settings = {
        'two_factor_enabled': _twoFactorEnabled,
        'notification_enabled': _notificationEnabled,
        'font_size': _fontSize,
        'font_family': _fontFamily,
        'theme': _tempDarkMode ? 'Dark' : 'White',
      };

      final profileRequest = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/users/update-profile'),
      );

      profileRequest.headers['Authorization'] = 'Bearer $token';
      profileRequest.fields['username'] = _usernameController.text;
      profileRequest.fields['setting'] = jsonEncode(settings);

      if (kIsWeb) {
        if (_imageBytes != null) {
          profileRequest.files.add(
            http.MultipartFile.fromBytes(
              'avatar',
              _imageBytes!,
              filename: 'avatar.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      } else {
        if (_image != null) {
          final imageBytes = await _image!.readAsBytes();
          final fileName = _image!.path.split('/').last;

          profileRequest.files.add(
            http.MultipartFile.fromBytes(
              'avatar',
              imageBytes,
              filename: fileName,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }

      final profileResponse = await profileRequest.send().timeout(const Duration(seconds: 10));
      final profileResponseBody = await profileResponse.stream.bytesToString();

      if (profileResponse.statusCode == 200) {
        if (_tempDarkMode != themeProvider.isDarkMode) {
          themeProvider.toggleTheme();
        }
        setState(() {
          _isLoading = false;
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
        await _fetchUserData();
      } else {
        setState(() {
          _errorMessage = jsonDecode(profileResponseBody)['msg'] ?? 'Failed to update profile';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ThemeProvider.of(context).isDarkMode
                  ? const Color(0xFF3C3C48)
                  : Colors.grey[300],
              title: Text(
                'Change Password',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter new password',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).iconTheme.color ?? Colors.grey,
                        ),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Confirm new password',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).iconTheme.color ?? Colors.grey,
                        ),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
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
                  onPressed: () async {
                    if (newPasswordController.text.isEmpty) {
                      setDialogState(() {
                        errorMessage = 'Please enter a new password';
                      });
                      return;
                    }
                    if (newPasswordController.text.length < 6) {
                      setDialogState(() {
                        errorMessage = 'Password must be at least 6 characters';
                      });
                      return;
                    }
                    if (newPasswordController.text != confirmPasswordController.text) {
                      setDialogState(() {
                        errorMessage = 'Passwords do not match';
                      });
                      return;
                    }

                    // Call API to update password
                    try {
                      final token = await SessionManager.getToken();
                      if (token == null) {
                        setDialogState(() {
                          errorMessage = 'No token found. Please login again.';
                        });
                        return;
                      }

                      final userId = JwtDecoder.decode(token)['sub'];
                      final response = await http.put(
                        Uri.parse('${ApiConfig.baseUrl}/api/auth/$userId/password'),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({'password': newPasswordController.text}),
                      ).timeout(const Duration(seconds: 10));

                      if (response.statusCode == 200) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Password updated successfully'),
                            backgroundColor: ThemeProvider.of(context).isDarkMode
                                ? const Color(0xFF9146FF)
                                : Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      } else {
                        setDialogState(() {
                          errorMessage = jsonDecode(response.body)['msg'] ?? 'Failed to update password';
                        });
                      }
                    } catch (e) {
                      setDialogState(() {
                        errorMessage = 'Error: $e';
                      });
                    }
                  },
                  child: Text(
                    'Save',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _image = null;
        });
      } else {
        setState(() {
          _image = File(pickedFile.path);
          _imageBytes = null;
        });
      }
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
                  : [Colors.grey.shade100, Colors.grey.shade300],
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
              if (_isEditing) {
                if (_formKey.currentState!.validate()) {
                  _updateProfile();
                }
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
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
              backgroundImage: _image != null
                  ? FileImage(_image!)
                  : _imageBytes != null
                      ? MemoryImage(_imageBytes!)
                      : _userData != null && _userData!['metadata']['avatar'] != null
                          ? NetworkImage(_userData!['metadata']['avatar']) as ImageProvider
                          : const AssetImage('assets/default-avatar.png') as ImageProvider,
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
              enabled: false,
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildTextField(
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              controller: _phoneController,
              enabled: false,
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
            _buildPasswordField(isSmallScreen),
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
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                dropdownColor: themeProvider.isDarkMode ? const Color(0xFF2C2C38) : Colors.white,
                items: _fontSizeOptions.map((size) {
                  return DropdownMenuItem<double>(
                    value: size,
                    child: Text(
                      '$size',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
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
            // ListTile(
            //   title: Text(
            //     'Font Family',
            //     style: TextStyle(
            //       color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
            //     ),
            //   ),
            //   trailing: DropdownButton<String>(
            //     value: _fontFamily,
            //     style: TextStyle(
            //       color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
            //     ),
            //     dropdownColor: themeProvider.isDarkMode ? const Color(0xFF2C2C38) : Colors.white,
            //     items: _fontFamilyOptions.map((font) {
            //       return DropdownMenuItem<String>(
            //         value: font,
            //         child: Text(
            //           font,
            //           style: TextStyle(
            //             color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
            //           ),
            //         ),
            //       );
            //     }).toList(),
            //     onChanged: _isEditing
            //         ? (value) {
            //             if (value != null) {
            //               setState(() {
            //                 _fontFamily = value;
            //               });
            //             }
            //           }
            //         : null,
            //   ),
            // ),
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              value: _tempDarkMode,
              onChanged: _isEditing
                  ? (value) {
                      setState(() {
                        _tempDarkMode = value;
                      });
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
                      _updateProfile();
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
              SizedBox(height: isSmallScreen ? 12 : 16),
              SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 50 : 60,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _fetchUserData();
                    });
                  },
                  child: const Text(
                    'CANCEL',
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

  Widget _buildPasswordField(bool isSmallScreen) {
    final themeProvider = ThemeProvider.of(context);
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextFormField(
          enabled: false,
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
          ),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: '************',
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(
              Icons.edit,
              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
            ),
            onPressed: _showChangePasswordDialog,
            splashRadius: 20,
          ),
        ),
      ],
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
        prefixIcon: Icon(icon, color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: validator,
    );
  }
}