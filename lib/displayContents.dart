import 'package:flutter/material.dart';

class DisplayScreen extends StatefulWidget {
  DisplayScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _DisplayState createState() => _DisplayState();
}

class _DisplayState extends State<DisplayScreen>{
  @override
  Widget build(BuildContext context) {
    String? _content = widget.title;
    return Scaffold(
      appBar: AppBar(
      ),
      body: Center(
        child: Text(
          _content,
          style: const TextStyle(
            fontSize: 20
          ),
        )
      )
    );
  }
  
}