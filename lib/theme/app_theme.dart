import 'package:flutter/material.dart';

/// Tema aplikasi: hanya mengatur warna, tanpa tema tipografi / font.
class AppTheme {
  AppTheme._();

  /// Warna utama aplikasi (dipakai tombol, avatar, dll).
  static const Color warnaUtama = Color(0xFF1565C0);

  /// Warna latar belakang halaman.
  static const Color warnaLatar = Color(0xFFE3F2FD);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: warnaUtama,
        primary: warnaUtama,
      ),
      scaffoldBackgroundColor: warnaLatar,
    );
  }
}
