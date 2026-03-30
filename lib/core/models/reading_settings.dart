class ReadingSettings {
  const ReadingSettings({
    this.fontSize = 18,
    this.lineHeight = 1.8,
    this.letterSpacing = 0,
    this.fontFamily = 'serif',
    this.themePreset = 'paper',
    this.horizontalPadding = 20,
    this.paragraphSpacing = 24,
    this.textAlign = 'justify',
  });

  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final String fontFamily;
  final String themePreset;
  final double horizontalPadding;
  final double paragraphSpacing;
  final String textAlign;

  ReadingSettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? letterSpacing,
    String? fontFamily,
    String? themePreset,
    double? horizontalPadding,
    double? paragraphSpacing,
    String? textAlign,
  }) =>
      ReadingSettings(
        fontSize: fontSize ?? this.fontSize,
        lineHeight: lineHeight ?? this.lineHeight,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        fontFamily: fontFamily ?? this.fontFamily,
        themePreset: themePreset ?? this.themePreset,
        horizontalPadding: horizontalPadding ?? this.horizontalPadding,
        paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
        textAlign: textAlign ?? this.textAlign,
      );

  factory ReadingSettings.fromJson(Map<String, dynamic> json) => ReadingSettings(
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
        lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.8,
        letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0,
        fontFamily: json['fontFamily'] as String? ?? 'serif',
        themePreset: json['themePreset'] as String? ?? 'paper',
        horizontalPadding: (json['horizontalPadding'] as num?)?.toDouble() ?? 20,
        paragraphSpacing: (json['paragraphSpacing'] as num?)?.toDouble() ?? 24,
        textAlign: json['textAlign'] as String? ?? 'justify',
      );

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'lineHeight': lineHeight,
        'letterSpacing': letterSpacing,
        'fontFamily': fontFamily,
        'themePreset': themePreset,
        'horizontalPadding': horizontalPadding,
        'paragraphSpacing': paragraphSpacing,
        'textAlign': textAlign,
      };
}
