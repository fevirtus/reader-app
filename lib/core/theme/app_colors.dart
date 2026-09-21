import 'package:flutter/material.dart';

/// Warm paper surfaces with a forest-green accent, shared by light and dark UI.
class AppColors {
  AppColors._();

  // ── Accent (màu nhấn duy nhất) ──────────────────────────────────────────
  static const lightAccent = Color(0xFF246451);
  static const darkAccent = Color(0xFF94D5B6);
  static const lightOnAccent = Color(0xFFFFFFFF);
  static const darkOnAccent = Color(0xFF103C2E);
  // Nền nút bấm filled ở dark mode dùng tông đậm hơn accent-text để chữ trắng đủ tương phản.
  static const darkAccentContainer = Color(0xFF246451);

  // ── Trung tính  ───────────────────────────────────────────────────
  static const lightBackground = Color(0xFFF8F7F3);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceLow = Color(0xFFF0EFE9);
  static const lightSurfaceHigh = Color(0xFFE8E7DF);
  static const lightOutline = Color(0xFFDADDD5);
  static const lightOutlineVariant = Color(0xFFE8EAE3);
  static const lightOnSurface = Color(0xFF1D2924);
  static const lightOnSurfaceVariant = Color(0xFF65716A);

  static const darkBackground = Color(0xFF101713);
  static const darkSurface = Color(0xFF1D2924);
  static const darkSurfaceLow = Color(0xFF19231D);
  static const darkSurfaceHigh = Color(0xFF2A362F);
  static const darkOutline = Color(0xFF47564C);
  static const darkOutlineVariant = Color(0xFF2A362F);
  static const darkOnSurface = Color(0xFFF8F7F3);
  static const darkOnSurfaceVariant = Color(0xFFADBAB0);

  // ── Ngữ nghĩa (dùng tiết chế, không phải màu nhấn) ───────────────────────
  static const lightSuccess = Color(0xFF16A34A);
  static const darkSuccess = Color(0xFF4ADE80);
  static const lightWarning = Color(0xFFB45309);
  static const darkWarning = Color(0xFFFBBF24);
  static const lightError = Color(0xFFDC2626);
  static const darkError = Color(0xFFF87171);
}
