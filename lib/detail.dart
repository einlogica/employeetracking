import 'package:flutter/material.dart';

class Details extends StatefulWidget {
  final String data;
  const Details({super.key, required this.data});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  @override

  Widget build(BuildContext context) {
  
    return Scaffold(
      appBar: AppBar(title: Text("Location Details")), 
      body: Center(child: Text(widget.data)),
    );
  }
}
