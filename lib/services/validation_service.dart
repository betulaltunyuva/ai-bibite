class ValidationService {
  /// Şifre doğrulama
  /// Kurallar:
  /// - En az 8 karakter
  /// - En az 1 büyük harf (A–Z)
  /// - En az 1 küçük harf (a–z)
  /// - En az 1 rakam (0–9)
  /// - Özel karakter zorunlu değil
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Şifre gereklidir';
    }

    // En az 8 karakter kontrolü
    if (password.length < 8) {
      return 'Şifre en az 8 karakter olmalıdır';
    }

    // Büyük harf kontrolü (A–Z)
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Şifre en az 1 büyük harf içermelidir';
    }

    // Küçük harf kontrolü (a–z)
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Şifre en az 1 küçük harf içermelidir';
    }

    // Rakam kontrolü (0–9)
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Şifre en az 1 rakam içermelidir';
    }

    // Tüm kurallar sağlandı
    return null;
  }

  /// Şifre doğrulama mesajı (kullanıcıya gösterilecek özet)
  static String getPasswordRequirements() {
    return 'Şifre en az 8 karakter olmalı, büyük harf, küçük harf ve rakam içermelidir';
  }
}


