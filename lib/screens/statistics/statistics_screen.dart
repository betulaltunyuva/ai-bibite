import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../widgets/weekly_calorie_chart.dart';
import '../../widgets/weekly_macro_chart.dart';
import '../../services/supabase_helper.dart';
import '../../services/nutrition_calculator_service.dart';

/// İstatistik sayfası - Haftalık kalori ve makro besin grafikleri
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final supabase = Supabase.instance.client;
  final SupabaseHelper _supabaseHelper = SupabaseHelper();
  final Color _mintColor = const Color(0xFF2E7D32);

  // Haftalık veriler
  List<Map<String, dynamic>> _weeklyCalorieData = [];
  List<Map<String, dynamic>> _weeklyMacroData = [];
  bool _loading = true;
  int? _targetCalories;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  /// Türkçe locale verilerini başlat
  Future<void> _initializeLocale() async {
    await initializeDateFormatting('tr_TR', null);
    _loadProfileAndCalculate();
    _loadWeeklyData();
  }

  /// Profil verilerini yükle ve hedef kaloriyi hesapla
  Future<void> _loadProfileAndCalculate() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profile = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle(),
      );

      if (profile != null && mounted) {
        final gender = profile['gender'] as String?;
        final birthYear = profile['birth_year'] as int?;
        final height = profile['height'] as int?;
        final weight = profile['weight'] as int?;
        final activityLevel = profile['activity_level'] as String?;
        final goal = profile['goal'] as String?;

        if (weight != null && height != null && birthYear != null) {
          final age = NutritionCalculatorService.calculateAge(birthYear);
          final targetCalories = NutritionCalculatorService.calculateTDEE(
            gender: gender ?? 'Erkek',
            age: age,
            height: height,
            weight: weight,
            activityLevel: activityLevel ?? 'Hafif',
            goal: goal ?? 'Kilo Koruma',
          );

          setState(() {
            _targetCalories = targetCalories;
          });
        }
      }
    } catch (e) {
      // Sessiz hata yönetimi
    }
  }

  /// Son 7 günün verilerini yükle
  Future<void> _loadWeeklyData() async {
    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _weeklyCalorieData = [];
          _weeklyMacroData = [];
          _loading = false;
        });
        return;
      }

      // Son 7 günün tarihlerini oluştur
      final now = DateTime.now();
      final List<DateTime> weekDates = [];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        weekDates.add(date);
      }

      // Her gün için verileri çek
      final List<Map<String, dynamic>> calorieData = [];
      final List<Map<String, dynamic>> macroData = [];

      for (final date in weekDates) {
        final dateStr = DateFormat("yyyy-MM-dd").format(date);
        
        // O günün tüm yemek kayıtlarını çek
        final result = await _supabaseHelper.executeQuerySilent(
          () => supabase
              .from('meals_history')
              .select('calories, protein, carbs, fat')
              .eq('user_id', user.id)
              .gte('date', '${dateStr}T00:00:00Z')
              .lte('date', '${dateStr}T23:59:59Z'),
        );

        if (result != null) {
          final meals = result as List<dynamic>;
          
          // Günlük toplamları hesapla
          int totalCalories = 0;
          double totalProtein = 0;
          double totalCarbohydrate = 0;
          double totalFat = 0;

          for (var meal in meals) {
            final mealMap = meal as Map<String, dynamic>;
            totalCalories += (mealMap['calories'] as num?)?.toInt() ?? 0;
            totalProtein += (mealMap['protein'] as num?)?.toDouble() ?? 0;
            totalCarbohydrate += (mealMap['carbs'] as num?)?.toDouble() ?? 0;
            totalFat += (mealMap['fat'] as num?)?.toDouble() ?? 0;
          }

          calorieData.add({
            'date': date,
            'calories': totalCalories,
          });

          macroData.add({
            'date': date,
            'protein': totalProtein,
            'carbohydrate': totalCarbohydrate,
            'fat': totalFat,
          });
        } else {
          // Veri yoksa 0 değerleri ekle
          calorieData.add({
            'date': date,
            'calories': 0,
          });

          macroData.add({
            'date': date,
            'protein': 0.0,
            'carbohydrate': 0.0,
            'fat': 0.0,
          });
        }
      }

      if (mounted) {
        setState(() {
          _weeklyCalorieData = calorieData;
          _weeklyMacroData = macroData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weeklyCalorieData = [];
          _weeklyMacroData = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _mintColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'İstatistik',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _mintColor),
            onPressed: () {
              _loadProfileAndCalculate();
              _loadWeeklyData();
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _loadProfileAndCalculate();
                await _loadWeeklyData();
              },
              color: _mintColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Haftalık Kalori Grafiği
                    WeeklyCalorieChart(
                      weeklyData: _weeklyCalorieData,
                      targetCalories: _targetCalories,
                    ),
                    const SizedBox(height: 20),
                    // Haftalık Makro Grafiği
                    WeeklyMacroChart(
                      weeklyData: _weeklyMacroData,
                    ),
                    const SizedBox(height: 20),
                    // Bilgi kartı
                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Bilgi kartı widget'ı
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _mintColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: _mintColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Bilgi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Grafikler son 7 günün verilerini gösterir.\n'
            '• Kalori grafiğinde yeşil çubuklar günlük hedefi gösterir.\n'
            '• Makro grafiğinde protein (pembe), karbonhidrat (sarı) ve yağ (mavi) gösterilir.\n'
            '• Veriler yemek kayıtlarınızdan otomatik olarak hesaplanır.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

