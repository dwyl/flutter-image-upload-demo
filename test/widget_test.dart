import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_upload_demo/http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import 'package:flutter_image_upload_demo/main.dart';

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

        // Verify that no image is shown
        expect(find.text('No image has been uploaded.'), findsNothing);
        expect(image, findsOneWidget);
      },
      createFile: (_) => FileMock(),
    );
  });
}