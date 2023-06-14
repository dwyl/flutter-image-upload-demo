import 'package:flutter/material.dart';
import 'package:flutter_image_upload_demo/http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'package:file_picker/file_picker.dart';

import 'package:flutter_image_upload_demo/main.dart';

// importing mocks
import 'widget_test.mocks.dart';

@GenerateMocks([http.Client, ImageFilePicker])
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

  /*
  testWidgets('Pressing the button should show dialog and person uploads image', (WidgetTester tester) async {
    // Mocks
    final requestMock = MockMultipartRequest();
    final filePickerMock = MockImageFilePicker();

    // Set mock behaviour for `filePickerMock`
    final List<PlatformFile> listMockFiles = [
      PlatformFile(
        name: 'image.png',
        size: 200
      )
    ];

    when(filePickerMock.pickImage()).thenAnswer((_) async => Future<FilePickerResult?>.value(FilePickerResult(listMockFiles)));

    // Set mock behaviour for `requestMock`
    when(requestMock.send()).thenAnswer((_) async => http.StreamedResponse(Stream<List<int>>.fromIterable([]), 200));

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      imageFilePicker: filePickerMock,
      multipartRequest: requestMock,
    ));

    final button = find.byKey(buttonKey);

    // Tap button
    await tester.tap(button);
    await tester.pumpAndSettle();

    // Verify that no image is shown
    expect(find.text('No image has been uploaded.'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
  */
}
