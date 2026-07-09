import 'dart:typed_data';

Future<void> downloadFileImpl({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
  String? subject,
}) {
  throw UnsupportedError('File download is not supported on this platform');
}
