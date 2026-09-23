import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader_app/features/audiobook/audio_book_migration.dart';

void main() {
  test(
    'retired audio is removed without touching text or other files',
    () async {
      final root = await Directory.systemTemp.createTemp('reader-migration-');
      try {
        await Directory(
          '${root.path}/audiobooks/edition',
        ).create(recursive: true);
        await File(
          '${root.path}/audiobooks/edition/audio.m4a',
        ).writeAsString('old audio');
        final text = await File(
          '${root.path}/text.sqlite',
        ).writeAsString('text download');
        await removeRetiredAudioDownloads(supportDirectory: root);
        await removeRetiredAudioDownloads(supportDirectory: root);
        expect(await Directory('${root.path}/audiobooks').exists(), false);
        expect(await text.readAsString(), 'text download');
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
  test('cleanup never follows a linked directory', () async {
    final root = await Directory.systemTemp.createTemp('reader-migration-');
    final other = await Directory.systemTemp.createTemp('reader-other-');
    try {
      await File('${other.path}/keep').writeAsString('keep');
      await Link('${root.path}/audiobooks').create(other.path);
      await removeRetiredAudioDownloads(supportDirectory: root);
      expect(await File('${other.path}/keep').readAsString(), 'keep');
    } finally {
      await root.delete(recursive: true);
      await other.delete(recursive: true);
    }
  });
}
