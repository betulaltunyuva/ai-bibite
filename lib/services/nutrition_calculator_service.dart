class NutritionCalculatorService {
  /// VKİ (Vücut Kitle Endeksi) hesaplama
  static double? calculateBMI(int? height, int? weight) {
    if (height == null || weight == null || height <= 0 || weight <= 0) {
      return null;
    }
    // VKİ = kilo / (boy/100)^2
    final heightInMeters = height / 100.0;
    return weight / (heightInMeters * heightInMeters);
  }

  /// TDEE (Total Daily Energy Expenditure) hesaplama - VKİ bazlı
  static int calculateTDEE({
    required String? gender,
    required int? age,
    required int? height, // cm
    required int? weight, // kg
    required String? activityLevel,
    required String? goal,
  }) {
    // Eksik veri kontrolü
    if (age == null || height == null || weight == null || 
        activityLevel == null || goal == null) {
      return 2000; // Varsayılan değer
    }

    // VKİ hesapla
    final bmi = calculateBMI(height, weight);
    
    // BMR (Basal Metabolic Rate) hesaplama - Mifflin-St Jeor formülü
    double bmr;
    if (gender?.toLowerCase() == 'erkek' || gender?.toLowerCase() == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    // VKİ'ye göre BMR ayarlama (VKİ yüksekse metabolizma daha yavaş olabilir)
    if (bmi != null) {
      if (bmi > 30) {
        // Obezite durumunda BMR'yi %5 azalt
        bmr *= 0.95;
      } else if (bmi < 18.5) {
        // Zayıflık durumunda BMR'yi %3 artır
        bmr *= 1.03;
      }
    }

    // Aktivite seviyesine göre çarpan
    double activityMultiplier = _getActivityMultiplier(activityLevel);

    // TDEE hesaplama
    double tdee = bmr * activityMultiplier;

    // Hedefe göre ayarlama
    double adjustedCalories = _adjustForGoal(tdee, goal);

    return adjustedCalories.round();
  }

  /// Aktivite seviyesine göre çarpan
  static double _getActivityMultiplier(String activityLevel) {
    switch (activityLevel) {
      case 'Hareketsiz':
        return 1.2;
      case 'Az Aktif (Haftada 1-3 gün)':
        return 1.375;
      case 'Orta Aktif (Haftada 3-5 gün)':
        return 1.55;
      case 'Aktif (Haftada 6-7 gün)':
        return 1.725;
      case 'Çok Aktif (Günde 2+ kez)':
        return 1.9;
      default:
        return 1.375; // Varsayılan: Az Aktif
    }
  }

  /// Hedefe göre kalori ayarlama
  static double _adjustForGoal(double tdee, String goal) {
    switch (goal) {
      case 'Kilo Vermek':
        return tdee - 500; // 500 kcal açık
      case 'Kilo Almak':
        return tdee + 500; // 500 kcal fazla
      case 'Kilo Koruma':
        return tdee; // Aynı kalori
      case 'Kas Yapmak':
        return tdee + 300; // 300 kcal fazla
      default:
        return tdee; // Varsayılan: Koruma
    }
  }

  /// Protein hesaplama (kilo × 1.6)
  static int calculateProtein(int? weight) {
    if (weight == null || weight <= 0) return 80; // Varsayılan
    return (weight * 1.6).round();
  }

  /// Yağ hesaplama (toplam kalorinin %25'i / 9)
  static int calculateFat(int totalCalories) {
    double fatCalories = totalCalories * 0.25;
    return (fatCalories / 9).round();
  }

  /// Karbonhidrat hesaplama (kalan kaloriler / 4)
  static int calculateCarbs(int totalCalories, int protein, int fat) {
    // Protein kalorisi = protein × 4
    int proteinCalories = protein * 4;
    // Yağ kalorisi = yağ × 9
    int fatCalories = fat * 9;
    // Kalan kalori = toplam - protein - yağ
    int remainingCalories = totalCalories - proteinCalories - fatCalories;
    // Karbonhidrat = kalan kalori / 4
    return (remainingCalories / 4).round();
  }

  /// Yaş hesaplama (doğum yılından)
  static int? calculateAge(int? birthYear) {
    if (birthYear == null) return null;
    return DateTime.now().year - birthYear;
  }
}


