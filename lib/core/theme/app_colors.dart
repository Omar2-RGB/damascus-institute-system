import 'package:flutter/material.dart';

class AppColors {
  // --- 1. Brand Colors (ألوان الهوية الرسمية) ---
  static const Color primary       = Color(0xFF2563EB); // Royal Blue (جامعة دمشق)
  static const Color primaryDark   = Color(0xFF3B82F6); // Bright Neon Blue للدارك
  static const Color secondary     = Color(0xFF7C3AED); // Purple (للعلامات)
  static const Color accent        = Color(0xFF0D9488); // Teal (للإعلانات)

  // --- 2. Light Mode Palette ---
  static const Color lightBg       = Color(0xFFF8FAFC); // الرمادي الثلجي المريح
  static const Color lightSurface  = Colors.white;
  static const Color lightBorder   = Color(0xFFE2E8F0);
  static const Color lightTextDark = Color(0xFF0F172A);
  static const Color lightTextMuted= Color(0xFF64748B);

  // --- 3. Cinematic Dark Mode Palette (فخامة الأوبسيديان) ---
  static const Color darkBg        = Color(0xFF090D16); // كحلي أوبسيديان عميق جداً
  static const Color darkSurface   = Color(0xFF131C2E); // كرت كحلي زجاجي
  static const Color darkBorder    = Color(0xFF222F4A); // تحديد ناعم للكرت
  static const Color darkTextLight = Color(0xFFF8FAFC); // أبيض ناصع
  static const Color darkTextMuted = Color(0xFF94A3B8); // رمادي ليلي

  // --- 4. Dopamine Status Colors (ألوان الحالات الأكاديمية) ---
  static const Color success       = Color(0xFF10B981); // Emerald Green
  static const Color successBg     = Color(0xFFD1FAE5);
  static const Color warning       = Color(0xFFF59E0B); // Amber Glow
  static const Color warningBg     = Color(0xFFFEF3C7);
  static const Color danger        = Color(0xFFF43F5E); // Rose Neon
  static const Color dangerBg      = Color(0xFFFFE4E6);
}