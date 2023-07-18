<div align="center">

# `Flutter` image upload demo

A showcase of how to upload images to an API
from a `Flutter` client.


![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/dwyl/flutter-image-upload-demo/ci.yml?label=build&style=flat-square&branch=main)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/flutter-image-upload-demo/master.svg?style=flat-square)](https://codecov.io/github/dwyl/flutter-image-upload-demo?branch=master)
[![HitCount](https://hits.dwyl.com/dwyl/flutter-image-upload-demo.svg?style=flat-square&show=unique)](https://hits.dwyl.com/dwyl/flutter-image-upload-demo)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat-square)](https://github.com/dwyl/flutter-image-upload-demo/issues)


</div>
<br />

- [`Flutter` image upload demo](#flutter-image-upload-demo)
- [Why? 🤷‍](#why-)
- [What? 💭](#what-)
- [Who? 👤](#who-)
- [_How_? 👩‍💻](#how-)
  - [Prerequisites? 📝](#prerequisites-)
  - [0. Project setup](#0-project-setup)
  - [1. Adding basic picker and multipart request](#1-adding-basic-picker-and-multipart-request)
    - [1.1 Explaining `openImagePickerDialog`'s behaviour](#11-explaining-openimagepickerdialogs-behaviour)
  - [2. Changing `MyHomePage` so it receives mockable dependencies](#2-changing-myhomepage-so-it-receives-mockable-dependencies)
  - [3. Changing the `MyHomePage` widget view.](#3-changing-the-myhomepage-widget-view)
  - [4. Testing our app](#4-testing-our-app)
  - [5. Adding `Flutter Web` support](#5-adding-flutter-web-support)
    - [5.1 Fixing tests](#51-fixing-tests)
  - [6. (Optional) Click on image to open the URL in the browser](#6-optional-click-on-image-to-open-the-url-in-the-browser)
  - [6.1 Changing tests](#61-changing-tests)
  - [7. (Optional) Adding progress circle while requesting API](#7-optional-adding-progress-circle-while-requesting-api)
  - [8. (Optional) Showing error text in case API fails](#8-optional-showing-error-text-in-case-api-fails)


# Why? 🤷‍

After creating a quick SPIKE to upload files to a `Phoenix` server
in https://github.com/dwyl/imgup,
the next logical step was implementing this feature
to call the API from a third-party client, like `Flutter`.
So here we are!

# What? 💭

`Phoenix` makes uploading files through API
quite straightforward.

This repo demos an interaction between a `Flutter` app
and a `Phoenix` API that stores images.


# Who? 👤

This quick demo is aimed at people in the @dwyl team
or anyone who is interested in learning 
how to use a `Phoenix` API to upload images
from a `Flutter` client app.

# _How_? 👩‍💻

## Prerequisites? 📝

This demo assumes you have foundational knowledge of `Flutter`.
If this is your first time tinkering with `Flutter`,
we suggest you first take a look at 
https://github.com/dwyl/learn-flutter.

In this repo you will learn 
how to install the needed dependencies
and how to debug your app on both an emulator
or a physical device.

We are going to make API requests
to https://imgup.fly.dev/.
However, you are free to clone the API source files
from https://github.com/dwyl/imgup
and run it on your localhost.

## 0. Project setup

To create a new project in `Flutter`,
follow the steps in 
https://github.com/dwyl/learn-flutter#0-setting-up-a-new-project.

After completing these steps,
you should have a boilerplate `Flutter` project.
You can see the state of the project files
should correspond to the ones found in 
https://github.com/dwyl/flutter-image-upload-demo/tree/4b7b5fa2396a26e866cad59e17642b98ba43fede.

If you run the app, you should see the template Counter app.
The tests should also run correctly.
Executing `flutter test --coverage` should yield
this output on the terminal.

```sh
00:02 +1: All tests passed!   
```

This means everything is correctly setup!
We are ready to start implementing!

## 1. Adding basic picker and multipart request

Let's get a basic `Picker` component working which,
upon choosing an image successfully, 
starts a [multipart request](https://medium.com/nerd-for-tech/multipartrequest-in-http-for-sending-images-videos-via-post-request-in-flutter-e689a46471ab).

To achieve this, 
we are going to need three libraries:
- [`file_picker`](https://pub.dev/packages/file_picker),
which will make selecting images simple.
- [`http`](https://pub.dev/packages/http),
to make API calls.
- [`mime`](https://pub.dev/packages/mime),
to determine the [MIME type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types) of the file 
to be used in the request.

To install these libraries,
in `pubspec.yaml`,
add these lines inside the `dependencies` section.

```yaml
  file_picker: ^5.3.2
  http: ^1.0.0
  mime: ^1.0.4
```

And run `flutter pub get`.
This will install these dependencies.

Now, create a file called `http.dart` inside `lib`
and add the following piece of code.

```dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

const API_URL = 'http://localhost:4000/api/images';

// coverage:ignore-start
/// Image file picker wrapper class
class ImageFilePicker {
  Future<FilePickerResult?> pickImage() => FilePicker.platform.pickFiles(type: FileType.image);
}
// coverage:ignore-end

/// Opens a dialog [imageFilePicker] and creates  MultipartRequest [request].
/// In the request, a field 'image' is appended with the chosen image and the public URL of the image is returned in case of success.
Future<String?> openImagePickerDialog(ImageFilePicker imageFilePicker, http.Client client) async {
  FilePickerResult? result = await imageFilePicker.pickImage();
  MultipartRequest request = http.MultipartRequest('POST', Uri.parse(API_URL));

  if (result != null) {
    // Get file and make request
    PlatformFile platformFile = result.files.first;
    File file = File(result.files.first.path!);

    // Read file as bytes and add it to request object
    final bytes = await file.readAsBytes();
    final httpImage =
        http.MultipartFile.fromBytes('image', bytes, contentType: MediaType.parse(lookupMimeType(file.path)!), filename: platformFile.name);
    request.files.add(httpImage);

    // Send request
    final response = await client.send(request);

    // Get response of request
    Response responseStream = await http.Response.fromStream(response);
    final responseData = json.decode(responseStream.body);

    return responseData['url'];
  } else {
    // User canceled the picker
    return null;
  }
}
```

In summary, the `openImagePickerDialog` is a function will open a picker
and make the API request to the given URL 
and return the URL that is returned from the API.

However, there are a few choices of why we've made all of these steps into a single function.
This function receives two objects: 
- an `ImageFilePicker`, which is a wrapper of the 
`FilePicker.platform.pickFiles()` function
from the `file_picker` library.
This function simply opens the picker for the person
to choose the image.
- an `http.Client` class.

These are passed as parameter **for testing reasons**.
By doing this, we can effectively *mock* 
this function's behaviour
and make testing much easier by 
[**dependency injection**](https://medium.com/flutter-community/dependency-injection-in-flutter-f19fb66a0740).

The reason we are wrapping the picker behaviour
with the class `ImageFilePicker`
is because it's a static method, 
which can't easily be mocked.
To circumvent this,
we wrap the static function with the class
so we can mock it when testing.
For more information about this, 
visit https://github.com/dart-lang/mockito/issues/214.


### 1.1 Explaining `openImagePickerDialog`'s behaviour

Now that we've asserted *why we are injecting dependencies*,
let's explain the rest of the function.

```dart
await imageFilePicker.pickImage();
```

The previous line picks and image and returns a `FilePickerResult`.
If this return is `null`,
it means the person cancelled the operation 
and did not choose an image.
Otherwise, we proceed.

With the result of the person picking the image,
we use its path to create a 
[`File`](https://api.dart.dev/stable/3.0.5/dart-io/File-class.html)
object.
With this object,
we can *read the file as an array of bytes*,
and use the latter
**to add it to the multipart request**,
as noted in the next line.

```dart
final httpImage =
        http.MultipartFile.fromBytes('image', bytes, contentType: MediaType.parse(lookupMimeType(file.path)!), filename: platformFile.name);
    request.files.add(httpImage);
```

We are essentially creating a multipart request
with the field `image` as key,
and the value being the file's contents.
Because we have to define the 
[`Content Type`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type)
when creating the request,
we use the 
[`lookupMimeType`](https://pub.dev/documentation/mime/latest/mime/lookupMimeType.html)
function from the `mime` library
to get the MIME type of the file.

After this, 
we simply send the request away!

```dart
final response = await client.send(request);
```

With the successful request being made,
we decode it
and retrieve the `url` field 
from the `json` response of the API,
which has the following format.

```json
{
  "compressed_url": "https://s3.eu-west-3.amazonaws.com/imgup-compressed/zb2rheg9SUidrPwaKMMJipf54b5YxmkTxPt3xAbiq9kWkngis.jpg",
  "url": "https://s3.eu-west-3.amazonaws.com/imgup-original/zb2rheg9SUidrPwaKMMJipf54b5YxmkTxPt3xAbiq9kWkngis.jpg"
}
```

And that's it!
We are going to be using this URL
**to render the image on our app**.

That comes up next!


## 2. Changing `MyHomePage` so it receives mockable dependencies

To use the function we've implemented earlier,
we are going to need to create them at a root level.

> In a normal application,
> we could use libraries like [`Riverpod`](https://riverpod.dev/)
> to make this much easier.
> However, because this is a simple demo,
> we will refrain from using packages like this.

Therefore,
open `lib/main.dart`
and change the `main`, `myApp`
and `MyHomepage` widgets like so:

```dart
final buttonKey = UniqueKey();
final imageKey = UniqueKey();

// coverage:ignore-start
void main() {
  runApp( MyApp(imageFilePicker: ImageFilePicker(), client: http.Client()));
}
// coverage:ignore-end

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.imageFilePicker, required this.client});

  final ImageFilePicker imageFilePicker;
  final http.Client client;

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Image Upload Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: MyHomePage(imageFilePicker: imageFilePicker, client: client),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.imageFilePicker, required this.client});

  final ImageFilePicker imageFilePicker;
  final http.Client client;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
```

As you may have noticed,
we instantiate the `ImageFilePicker` and `http.Client` 
classes in the `main()` function.
For reference,
when testing,
these are the functions that will be mocked.

As such,
we define `imageFilePicker`
and `client`
in both `MyApp` and `MyHomePage` widgets
and pass these dependencies down the widget tree. 


## 3. Changing the `MyHomePage` widget view.

Now we can change our homepage!
Open `lib/main.dart`
and change `_MyHomePageState`
to the following:

```dart
class _MyHomePageState extends State<MyHomePage> {
  String? imageURL;

  /// Called when the image is pressed.
  /// It invokes `openImagePickerDialog`, which opens a dialog to select an image and makes the request to upload the image.
  void _onImagePressed() async {
    String? url = await openImagePickerDialog(widget.imageFilePicker, widget.client);

    if (url != null) {
      setState(() {
        imageURL = url;
      });
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: imageURL != null
                    // Image URL is defined
                    ? [
                        const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Column(children: [
                              Text(
                                "Here's your uploaded image!",
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              Text("It's living on the web."),
                            ])),
                        Image.network(
                          key: imageKey,
                          imageURL!,
                          fit: BoxFit.fill,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      ]
                    :
                    // No image URL is defined
                    [const Text("No image has been uploaded.")],
              ),
            )
          ],
        ),
      ),
    );
  }
}
```

We've done a couple of things here:
- the `imageURL` it the widget's field 
that is changed every time the person 
picks an image and uploads it to the API.
The `URL` returned from the API is mapped to this field.
- we are rendering an `ElevatedButton`
that, when clicked, calls the `_onImagePressed`
function.
This function simply calls the `openImagePickerDialog` function
we've implemented in `lib/http.dart`
and maps the returned URL to `imageURL`.
This is done by calling [`setState()`](https://api.flutter.dev/flutter/widgets/State/setState.html), 
which triggers a re-render of the widget.
- we use [`Image.network`](https://api.flutter.dev/flutter/widgets/Image/Image.network.html)
to render the image from the URL provided by the API.

And that's it!

If you run the app,
you should be able to see the button and,
upon pressing it and picking an image,
see the image you've just uploaded!

> **Note**
>
> Make sure you have the API running on your `localhost`.
> If you prefer to call the API at 
> https://imgup.fly.dev/api/images,
> change the `API_URL` variable in `lib/http.dart` before running the app.

> If you try to upload the images of pink flowers
> in your iOS simulator,
> this won't work.
> This is a [known issue](https://github.com/miguelpruivo/flutter_file_picker/issues/997#issuecomment-1070981727)
> that only happens on this very much,
> so you can safely ignore it.

![final](https://github.com/dwyl/flutter-image-upload-demo/assets/17494745/8ff4ecad-1158-42d6-90fe-68fe67d700e9)

Awesome! 
Give yourself a pat on the back 🙂.


## 4. Testing our app

Now it's time to test our app.
If we run `flutter test --coverage`,
the tests will fail.
After all, we've made all of these changes 
and haven't touched our tests.

Luckily for us, because we've implemented our app
*knowing we'd be mocking some of its components*,
we can easily test our app 
and cover it in its entirety!

To successfully mock objects,
we are going to be using 
[`mockito`](https://pub.dev/packages/mockito).

For this, 
open `pubspec.yaml`
and inside `dev_dependencies`,
add these lines.

```yaml
  mockito: ^5.4.2
  build_runner: ^2.4.5
  network_image_mock: ^2.1.1
```

We've also added [`network_image_mock`](https://pub.dev/packages/network_image_mock).
[Because HTTP Requests are blocked by default in Flutter tests](https://timm.preetz.name/articles/http-request-flutter-test),
when using `Image.network`,
the tests will eventually crash.
With this package,
we can bypass this issue.

Now let's create the tests!
Inside `test/widget_test.dart`,
paste the following code.

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_upload_demo/http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import 'package:flutter_image_upload_demo/main.dart';
import 'package:network_image_mock/network_image_mock.dart';

// importing mocks
import 'widget_test.mocks.dart';

/// File mock (overrides `dart.io`)
/// Visit https://api.flutter.dev/flutter/dart-io/IOOverrides-class.html for more information
/// and https://stackoverflow.com/questions/64031671/flutter-readasbytes-readasstring-in-widget-tests for context on why `readAsBytes` is skipped on tests.
/// This is used to mock the `File` class (useful for `readAsBytes`)
class FileMock extends MockFile {
  @override
  Future<Uint8List> readAsBytes() {
    Uint8List bytes = Uint8List(0);
    return Future<Uint8List>.value(bytes);
  }

  @override
  String get path => "some_path.png";
}

@GenerateMocks([http.Client, ImageFilePicker, File])
void main() {
  testWidgets('Initial mount', (WidgetTester tester) async {
    // Mocks
    final clientMock = MockClient();
    final filePickerMock = MockImageFilePicker();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      imageFilePicker: filePickerMock,
      client: clientMock,
    ));

    // Verify that the page loads properly
    expect(find.text('No image has been uploaded.'), findsOneWidget);
  });

  testWidgets('Pressing the button should show dialog and person cancels it', (WidgetTester tester) async {
    // Mocks
    final clientMock = MockClient();
    final filePickerMock = MockImageFilePicker();

    // Set mock behaviour
    when(filePickerMock.pickImage()).thenAnswer((_) async => Future<FilePickerResult?>.value(null));

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      imageFilePicker: filePickerMock,
      client: clientMock,
    ));

    final button = find.byKey(buttonKey);

    // Tap button
    await tester.tap(button);
    await tester.pumpAndSettle();

    // Verify that no image is shown
    expect(find.text('No image has been uploaded.'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('Pressing the button should show dialog and person uploads image', (WidgetTester tester) async {

    /// Because we are using `Image.network`, which throws `400` on tests,
    /// we use https://github.com/stelynx/network_image_mock to override this behaviour
    /// so the test doesn't crash.
    mockNetworkImagesFor(() =>

        /// We are overriding the `IO` because `readAsBytes` is skipped on tests.
        /// We use the mocked file so the test can be executed correctly.
        IOOverrides.runZoned(
          () async {
            // Mocks
            final clientMock = MockClient();
            final filePickerMock = MockImageFilePicker();

            // Set mock behaviour for `filePickerMock`
            final List<PlatformFile> listMockFiles = [PlatformFile(name: 'image.png', size: 200, path: "some_path")];

            when(filePickerMock.pickImage()).thenAnswer((_) async => Future<FilePickerResult?>.value(FilePickerResult(listMockFiles)));

            // Set mock behaviour for `requestMock`
            const body = "{\"url\":\"return_url\"}";
            final bodyBytes = utf8.encode(body);
            when(clientMock.send(any)).thenAnswer((_) async => http.StreamedResponse(Stream<List<int>>.fromIterable([bodyBytes]), 200));

            // Build our app and trigger a frame.
            await tester.pumpWidget(MyApp(
              imageFilePicker: filePickerMock,
              client: clientMock,
            ));

            final button = find.byKey(buttonKey);
            final image = find.byKey(imageKey);

            // Tap button
            await tester.tap(button);
            await tester.pumpAndSettle();

            // Verify that image is shown
            expect(find.text('No image has been uploaded.'), findsNothing);
            expect(image, findsOneWidget);
          },
          createFile: (_) => FileMock(),
        ));
  });
}
```

Gee whiz, that's a lot!
Don't worry, we'll cover all of these changes! 😅

Firstly, 
we are using the `@GenerateMocks` annotation
from the `mockito` library
to generate the mocks for us.
With this annotation,
we can run the following command,
which will create `widget_test.mocks.dart`
that we can use in our tests.

```sh
flutter pub run build_runner build
```

This command will generate the mocks of the 
given objects that are passed in the 
`@GenerateMocks` annotation.
This creates the mock classes,
like `MockClient` and `MockImageFilePicker`.

We are wrapping `MockFile`
with a class called `FileMock`
(on top of the file).
This is to override the `readAsBytes` function,
[which usually fails during tests](https://stackoverflow.com/questions/64031671/flutter-readasbytes-readasstring-in-widget-tests).
In `FileMock`, we also mock the behaviour
when fetching the `path`,
which is used in the `openImagePickerDialog` function.

The first test `'Initial mount'` is quite simple.
We simply use the `MockClient` and `MockImageFilePicker`
mocks we've generated 
and pass it on the `MyApp` widget.

The second test `'Pressing the button should show dialog and person cancels it'`,
we mock the behaviour of the `pickImage()` function
by stubbing it with the 
[`when`](https://pub.dev/documentation/mockito/latest/mockito/when.html) class.
We are simulating the person not picking an image,
hence why it's returning `null`.

In the third test `'Pressing the button should show dialog and person uploads image'`,
we make use of the `mockNetworkImagesFor()`
function to make sure `Image.network` doesn't fail
(this is from the `network_image_mock` library).
In addition to this,
we use [`IOOerrides`](https://api.flutter.dev/flutter/dart-io/IOOverrides-class.html)
so `readAsBytes` is correctly stubbed 
and the test doesn't crash.

And that's it!
We are correctly stubbing behaviour 
and making our tests pass properly!
If you execute `flutter test --coverage`,
all tests should pass! ✅


## 5. Adding `Flutter Web` support

Because we are using [`flutter_file_picker`](https://github.com/miguelpruivo/flutter_file_picker),
we need to make a few adjustments to our code
so it supports uploading the image on web-based browsers.

To change the behaviour of our application according to the platform,
we can use the constant [`kIsWeb`](https://api.flutter.dev/flutter/foundation/kIsWeb-constant.html),
that returns true if the application was compiled to run on the web.

Therefore, in order to make our code behave differently and *testable*,
we are going to create a small class `PlatformService`,
which will have a `isWebPlatform` function that will return the value of this constant.
This class will be dependency-injected so it can later changed during testing.

In `lib/http.dart`,
create the class.

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformService {
  bool isWebPlatform() {
    return kIsWeb;
  }
}
```

Next, change the `openImagePickerDialog` function to the following:

```dart
Future<APIResponse?> openImagePickerDialog(ImageFilePicker imageFilePicker, http.Client client, PlatformService platformService) async {
  FilePickerResult? result = await imageFilePicker.pickImage();
  MultipartRequest request = http.MultipartRequest('POST', Uri.parse(API_URL));

  if (result != null && result.files.isNotEmpty) {
    // Get file
    PlatformFile platformFile = result.files.first;

    // Make request according to the platform.
    // If the platform is web-based, we need to use the `bytes` directly.
    // Otherwise, we can use the `path` to add it to the request
    if (platformService.isWebPlatform()) {
      // Read file as bytes
      final bytes = platformFile.bytes;

      // If it's not empty, we populate the request
      if (bytes != null) {
        final httpImage = http.MultipartFile.fromBytes('image', bytes,
            contentType: MediaType.parse(lookupMimeType('', headerBytes: bytes)!), filename: platformFile.name);
        request.files.add(httpImage);
      }
    } else {
      // Read file from the path
      File file = File(result.files.first.path!);

      // Read file as bytes and add it to request object
      final bytes = await file.readAsBytes();
      final httpImage =
          http.MultipartFile.fromBytes('image', bytes, contentType: MediaType.parse(lookupMimeType(file.path)!), filename: platformFile.name);
      request.files.add(httpImage);
    }

    // Send request
    final response = await client.send(request);

    // Get response of request
    Response responseStream = await http.Response.fromStream(response);
    final responseData = json.decode(responseStream.body);

    return APIResponse(url: responseData['url'], code: response.statusCode);
  } else {
    // User canceled the picker
    return null;
  }
}
```

This function now receives an instance 
of the newly-created `PlatformService` class.

We've added an `if` statement which checks the current platform.
If it's the case that's a web-based one, 
instead of creating a `File` object like we do on mobile platforms,
we simply fetch the `bytes` array directly from the `FilePickerResult` object
yielded by the `imageFilePicker`.

Because `openImagePickerDialog` now receives a new parameter,
we are going to do the same thing we've made for the `http.Client` and `ImageFilePicker`:
we are going to dependency-inject it from the root widget `MyApp`.

Head over to `lib/main.dart`
and change `MyApp` and `MyHomePage` like so: 

```dart
void main() {
  runApp(MyApp(imageFilePicker: ImageFilePicker(), client: http.Client(), platformService: PlatformService(),));
}

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
```

We've added a new field `final PlatformService platformService` in both widgets,
which are passed down the widget tree.
Now, inside `MyHomePageState`, 
add the new parameter when invoking the `openImageFilePicker` dialog function.

```dart
    APIResponse? response = await openImagePickerDialog(widget.imageFilePicker, widget.client, widget.platformService);
```

And that's it!
Now let's fix our tests!


### 5.1 Fixing tests

Open `test/widget_test.dart` and change it to the following:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_upload_demo/http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import 'package:flutter_image_upload_demo/main.dart';
import 'package:network_image_mock/network_image_mock.dart';

// importing mocks
import 'widget_test.mocks.dart';

/// File mock (overrides `dart.io`)
/// Visit https://api.flutter.dev/flutter/dart-io/IOOverrides-class.html for more information
/// and https://stackoverflow.com/questions/64031671/flutter-readasbytes-readasstring-in-widget-tests for context on why `readAsBytes` is skipped on tests.
/// This is used to mock the `File` class (useful for `readAsBytes`)
class FileMock extends MockFile {

  @override
  Future<Uint8List> readAsBytes() {
    Uint8List bytes = Uint8List(0);
    return Future<Uint8List>.value(bytes);
  }

  @override
  String get path => "some_path.png";
}

@GenerateMocks([http.Client, ImageFilePicker, File, PlatformService])
void main() {
  testWidgets('Initial mount', (WidgetTester tester) async {
    // Mocks
    final clientMock = MockClient();
    final filePickerMock = MockImageFilePicker();
    final platformServiceMock = MockPlatformService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      imageFilePicker: filePickerMock,
      client: clientMock,
      platformService: platformServiceMock,
    ));

    // Verify that the page loads properly
    expect(find.text('No image has been uploaded.'), findsOneWidget);
  });

  testWidgets('Pressing the button should show dialog and person cancels it', (WidgetTester tester) async {
    // Mocks
    final clientMock = MockClient();
    final filePickerMock = MockImageFilePicker();
    final platformServiceMock = MockPlatformService();

    // Platform is mobile
    when(platformServiceMock.isWebPlatform()).thenAnswer((_) => false);

    // Set mock behaviour
    when(filePickerMock.pickImage()).thenAnswer((_) async => Future<FilePickerResult?>.value(null));

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      imageFilePicker: filePickerMock,
      client: clientMock,
      platformService: platformServiceMock,
    ));

    final button = find.byKey(buttonKey);

    // Tap button
    await tester.tap(button);
    await tester.pumpAndSettle();

    // Verify that no image is shown
    expect(find.text('No image has been uploaded.'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('Pressing the button should show dialog and person uploads image', (WidgetTester tester) async {
    /// Because we are using `Image.network`, which throws `400` on tests,
    /// we use https://github.com/stelynx/network_image_mock to override this behaviour
    /// so the test doesn't crash.
    mockNetworkImagesFor(() =>

        /// We are overriding the `IO` because `readAsBytes` is skipped on tests.
        /// We use the mocked file so the test can be executed correctly.
        IOOverrides.runZoned(
          () async {
            // Mocks
            final clientMock = MockClient();
            final filePickerMock = MockImageFilePicker();
            final platformServiceMock = MockPlatformService();

            // Platform is mobile
            when(platformServiceMock.isWebPlatform()).thenAnswer((_) => false);

            // Set mock behaviour for `filePickerMock`
            final List<PlatformFile> listMockFiles = [PlatformFile(name: 'image.png', size: 200, path: "some_path")];

            when(filePickerMock.pickImage()).thenAnswer((_) async => Future<FilePickerResult?>.value(FilePickerResult(listMockFiles)));

            // Set mock behaviour for `requestMock`
            const body = "{\"url\":\"return_url\"}";
            final bodyBytes = utf8.encode(body);
            when(clientMock.send(any)).thenAnswer((_) async => http.StreamedResponse(Stream<List<int>>.fromIterable([bodyBytes]), 200));

            // Build our app and trigger a frame.
            await tester.pumpWidget(MyApp(
              imageFilePicker: filePickerMock,
              client: clientMock,
              platformService: platformServiceMock,
            ));

            final button = find.byKey(buttonKey);
            final image = find.byKey(imageKey);

            // Tap button
            await tester.tap(button);
            await tester.pumpAndSettle();

            // Verify that image is shown
            expect(find.text('No image has been uploaded.'), findsNothing);
            expect(image, findsOneWidget);

            // Tap image
            await tester.tap(image);
            await tester.pumpAndSettle();
          },
          createFile: (_) => FileMock(),
        ));
  });

  testWidgets('Pressing the button should show dialog and person uploads image (web version)', (WidgetTester tester) async {
    /// Because we are using `Image.network`, which throws `400` on tests,
    /// we use https://github.com/stelynx/network_image_mock to override this behaviour
    /// so the test doesn't crash.
    mockNetworkImagesFor(() =>

        /// We are overriding the `IO` because `readAsBytes` is skipped on tests.
        /// We use the mocked file so the test can be executed correctly.
        IOOverrides.runZoned(
          () async {
            // Mocks
            final clientMock = MockClient();
            final filePickerMock = MockImageFilePicker();
            final platformServiceMock = MockPlatformService();

            // Platform is web
            when(platformServiceMock.isWebPlatform()).thenAnswer((_) => true);

            // Set mock behaviour for `filePickerMock` with jpeg magic number byte array https://gist.github.com/leommoore/f9e57ba2aa4bf197ebc5
            final List<PlatformFile> listMockFiles = [PlatformFile(name: 'image.png', size: 200, path: "some_path", bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]))];

            when(filePickerMock.pickImage()).thenAnswer((_) async => Future<FilePickerResult?>.value(FilePickerResult(listMockFiles)));

            // Set mock behaviour for `requestMock`
            const body = "{\"url\":\"return_url\"}";
            final bodyBytes = utf8.encode(body);
            when(clientMock.send(any)).thenAnswer((_) async => http.StreamedResponse(Stream<List<int>>.fromIterable([bodyBytes]), 200));

            // Build our app and trigger a frame.
            await tester.pumpWidget(MyApp(
              imageFilePicker: filePickerMock,
              client: clientMock,
              platformService: platformServiceMock,
            ));

            final button = find.byKey(buttonKey);
            final image = find.byKey(imageKey);

            // Tap button
            await tester.tap(button);
            await tester.pumpAndSettle();

            // Verify that image is shown
            expect(find.text('No image has been uploaded.'), findsNothing);
            expect(image, findsOneWidget);

            // Tap image
            await tester.tap(image);
            await tester.pumpAndSettle();
          },
          createFile: (_) => FileMock(),
        ));
  });

  testWidgets('Pressing the button should show dialog and person uploads image and the API returns error', (WidgetTester tester) async {
    /// We are overriding the `IO` because `readAsBytes` is skipped on tests.
    /// We use the mocked file so the test can be executed correctly.
    IOOverrides.runZoned(
      () async {
        // Mocks
        final clientMock = MockClient();
        final filePickerMock = MockImageFilePicker();
        final platformServiceMock = MockPlatformService();

        // Platform is mobile
        when(platformServiceMock.isWebPlatform()).thenAnswer((_) => false);

        // Set mock behaviour for `filePickerMock`
        final List<PlatformFile> listMockFiles = [PlatformFile(name: 'image.png', size: 200, path: "some_path")];

        when(filePickerMock.pickImage()).thenAnswer((_) async => Future<FilePickerResult?>.value(FilePickerResult(listMockFiles)));

        // Set mock behaviour for `requestMock`, retyping error
        const body = "{\"error\":\"Couldn\'t upload image.\"}";
        final bodyBytes = utf8.encode(body);
        when(clientMock.send(any)).thenAnswer((_) async => http.StreamedResponse(Stream<List<int>>.fromIterable([bodyBytes]), 405));

        // Build our app and trigger a frame.
        await tester.pumpWidget(MyApp(
          imageFilePicker: filePickerMock,
          client: clientMock,
          platformService: platformServiceMock,
        ));

        final button = find.byKey(buttonKey);

        // Tap button
        await tester.tap(button);
        await tester.pumpAndSettle();

        // Verify that error is shown
        expect(find.text('There was an error uploading the image. Check if the API is up.'), findsOneWidget);
      },
      createFile: (_) => FileMock(),
    );
  });
}
```

We've made a handful of changes here:

- because we are using dependency-injection with the `PlatformService`,
we need to add it to `@GenerateMocks([http.Client, ImageFilePicker, File, PlatformService])`
so we can simulate that the test is being executed in a web-based environment.
We run `flutter pub run build_runner build` to regenerate `test/widget_test.mocks.dart`.
- in each test, we've added `final platformServiceMock = MockPlatformService();`
that is used when pumping `MyApp`.
- asserted the platform of each unit test by adding
`when(platformServiceMock.isWebPlatform()).thenAnswer((_) => false);`,
(this line returns `false`, meaning it's a mobile platform),
effectively changing the behaviour of the `kIsWeb` constant we've discussed earlier.
- added a new test for a normal flow in web-based platforms.
This new test is fairly similar to its mobile counterpart, 
as it should, since the behaviour is expected to be similar in both cases.

And that's it!
We've successfully made our app **compatible with `Flutter Web`**!



## 6. (Optional) Click on image to open the URL in the browser

Because the image is stored on the web,
*and we know where it is stored*,
it'd be useful for the person using the app
to be redirected to the URL when clicking on the image.

For this, we are going to need to use the 
[`url_launcher`](https://pub.dev/packages/url_launcher)
package.
To install it, simply run `flutter pub add url_launcher`.

Now, let's use it!
In `lib/main.dart`,
change the `build()` function 
of the `_MyHomePageState` class.

```dart
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: imageURL != null
                    // Image URL is defined
                    ? [
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
                              Text("It's living on the web. Click on the picture to open in the browser.", textAlign: TextAlign.center,),
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
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ]
                    :
                    // No image URL is defined
                    [const Text("No image has been uploaded.")],
              ),
            )
          ],
        ),
      ),
    );
  }
```

We've wrapped `Image.network`
with a [`GestureDetector` class](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html).
When pressed,
we use the `launchUrl` function from the package
we've just imported to launch a web browser
with the URL of the image `imageURL`.

And that's it!
We've also changed the text 
to tell the person that he can click the image
to open it in the browser.

If you run the app,
everything should properly work!

![final_with_urlloader](https://github.com/dwyl/flutter-image-upload-demo/assets/17494745/cc05ac09-f30d-4714-b490-808ff317a005)


## 6.1 Changing tests

Because this redirection is handled by the OS of the device,
and is *out of context of the `Flutter` app*,
[it's impossible to unit test this behaviour](https://stackoverflow.com/questions/54869155/how-to-test-flutter-url-launcher-that-email-app-opens).
However, we can get the coverage back to 100%
by simply tapping on the image during the test.

Therefore, in `test/widget_test.dart`,
in the `'Pressing the button should show dialog and person uploads image'` test,
add these two lines at the end of it.

```dart
    // Tap image
    await tester.tap(image);
    await tester.pumpAndSettle();
```

And that's it!
All tests should successfully run without a hitch! 🏃‍♂️


## 7. (Optional) Adding progress circle while requesting API

Currently, when the person chooses an image,
there's a delay for the image to be shown.
This is because the request to the API occurs.

In order to let the person know the request is in-progress,
let's add a simple progress circle!

Open `lib/main.dart`
and change `_MyHomePageState` to the following.

```dart
class _MyHomePageState extends State<MyHomePage> {
  String? imageURL;
  bool isLoading = false;

  /// Called when the image is pressed.
  /// It invokes `openImagePickerDialog`, which opens a dialog to select an image and makes the request to upload the image.
  void _onImagePressed() async {
    setState(() {
      isLoading = true;
    });

    String? url = await openImagePickerDialog(widget.imageFilePicker, widget.client);

    if (url != null) {
      setState(() {
        imageURL = url;
        isLoading = false;
      });
    }
  }

  Widget renderImage() {
    if (isLoading) {
      return const CircularProgressIndicator();
    } else {
      return GestureDetector(
        onTap: () async {
          final Uri url = Uri.parse(imageURL!);
          await launchUrl(url);
        },
        child: Image.network(
          key: imageKey,
          imageURL!,
          fit: BoxFit.fill,
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
              ),
            );
          },
        ),
      );
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: imageURL != null
                    // Image URL is defined
                    ? [
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
                        renderImage(),
                      ]
                    :
                    // No image URL is defined
                    [const Text("No image has been uploaded.")],
              ),
            )
          ],
        ),
      ),
    );
  }
}
```

We've added an `isLoading` boolean field.
This is initialized as `false`.
It's set to `true` whenever the person
starts the request and set back to `false`
when the request is finished.

We've created a function called `renderImage()` 
where we've extracted the `GestureDetector`.
In this function,
we are conditionally rendering the image or the loading icon
according to the `isLoading` field.
This way, we're showing the `CircularProgressIndicator` widget
whenever the request is happening!

And it's that simple!


## 8. (Optional) Showing error text in case API fails

As it stands, if the API (for some reason)
*fails* at uploading the image,
it will return an error response (that is not HTTP Code `200`).

We should tell the person that something went wrong
in case this fails.
For this, we're going to be making a couple of changes.

Head to `lib/http.dart`
and create a class called `APIResponse`.

```dart
class APIResponse {
  final String? url;
  final int code;

  APIResponse({this.url, required this.code});
}
```

The `openImagePickerDialog` function will now return `Future<APIResponse?>`
and return an instance of this class.

```dart
    return APIResponse(url: responseData['url'], code: response.statusCode);
```

Next, go to `lib/main.dart`,
more specifically `_MyHomePageState`
and create a field called `errored`.

```dart
class _MyHomePageState extends State<MyHomePage> {
  String? imageURL;
  bool isLoading = false;
  bool errored = false;

  ...
}
```

We're going to change the `_onImagePresseed` and
`renderImage` functions.

```dart
void _onImagePressed() async {
    setState(() {
      isLoading = true;
    });

    APIResponse? response = await openImagePickerDialog(widget.imageFilePicker, widget.client);

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
```

We've made a ew changes.
Because we get an instance of `APIResponse`,
we use it to set the fields `errored`, `imageURL` and `isLoading`
according to what we've received from the API.

Inside `renderImage()`, we render the contents accordingly.
- If the API errored out, we render a text.
- If the API returned an URL, we render an image.
- If the `response` was `null`, it means the person cancelled the operation,
so we don't do anything.

In the `build` function,
simply change the `Expanded` widget
to use the `renderImage` function.

```dart
Expanded(
  child: SingleChildScrollView(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: renderImage(),
    ),
  ),
)
```

And we're done!
All that's left is add a test to test this error edge case!

Head to `test/widget_test.dart`
and add the following test.

```dart
testWidgets('Pressing the button should show dialog and person uploads image and the API returns error', (WidgetTester tester) async {
    /// We are overriding the `IO` because `readAsBytes` is skipped on tests.
    /// We use the mocked file so the test can be executed correctly.
    IOOverrides.runZoned(
      () async {
        // Mocks
        final clientMock = MockClient();
        final filePickerMock = MockImageFilePicker();

        // Set mock behaviour for `filePickerMock`
        final List<PlatformFile> listMockFiles = [PlatformFile(name: 'image.png', size: 200, path: "some_path")];

        when(filePickerMock.pickImage()).thenAnswer((_) async => Future<FilePickerResult?>.value(FilePickerResult(listMockFiles)));

        // Set mock behaviour for `requestMock`, retyping error
        const body = "{\"error\":\"Couldn\'t upload image.\"}";
        final bodyBytes = utf8.encode(body);
        when(clientMock.send(any)).thenAnswer((_) async => http.StreamedResponse(Stream<List<int>>.fromIterable([bodyBytes]), 405));

        // Build our app and trigger a frame.
        await tester.pumpWidget(MyApp(
          imageFilePicker: filePickerMock,
          client: clientMock,
        ));

        final button = find.byKey(buttonKey);

        // Tap button
        await tester.tap(button);
        await tester.pumpAndSettle();

        // Verify that error is shown
        expect(find.text('There was an error uploading the image. Check if the API is up.'), findsOneWidget);
      },
      createFile: (_) => FileMock(),
    );
  });
```

And that's it! 🎉

We are now rendering a simple text stating
`'There was an error uploading the image. Check if the API is up.'`
whenever there's an error from the API. 

