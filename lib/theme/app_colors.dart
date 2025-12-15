import 'package:flutter/material.dart';

/// Uygulama genel renk teması - Logo yeşil rengine uygun
class AppColors {
  // Ana renkler (Logo referansı)
  static const Color primaryGreen = Color(0xFF2F6F3E); // Ana yeşil
  static const Color secondaryGreen = Color(0xFFEAF5EE); // Soft yeşil
  
  // Arka plan renkleri (Light Mode)
  static const Color background = Color(0xFFF6FBF8); // Ana arka plan
  static const Color cardBackground = Color(0xFFFFFFFF); // Kart arka planı
  static const Color borderDivider = Color(0xFFE2EFE7); // Border / divider
  
  // Arka plan renkleri (Dark Mode)
  static const Color backgroundDark = Color(0xFF1A1F1C); // Dark arka plan
  static const Color cardBackgroundDark = Color(0xFF2A2F2C); // Dark kart arka planı
  static const Color borderDividerDark = Color(0xFF3A3F3C); // Dark border / divider
  
  // Metin renkleri (Light Mode)
  static const Color primaryText = Color(0xFF1F2D24); // Ana metin
  static const Color secondaryText = Color(0xFF6B7F74); // İkincil metin
  
  // Metin renkleri (Dark Mode)
  static const Color primaryTextDark = Color(0xFFE8F0E8); // Dark ana metin
  static const Color secondaryTextDark = Color(0xFFB0B8B4); // Dark ikincil metin
  
  // Context-aware getters
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? backgroundDark 
        : background;
  }
  
  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? cardBackgroundDark 
        : cardBackground;
  }
  
  static Color getBorderDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? borderDividerDark 
        : borderDivider;
  }
  
  static Color getPrimaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? primaryTextDark 
        : primaryText;
  }
  
  static Color getSecondaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? secondaryTextDark 
        : secondaryText;
  }
  
  // Progress bar renkleri
  static const Color progressFilled = Color(0xFFCFF0DA); // Dolu kısım
  static const Color progressEmpty = Color(0x80FFFFFF); // Boş kısım (yarı transparan beyaz)
  
  // Aksan renkleri (Yemek ekle butonları için)
  static const Color accentCamera = Color(0xFF2F6F3E); // Kamera - yeşil
  static const Color accentGallery = Color(0xFFB3E5FC); // Galeri - açık mavi
  static const Color accentBarcode = Color(0xFFFFF9C4); // Barkod - pastel sarı
  static const Color accentManual = Color(0xFFE1BEE7); // Manuel - pastel mor
  
  // Su takibi renkleri
  static const Color waterFilled = Color(0xFFB3E5FC); // Dolu damla - açık mavi
  static const Color waterEmpty = Color(0xFFE0E0E0); // Boş damla - açık gri
  
  // Gölgeler
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
  
  // Bottom navigation
  static const Color navActive = Color(0xFF2F6F3E); // Aktif ikon
  static const Color navInactive = Color(0xFF9E9E9E); // Pasif ikon
}

