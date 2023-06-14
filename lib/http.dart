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
