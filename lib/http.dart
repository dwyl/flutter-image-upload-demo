import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

const API_URL = 'https://imgup.fly.dev/api/images';

// coverage:ignore-start
/// Image file picker wrapper class
class ImageFilePicker {
  Future<FilePickerResult?> pickImage() => FilePicker.platform.pickFiles(type: FileType.image);
}

// Platform service class that tells if the platform is web-based or not
class PlatformService {
  bool isWebPlatform() {
    return kIsWeb;
  }
}
// coverage:ignore-end


class APIResponse {
  final String? url;
  final int code;

  APIResponse({this.url, required this.code});
}


/// Opens a dialog [imageFilePicker] and creates  MultipartRequest [request].
/// In the request, a field 'image' is appended with the chosen image and the public URL of the image is returned in case of success.
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
