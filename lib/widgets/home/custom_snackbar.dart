import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    Color backgroundColor = const Color.fromARGB(255, 204, 204, 233), // Màu trắng ánh đen (xám nhạt)
    Color borderColor = const Color.fromARGB(255, 105, 8, 250), // Viền màu tím
    Duration duration = const Duration(seconds: 3),
  }) {
    showDialog(
      context: context,
      barrierDismissible: true, // Cho phép đóng bằng cách nhấn bên ngoài
      builder: (BuildContext context) {
        Future.delayed(duration, () {
          Navigator.of(context).pop(); // Đóng dialog sau thời gian duration
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 2), // Viền tím
          ),
          backgroundColor: backgroundColor.withOpacity(0.9), // Ánh đen với độ trong suốt
          child: Padding(
            padding: const EdgeInsets.all(24.0), // Tăng padding để mở rộng vùng text
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 300, // Giới hạn tối đa chiều rộng để text không quá rộng
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true, // Cho phép text xuống dòng tự động
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}