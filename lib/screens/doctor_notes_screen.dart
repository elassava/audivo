import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class NotesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notes')),
      body: Center(
        child: Text('Manage your notes here'),
      ),
    );
  }
}
