import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'supabase_helper.dart';

/// Yüz ifadesi tipleri
enum MoodType {
  veryHappy,   // Çok mutlu / gülen yüz (80-100 puan)
  happy,       // Hafif mutlu yüz (60-79 puan)
  neutral,     // Tepkisiz / nötr yüz (40-59 puan)
  sad,         // Üzgün yüz (0-39 puan)
}

/// Kullanıcı ruh hali/yüz ifadesi servisi
/// Kullanıcının davranışlarına göre skor hesaplar ve yüz ifadesi belirler
class UserMoodService {
  final supabase = Supabase.instance.client;
  final SupabaseHelper _supabaseHelper = SupabaseHelper();

  /// Kullanıcının mevcut skorunu hesapla ve yüz ifadesi döndür
  Future<MoodType> getUserMood(String? userId) async {
    if (userId == null) return MoodType.neutral;

    try {
      final score = await _calculateUserScore(userId);
      return _scoreToMood(score);
    } catch (e) {
      print('Error calculating user mood: $e');
      return MoodType.neutral;
    }
  }

  /// Kullanıcı skorunu hesapla (0-100 arası)
  Future<int> _calculateUserScore(String userId) async {
    int score = 50; // Başlangıç skoru (nötr)

    // Son 30 günlük verileri al
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final dateStr = DateFormat("yyyy-MM-dd").format(thirtyDaysAgo);

    try {
      // 1. Düzenli kullanım puanı (son 7 günde günlük aktivite)
      final recentActivity = await _getRecentActivity(userId, dateStr);
      score += recentActivity;

      // 2. Sağlıklı yemek puanı (health_score'a göre)
      final healthyMealsScore = await _getHealthyMealsScore(userId, dateStr);
      score += healthyMealsScore;

      // 3. Hedef kalori takibi puanı
      final calorieTrackingScore = await _getCalorieTrackingScore(userId, dateStr);
      score += calorieTrackingScore;

      // 4. Uzun süre kullanılmama cezası
      final inactivityPenalty = await _getInactivityPenalty(userId);
      score -= inactivityPenalty;

      // Skoru 0-100 aralığına sınırla
      return score.clamp(0, 100);
    } catch (e) {
      print('Error calculating score: $e');
      return 50; // Hata durumunda nötr döndür
    }
  }

  /// Son 7 günde düzenli kullanım puanı (0-20 puan)
  Future<int> _getRecentActivity(String userId, String dateStr) async {
    try {
      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('daily_meals')
            .select('date')
            .eq('user_id', userId)
            .gte('date', dateStr)
            .order('date', ascending: false),
      );

      if (result == null) return 0;

      final dates = (result as List).map((e) => e['date'] as String).toSet();
      final uniqueDays = dates.length;

      // Son 7 günde kaç gün aktif kullanım var?
      if (uniqueDays >= 7) return 20;
      if (uniqueDays >= 5) return 15;
      if (uniqueDays >= 3) return 10;
      if (uniqueDays >= 1) return 5;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Sağlıklı yemek puanı (0-30 puan)
  Future<int> _getHealthyMealsScore(String userId, String dateStr) async {
    try {
      // diary tablosundan health_score'ları al
      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('diary')
            .select('summary')
            .eq('user_id', userId)
            .gte('created_at', '${dateStr}T00:00:00Z')
            .order('created_at', ascending: false)
            .limit(20), // Son 20 kayıt
      );

      if (result == null || (result as List).isEmpty) return 0;

      int totalScore = 0;
      int count = 0;

      // Summary'den health_score çıkarmaya çalış (eğer varsa)
      // Şimdilik basit bir yaklaşım: sağlıklı kelimeler varsa puan ver
      for (var entry in result) {
        final summary = entry['summary'] as String? ?? '';
        if (summary.toLowerCase().contains('sağlıklı') ||
            summary.toLowerCase().contains('iyi') ||
            summary.toLowerCase().contains('faydalı')) {
          totalScore += 10;
        } else if (summary.toLowerCase().contains('dikkat') ||
            summary.toLowerCase().contains('azalt')) {
          totalScore -= 5;
        }
        count++;
      }

      if (count == 0) return 0;
      final avgScore = (totalScore / count).round();
      return avgScore.clamp(0, 30);
    } catch (e) {
      return 0;
    }
  }

  /// Kalori takibi puanı (0-20 puan)
  Future<int> _getCalorieTrackingScore(String userId, String dateStr) async {
    try {
      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('daily_meals')
            .select('date')
            .eq('user_id', userId)
            .gte('date', dateStr),
      );

      if (result == null) return 0;

      final uniqueDays = (result as List).map((e) => e['date'] as String).toSet().length;
      
      // 30 günde kaç gün yemek eklenmiş?
      if (uniqueDays >= 20) return 20;
      if (uniqueDays >= 15) return 15;
      if (uniqueDays >= 10) return 10;
      if (uniqueDays >= 5) return 5;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Uzun süre kullanılmama cezası (0-20 puan düşüş)
  Future<int> _getInactivityPenalty(String userId) async {
    try {
      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('daily_meals')
            .select('date')
            .eq('user_id', userId)
            .order('date', ascending: false)
            .limit(1),
      );

      if (result == null || (result as List).isEmpty) return 20; // Hiç kayıt yoksa ceza

      final lastDateStr = result[0]['date'] as String?;
      if (lastDateStr == null) return 20;

      final lastDate = DateFormat("yyyy-MM-dd").parse(lastDateStr);
      final daysSinceLastUse = DateTime.now().difference(lastDate).inDays;

      if (daysSinceLastUse >= 14) return 20; // 14+ gün kullanılmamış
      if (daysSinceLastUse >= 7) return 15;
      if (daysSinceLastUse >= 3) return 10;
      if (daysSinceLastUse >= 1) return 5;
      return 0; // Son 24 saatte kullanılmış
    } catch (e) {
      return 0;
    }
  }

  /// Skoru yüz ifadesine çevir
  MoodType _scoreToMood(int score) {
    if (score >= 80) return MoodType.veryHappy;
    if (score >= 60) return MoodType.happy;
    if (score >= 40) return MoodType.neutral;
    return MoodType.sad;
  }

  /// Yüz ifadesi için emoji/ikon döndür
  static String getMoodEmoji(MoodType mood) {
    switch (mood) {
      case MoodType.veryHappy:
        return '😄'; // Çok mutlu
      case MoodType.happy:
        return '🙂'; // Hafif mutlu
      case MoodType.neutral:
        return '😐'; // Nötr
      case MoodType.sad:
        return '😔'; // Üzgün
    }
  }

  /// Yüz ifadesi için renk döndür
  static int getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.veryHappy:
        return 0xFFFFD700; // Altın sarısı
      case MoodType.happy:
        return 0xFF4CAF50; // Yeşil
      case MoodType.neutral:
        return 0xFF9E9E9E; // Gri
      case MoodType.sad:
        return 0xFFFF6B6B; // Açık kırmızı
    }
  }
}

