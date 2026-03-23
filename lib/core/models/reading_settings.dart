class ReadingSettings {
  const ReadingSettings({
    this.fontSize = 18,
    this.lineHeight = 1.8,
    this.letterSpacing = 0,
    this.fontFamily = 'serif',
  });

  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final String fontFamily;

  ReadingSettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? letterSpacing,
    String? fontFamily,
  }) =>
      ReadingSettings(
        fontSize: fontSize ?? this.fontSize,
        lineHeight: lineHeight ?? this.lineHeight,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        fontFamily: fontFamily ?? this.fontFamily,
      );

  factory ReadingSettings.fromJson(Map<String, dynamic> json) => ReadingSettings(
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
        lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.8,
        letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0,
        fontFamily: json['fontFamily'] as String? ?? 'serif',
      );

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'lineHeight': lineHeight,
        'letterSpacing': letterSpacing,
        'fontFamily': fontFamily,
      };
}
