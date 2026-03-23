import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const _kFontSize = 'reader_font_size';
  static const _kLineHeight = 'reader_line_height';
  static const _kLetterSpacing = 'reader_letter_spacing';
  static const _kFontFamily = 'reader_font_family';

  Future<void> saveReadingSettings({
    required double fontSize,
    required double lineHeight,
    required double letterSpacing,
    required String fontFamily,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontSize, fontSize);
    await prefs.setDouble(_kLineHeight, lineHeight);
    await prefs.setDouble(_kLetterSpacing, letterSpacing);
    await prefs.setString(_kFontFamily, fontFamily);
  }

  Future<Map<String, dynamic>> getReadingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fontSize': prefs.getDouble(_kFontSize) ?? 18,
      'lineHeight': prefs.getDouble(_kLineHeight) ?? 1.8,
      'letterSpacing': prefs.getDouble(_kLetterSpacing) ?? 0,
      'fontFamily': prefs.getString(_kFontFamily) ?? 'serif',
    };
  }
}
