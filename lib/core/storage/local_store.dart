import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_settings.dart';
import 'offline_store.dart';

class LocalStore {
  LocalStore({this.owner = 'guest', this.store});
  final OfflineStore? store;
  final String owner;
  static final Map<String, Future<void>> _writes = {};
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
  static const _kLastRoutePath = 'last_route_path';

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
      backgroundColorValue:
          prefs.getInt(_kBackgroundColor) ?? fallbackBackground,
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
  ) {
    if (store != null) {
      return store!.write(owner, 'progress:$novelId', {
        'chapterId': chapterId,
        'chapterNumber': chapterNumber,
        'scrollOffset': offset,
      });
    }
    final key = '$owner:$novelId';
    final task = (_writes[key] ?? Future<void>.value()).catchError((_) {}).then(
      (_) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          '$_kProgressChapterId${owner}_$novelId',
          chapterId,
        );
        await prefs.setInt(
          '$_kProgressChapterNum${owner}_$novelId',
          chapterNumber,
        );
        await prefs.setDouble('$_kProgressOffset${owner}_$novelId', offset);
      },
    );
    _writes[key] = task;
    return task.whenComplete(() {
      if (identical(_writes[key], task)) _writes.remove(key);
    });
  }

  Future<Map<String, dynamic>?> loadProgress(String novelId) async {
    if (store != null) {
      final data = await store!.read(owner, 'progress:$novelId');
      return data == null ? null : Map<String, dynamic>.from(data);
    }
    await _writes['$owner:$novelId'];
    final prefs = await SharedPreferences.getInstance();
    final chapterId = prefs.getString('$_kProgressChapterId${owner}_$novelId');
    if (chapterId == null) return null;
    return {
      'chapterId': chapterId,
      'chapterNumber':
          prefs.getInt('$_kProgressChapterNum${owner}_$novelId') ?? 1,
      'scrollOffset':
          prefs.getDouble('$_kProgressOffset${owner}_$novelId') ?? 0.0,
    };
  }

  // ── Last route restore (cold start after process reclaim) ───────────────

  Future<void> saveLastRoutePath(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty || normalized == '/') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastRoutePath, normalized);
  }

  Future<String?> loadLastRoutePath() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kLastRoutePath)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> clearLastRoutePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastRoutePath);
  }
}

final localStoreProvider = Provider<LocalStore>(
  (ref) => LocalStore(
    owner: ref.watch(currentUserProvider)?.id ?? 'guest',
    store: ref.watch(offlineStoreProvider),
  ),
);
