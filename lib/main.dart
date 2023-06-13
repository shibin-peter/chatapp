import 'package:flutter/material.dart';

import 'home.dart';

void main(){
  runApp(chat());
}
class chat extends StatelessWidget {
  const chat({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat app',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Home(),
    );
  }
}
