import 'package:flutter/material.dart';

/// Token màu cho phong cách "tối giản đơn sắc + một màu nhấn": nền/chữ luôn
/// là thang xám trung tính (zinc), chỉ duy nhất [lightAccent]/[darkAccent]
/// (indigo) mang màu — dùng cho nút bấm, trạng thái đang chọn, liên kết.
/// Light và dark được thiết kế ngang hàng nhau, không ưu tiên bên nào.
class AppColors {
  AppColors._();

  // ── Accent (màu nhấn duy nhất) ──────────────────────────────────────────
  static const lightAccent = Color(0xFF4F46E5); // indigo-600, đủ tương phản trên nền trắng
  static const darkAccent = Color(0xFF818CF8); // indigo-400, đủ tương phản trên nền tối
  static const lightOnAccent = Color(0xFFFFFFFF);
  static const darkOnAccent = Color(0xFF1E1B4B);
  // Nền nút bấm filled ở dark mode dùng tông đậm hơn accent-text để chữ trắng đủ tương phản.
  static const darkAccentContainer = Color(0xFF4F46E5);

  // ── Trung tính (zinc) ───────────────────────────────────────────────────
  static const lightBackground = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceLow = Color(0xFFF4F4F5);
  static const lightSurfaceHigh = Color(0xFFECECEE);
  static const lightOutline = Color(0xFFE4E4E7);
  static const lightOutlineVariant = Color(0xFFF0F0F1);
  static const lightOnSurface = Color(0xFF18181B);
  static const lightOnSurfaceVariant = Color(0xFF71717A);

  static const darkBackground = Color(0xFF09090B);
  static const darkSurface = Color(0xFF18181B);
  static const darkSurfaceLow = Color(0xFF141416);
  static const darkSurfaceHigh = Color(0xFF27272A);
  static const darkOutline = Color(0xFF3F3F46);
  static const darkOutlineVariant = Color(0xFF27272A);
  static const darkOnSurface = Color(0xFFFAFAFA);
  static const darkOnSurfaceVariant = Color(0xFFA1A1AA);

  // ── Ngữ nghĩa (dùng tiết chế, không phải màu nhấn) ───────────────────────
  static const lightSuccess = Color(0xFF16A34A);
  static const darkSuccess = Color(0xFF4ADE80);
  static const lightWarning = Color(0xFFB45309);
  static const darkWarning = Color(0xFFFBBF24);
  static const lightError = Color(0xFFDC2626);
  static const darkError = Color(0xFFF87171);
}
