import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

// coverage:ignore-start
void main() {
  runApp(const MyApp());
}
// coverage:ignore-end

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Image Upload Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Image Upload Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _onImagePressed() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    
    if (result != null) {
      // Get file and make request
      PlatformFile platformFile = result.files.first;
      File file = File(result.files.first.path!);

      // Create multipart/form data request from file
      final uri = Uri.parse('http://localhost:4000/api/images');

      MultipartRequest request = http.MultipartRequest('POST', uri);
      final bytes = await file.readAsBytes();
      final httpImage =
          http.MultipartFile.fromBytes('image', bytes, contentType: MediaType.parse(lookupMimeType(file.path)!), filename: platformFile.name);
      request.files.add(httpImage);

      // Send request
      final response = await request.send();

      // Get response of request
      Response responseStream = await http.Response.fromStream(response);
      final responseData = json.decode(responseStream.body);
      
      final bruh = "";
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Elevated button to open file picker
            ElevatedButton(
              onPressed: _onImagePressed,
              child: const Text("Upload image"),
            )
          ],
        ),
      ),
    );
  }
}
