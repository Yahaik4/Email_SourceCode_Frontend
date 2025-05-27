import 'package:flutter/material.dart';

class ComposeMailFab extends StatelessWidget {
  final VoidCallback? onPressed;
  const ComposeMailFab({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: 'Soạn mail',
      child: const Icon(Icons.edit),
    );
  }
} 