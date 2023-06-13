// Mocks generated by Mockito 5.4.2 from annotations
// in flutter_image_upload_demo/test/widget_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i6;

import 'package:file_picker/file_picker.dart' as _i8;
import 'package:flutter_image_upload_demo/http.dart' as _i7;
import 'package:http/http.dart' as _i2;
import 'package:http/src/byte_stream.dart' as _i4;
import 'package:http/src/multipart_file.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i5;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeUri_0 extends _i1.SmartFake implements Uri {
  _FakeUri_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeStreamedResponse_1 extends _i1.SmartFake
    implements _i2.StreamedResponse {
  _FakeStreamedResponse_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [MultipartRequest].
///
/// See the documentation for Mockito's code generation for more information.
class MockMultipartRequest extends _i1.Mock implements _i2.MultipartRequest {
  MockMultipartRequest() {
    _i1.throwOnMissingStub(this);
  }

  @override
  Map<String, String> get fields => (super.noSuchMethod(
        Invocation.getter(#fields),
        returnValue: <String, String>{},
      ) as Map<String, String>);
  @override
  List<_i3.MultipartFile> get files => (super.noSuchMethod(
        Invocation.getter(#files),
        returnValue: <_i3.MultipartFile>[],
      ) as List<_i3.MultipartFile>);
  @override
  int get contentLength => (super.noSuchMethod(
        Invocation.getter(#contentLength),
        returnValue: 0,
      ) as int);
  @override
  set contentLength(int? value) => super.noSuchMethod(
        Invocation.setter(
          #contentLength,
          value,
        ),
        returnValueForMissingStub: null,
      );
  @override
  String get method => (super.noSuchMethod(
        Invocation.getter(#method),
        returnValue: '',
      ) as String);
  @override
  Uri get url => (super.noSuchMethod(
        Invocation.getter(#url),
        returnValue: _FakeUri_0(
          this,
          Invocation.getter(#url),
        ),
      ) as Uri);
  @override
  Map<String, String> get headers => (super.noSuchMethod(
        Invocation.getter(#headers),
        returnValue: <String, String>{},
      ) as Map<String, String>);
  @override
  bool get persistentConnection => (super.noSuchMethod(
        Invocation.getter(#persistentConnection),
        returnValue: false,
      ) as bool);
  @override
  set persistentConnection(bool? value) => super.noSuchMethod(
        Invocation.setter(
          #persistentConnection,
          value,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get followRedirects => (super.noSuchMethod(
        Invocation.getter(#followRedirects),
        returnValue: false,
      ) as bool);
  @override
  set followRedirects(bool? value) => super.noSuchMethod(
        Invocation.setter(
          #followRedirects,
          value,
        ),
        returnValueForMissingStub: null,
      );
  @override
  int get maxRedirects => (super.noSuchMethod(
        Invocation.getter(#maxRedirects),
        returnValue: 0,
      ) as int);
  @override
  set maxRedirects(int? value) => super.noSuchMethod(
        Invocation.setter(
          #maxRedirects,
          value,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get finalized => (super.noSuchMethod(
        Invocation.getter(#finalized),
        returnValue: false,
      ) as bool);
  @override
  _i4.ByteStream finalize() => (super.noSuchMethod(
        Invocation.method(
          #finalize,
          [],
        ),
        returnValue: _i5.dummyValue<_i4.ByteStream>(
          this,
          Invocation.method(
            #finalize,
            [],
          ),
        ),
      ) as _i4.ByteStream);
  @override
  _i6.Future<_i2.StreamedResponse> send() => (super.noSuchMethod(
        Invocation.method(
          #send,
          [],
        ),
        returnValue:
            _i6.Future<_i2.StreamedResponse>.value(_FakeStreamedResponse_1(
          this,
          Invocation.method(
            #send,
            [],
          ),
        )),
      ) as _i6.Future<_i2.StreamedResponse>);
}

/// A class which mocks [ImageFilePicker].
///
/// See the documentation for Mockito's code generation for more information.
class MockImageFilePicker extends _i1.Mock implements _i7.ImageFilePicker {
  MockImageFilePicker() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i6.Future<_i8.FilePickerResult?> pickImage() => (super.noSuchMethod(
        Invocation.method(
          #pickImage,
          [],
        ),
        returnValue: _i6.Future<_i8.FilePickerResult?>.value(),
      ) as _i6.Future<_i8.FilePickerResult?>);
}
