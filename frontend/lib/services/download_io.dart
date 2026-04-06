import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Enregistre le CSV sur le système de fichiers (mobile / desktop).
Future<String?> saveCsvToDevice(Uint8List bytes, String fileName) async {
  final safeName = fileName.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');

  if (Platform.isAndroid) {
    await Permission.storage.request();
    final publicDownload = Directory('/storage/emulated/0/Download');
    if (await publicDownload.exists()) {
      try {
        final path = '${publicDownload.path}/$safeName';
        await File(path).writeAsBytes(bytes, flush: true);
        return path;
      } catch (_) {
        /* dossier app si accès refusé (scoped storage) */
      }
    }
  }

  Directory? directory;
  if (Platform.isAndroid) {
    directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
  } else if (Platform.isIOS) {
    directory = await getApplicationDocumentsDirectory();
  } else {
    directory = await getDownloadsDirectory();
    directory ??= await getApplicationDocumentsDirectory();
  }

  final path = '${directory.path}/$safeName';
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}
