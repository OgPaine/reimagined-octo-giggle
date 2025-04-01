import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

Future<String> compressAndSaveImage(String imagePath) async {
  final dir = await getApplicationDocumentsDirectory();
  final targetPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

  final compressedFile = await FlutterImageCompress.compressAndGetFile(
    imagePath,
    targetPath,
    quality: 80,
    format: CompressFormat.jpeg,
  );

  if (compressedFile == null) {
    throw Exception("Image compression failed");
  }

  return compressedFile.path;
}

Future<void> deleteImageFile(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}
