import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_settings.dart';

class LocalStore {
  static const _kFontSize = 'reader_font_size';
  static const _kLineHeight = 'reader_line_height';
  static const _kLetterSpacing = 'reader_letter_spacing';
  static const _kFontFamily = 'reader_font_family';
  static const _kThemePreset = 'reader_theme_preset';
  static const _kBackgroundColor = 'reader_background_color';
  static const _kTextColor = 'reader_text_color';
  static const _kHorizontalPadding = 'reader_horizontal_padding';
  static const _kParagraphSpacing = 'reader_paragraph_spacing';
  static const _kTextAlign = 'reader_text_align';
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
    await prefs.setString(_kThemePreset, settings.themePreset);
    await prefs.setInt(_kBackgroundColor, settings.backgroundColorValue);
    await prefs.setInt(_kTextColor, settings.textColorValue);
    await prefs.setDouble(_kHorizontalPadding, settings.horizontalPadding);
    await prefs.setDouble(_kParagraphSpacing, settings.paragraphSpacing);
    await prefs.setString(_kTextAlign, settings.textAlign);
  }

  Future<ReadingSettings?> loadReadingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kFontSize)) return null;
    final themePreset = prefs.getString(_kThemePreset) ?? 'paper';
    final fallbackBackground = switch (themePreset) {
      'night' => 0xFF101418,
      'sepia' => 0xFFF6EAD7,
      _ => 0xFFFFFEF8,
    };
    final fallbackText = switch (themePreset) {
      'night' => 0xFFE6EAF2,
      'sepia' => 0xFF3B2F23,
      _ => 0xFF111111,
    };

    return ReadingSettings(
      fontSize: prefs.getDouble(_kFontSize) ?? 18,
      lineHeight: prefs.getDouble(_kLineHeight) ?? 1.8,
      letterSpacing: prefs.getDouble(_kLetterSpacing) ?? 0,
      fontFamily: prefs.getString(_kFontFamily) ?? 'serif',
      themePreset: themePreset,
      backgroundColorValue: prefs.getInt(_kBackgroundColor) ?? fallbackBackground,
      textColorValue: prefs.getInt(_kTextColor) ?? fallbackText,
      horizontalPadding: prefs.getDouble(_kHorizontalPadding) ?? 20,
      paragraphSpacing: prefs.getDouble(_kParagraphSpacing) ?? 24,
      textAlign: prefs.getString(_kTextAlign) ?? 'left',
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
