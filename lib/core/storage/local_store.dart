import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_settings.dart';

class LocalStore {
  static const _kFontSize = 'reader_font_size';
  static const _kLineHeight = 'reader_line_height';
  static const _kLetterSpacing = 'reader_letter_spacing';
  static const _kFontFamily = 'reader_font_family';
  static const _kProgressChapterId = 'progress_chapter_id_';
  static const _kProgressChapterNum = 'progress_chapter_num_';
  static const _kProgressOffset = 'progress_offset_';

  // ── Reading settings ──────────────────────────────────────────────────────

  Future<void> saveReadingSettings(ReadingSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontSize, settings.fontSize);
    await prefs.setDouble(_kLineHeight, settings.lineHeight);
    await prefs.setDouble(_kLetterSpacing, settings.letterSpacing);
    await prefs.setString(_kFontFamily, settings.fontFamily);
  }

  Future<ReadingSettings?> loadReadingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kFontSize)) return null;
    return ReadingSettings(
      fontSize: prefs.getDouble(_kFontSize) ?? 18,
      lineHeight: prefs.getDouble(_kLineHeight) ?? 1.8,
      letterSpacing: prefs.getDouble(_kLetterSpacing) ?? 0,
      fontFamily: prefs.getString(_kFontFamily) ?? 'serif',
    );
  }

  // ── Reading progress ──────────────────────────────────────────────────────

  Future<void> saveProgress(
    String novelId,
    String chapterId,
    int chapterNumber,
    double offset,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kProgressChapterId$novelId', chapterId);
    await prefs.setInt('$_kProgressChapterNum$novelId', chapterNumber);
    await prefs.setDouble('$_kProgressOffset$novelId', offset);
  }

  Future<Map<String, dynamic>?> loadProgress(String novelId) async {
    final prefs = await SharedPreferences.getInstance();
    final chapterId = prefs.getString('$_kProgressChapterId$novelId');
    if (chapterId == null) return null;
    return {
      'chapterId': chapterId,
      'chapterNumber': prefs.getInt('$_kProgressChapterNum$novelId') ?? 1,
      'scrollOffset': prefs.getDouble('$_kProgressOffset$novelId') ?? 0.0,
    };
  }
}

final localStoreProvider = Provider<LocalStore>((_) => LocalStore());
