import 'package:flutter/material.dart';

/// Öğünler ekranı için pastel renk teması
class MealsTheme {
  // Arka plan renkleri
  static const Color background = Color(0xFFF7F8FC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE8EAF2);
  
  // Metin renkleri
  static const Color titleText = Color(0xFF1F2430);
  static const Color descriptionText = Color(0xFF6B7280);
  
  // Input renkleri
  static const Color inputBackground = Color(0xFFF3F4F6);
  
  // Primary renkler
  static const Color primary = Color(0xFF2F6F5B);
  static const Color primaryHover = Color(0xFF2A6452);
  
  // Secondary renkler
  static const Color secondaryBorder = Color(0xFFBFD8CF);
  static const Color secondaryText = Color(0xFF2F6F5B);
  
  // Öğün aksan renkleri (pastel)
  static const Color accentMorning = Color(0xFFFFE8B6); // Pastel sarı
  static const Color accentLunch = Color(0xFFFFD6D6);   // Pastel pembe
  static const Color accentDinner = Color(0xFFE6E1FF);  // Pastel lavanta
  
  // Banner renkleri (pastel mint)
  static const Color bannerBackground = Color(0xFFEAF7F1);
  static const Color bannerBorder = Color(0xFFCFEBDD);
  static const Color bannerIcon = Color(0xFF2F6F5B);
  
  // Gölge
  static BoxShadow get softShadow => BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 8,
    offset: const Offset(0, 2),
    spreadRadius: 0,
  );
  
  static BoxShadow get cardShadow => BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 12,
    offset: const Offset(0, 4),
    spreadRadius: 0,
  );
}


