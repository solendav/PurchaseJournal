import 'dart:typed_data';

import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart'
    if (dart.library.io) 'file_download_io.dart';

Future<void> downloadFile({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
  String? subject,
}) {
  return downloadFileImpl(
    bytes: bytes,
    filename: filename,
    mimeType: mimeType,
    subject: subject,
  );
}
