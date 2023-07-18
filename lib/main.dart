import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import './http.dart';

final buttonKey = UniqueKey();
final imageKey = UniqueKey();

// coverage:ignore-start
void main() {
  runApp(MyApp(imageFilePicker: ImageFilePicker(), client: http.Client(), platformService: PlatformService(),));
}
// coverage:ignore-end

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.imageFilePicker, required this.client, required this.platformService});

  final ImageFilePicker imageFilePicker;
  final http.Client client;
  final PlatformService platformService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Image Upload Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: MyHomePage(imageFilePicker: imageFilePicker, client: client, platformService: platformService),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.imageFilePicker, required this.client, required this.platformService});

  final ImageFilePicker imageFilePicker;
  final http.Client client;
  final PlatformService platformService;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? imageURL;
  bool isLoading = false;
  bool errored = false;

  /// Called when the image is pressed.
  /// It invokes `openImagePickerDialog`, which opens a dialog to select an image and makes the request to upload the image.
  void _onImagePressed() async {
    setState(() {
      isLoading = true;
    });

    APIResponse? response = await openImagePickerDialog(widget.imageFilePicker, widget.client, widget.platformService);

    if (response == null) {
      setState(() {
        errored = false;
        isLoading = false;
      });
    } else if (response.code != 200) {
      setState(() {
        errored = true;
        imageURL = null;
        isLoading = false;
      });
    } else {
      setState(() {
        errored = false;
        imageURL = response.url;
        isLoading = false;
      });
    }
  }

  /// Renders the contents of the image.
  /// If there's an error, a Text is shown telling the person something went wrong.
  /// If no image is found, we show a simple Text.
  List<Widget> renderImage() {
    // If it's loading, show a loading circular indicator
    if (isLoading) {
      // coverage:ignore-start
      return [const CircularProgressIndicator()];
      // coverage:ignore-end
    }

    // Check if it's not errored nor an image exists, meaning the person has yet to upload an image
    else if (!errored && imageURL == null) {
      return [const Text("No image has been uploaded.", textAlign: TextAlign.center)];
    }

    // If it errored, we show an error text
    else if (errored) {
      return [
        const Text(
          "There was an error uploading the image. Check if the API is up.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red),
        )
      ];
    }

    // If everything is successful, show the image
    else {
      return [
        const Padding(
            padding: EdgeInsets.only(bottom: 8.0, right: 8.0, left: 8.0),
            child: Column(children: [
              Text(
                "Here's your uploaded image!",
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              Text(
                "It's living on the web. Click on the picture to open in the browser.",
                textAlign: TextAlign.center,
              ),
            ])),
        GestureDetector(
          onTap: () async {
            final Uri url = Uri.parse(imageURL!);
            await launchUrl(url);
          },
          child: Image.network(
            key: imageKey,
            imageURL!,
            fit: BoxFit.fill,
            loadingBuilder: (BuildContext context, child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                ),
              );
            },
          ),
        )
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Flutter Image Upload Demo"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Elevated button to open file picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  child: ElevatedButton(
                    key: buttonKey,
                    onPressed: _onImagePressed,
                    child: const Text("Upload image"),
                  ),
                ),
              ],
            ),

            // Render image
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: renderImage(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
