import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Remove only V2's retired download directory. Text downloads and progress
/// preferences belong to separate stores and are deliberately untouched.
Future<void> removeRetiredAudioDownloads({Directory? supportDirectory}) async {
  final base = supportDirectory ?? await getApplicationSupportDirectory();
  final path = '${base.path}/audiobooks';
  final kind = await FileSystemEntity.type(path, followLinks: false);
  if (kind == FileSystemEntityType.directory) {
    await Directory(path).delete(recursive: true);
  } else if (kind == FileSystemEntityType.link) {
    await Link(path).delete();
  }
}
