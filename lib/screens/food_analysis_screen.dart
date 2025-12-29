import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/chat_service.dart';
import '../services/nutrition_calculator_service.dart';
import '../services/supabase_helper.dart';

class FoodAnalysisScreen extends StatefulWidget {
  final Map<String, dynamic> foodData;
  final File? imageFile;
  final String source; // 'camera', 'gallery', 'barcode', 'manual'

  const FoodAnalysisScreen({
    super.key,
    required this.foodData,
    this.imageFile,
    required this.source,
  });

  @override
  State<FoodAnalysisScreen> createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends State<FoodAnalysisScreen> {
  final supabase = Supabase.instance.client;
  final ChatService _chatService = ChatService();
  bool _saving = false;
  bool _loadingFunnyComment = false; // Esprili yorum yükleniyor mu
  final Color _mintColor = const Color(0xFF4CAF50); // Daha açık yeşil
  final Color _softGreen = const Color(0xFFE8F5E9); // Pastel yeşil
  final Color _softBlue = const Color(0xFFE3F2FD); // Pastel mavi
  final Color _softGrey = const Color(0xFFF5F5F5); // Açık gri
  int _dailyCalorieTarget = 2000; // Varsayılan, gerçekte Supabase'den gelecek
  int _targetWater = 8; // Günlük su hedefi (bardak)
  final SupabaseHelper _supabaseHelper = SupabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final profile = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle(),
      );

      // Profil verisi olsun veya olmasın, hesaplama yap
      final weight = profile?['weight'] as int?;
      final gender = profile?['gender'] as String?;
      final birthYear = profile?['birth_year'] as int?;
      final height = profile?['height'] as int?;
      final activityLevel = profile?['activity_level'] as String?;
      final goal = profile?['goal'] as String?;

      // Yaş hesapla
      final age = NutritionCalculatorService.calculateAge(birthYear);

      // TDEE hesapla (profil bilgileri eksik olsa bile hesaplama yapılır, varsayılan değerler kullanılır)
      final targetCalories = NutritionCalculatorService.calculateTDEE(
        gender: gender,
        age: age,
        height: height,
        weight: weight,
        activityLevel: activityLevel,
        goal: goal,
      );

      // Su hedefini hesapla (profil bilgileri eksik olsa bile hesaplama yapılır)
      final calculatedWaterTarget = NutritionCalculatorService.calculateWaterTarget(weight);

      if (mounted) {
        setState(() {
          _dailyCalorieTarget = targetCalories;
          _targetWater = calculatedWaterTarget;
        });
      }
    } catch (e) {
      // Hata durumunda varsayılan değerler kullanılır
    }
  }

  Future<void> addToDiary() async {
    setState(() => _saving = true);

    try {
      // analysisResult yerine widget.foodData kullanıyoruz
      final analysisResult = widget.foodData;
      
      await Supabase.instance.client
          .from('diary')
          .insert({
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'food_name': analysisResult['name'] ?? 'Bilinmeyen',
        'calories': (analysisResult['calories'] ?? 0) is int 
            ? (analysisResult['calories'] ?? 0) 
            : ((analysisResult['calories'] ?? 0) as num).toInt(),
        'allergens': analysisResult['allergens'] ?? [],
        'summary': analysisResult['ai_summary'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Günlüğe eklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }

    setState(() => _saving = false);
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 80) return const Color(0xFF66BB6A); // Yumuşak yeşil
    if (score >= 60) return const Color(0xFFFFB74D); // Yumuşak turuncu
    return const Color(0xFFEF5350); // Yumuşak kırmızı
  }

  double _getCaloriePercentage() {
    final calories = (widget.foodData['calories'] ?? 0) as num;
    return (calories.toDouble() / _dailyCalorieTarget * 100).clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    final confidence = ((widget.foodData['confidence'] ?? 0.8) as num).toDouble();
    final healthScore = (widget.foodData['health_score'] ?? 50) as num;
    final alternatives = widget.foodData['alternatives'] as List? ?? [];
    final allergens = widget.foodData['allergens'] as List? ?? [];
    final mainIngredients = widget.foodData['main_ingredients'] as List? ?? [];
    final toppingIngredients = widget.foodData['topping_ingredients'] as List? ?? [];
    final portion = widget.foodData['portion']?.toString() ?? '1 porsiyon';
    final healthierAlternative = widget.foodData['healthier_alternative']?.toString() ?? '';
    final aiSummary = widget.foodData['ai_summary']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _mintColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Besin Analizi',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğraf Önizleme
            if (widget.imageFile != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(
                    widget.imageFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Yemek Adı + Güven Skoru + Alternatifler
            _buildFoodNameSection(
              widget.foodData['name']?.toString() ?? 'Bilinmeyen Yemek',
              confidence,
              alternatives,
            ),
            const SizedBox(height: 24),

            // Sağlık Skoru
            _buildHealthScoreCard(healthScore.toInt()),
            const SizedBox(height: 24),

            // Porsiyon Bilgisi
            _buildPortionCard(portion),
            const SizedBox(height: 24),

            // Günlük Kalori Hedefine Etkisi
            _buildCalorieImpactCard(),
            const SizedBox(height: 24),

            // Su Analizi
            _buildWaterAnalysisCard(),
            const SizedBox(height: 24),

            // Besin Değerleri (Kalori, Protein, Karbonhidrat, Yağ, Lif, Şeker)
            _buildNutritionValuesSection(),
            const SizedBox(height: 24),

            // Makro Dağılımı Pie Chart
            _buildMacroChart(),
            const SizedBox(height: 24),

            // Malzemeler (Ana + Üst)
            if (mainIngredients.isNotEmpty || toppingIngredients.isNotEmpty)
              _buildIngredientsSection(mainIngredients, toppingIngredients),
            if (mainIngredients.isNotEmpty || toppingIngredients.isNotEmpty)
              const SizedBox(height: 24),

            // Alerjen Uyarıları
            if (allergens.isNotEmpty) _buildAllergenWarnings(allergens),
            if (allergens.isNotEmpty) const SizedBox(height: 24),

            // Daha Sağlıklı Alternatif
            if (healthierAlternative.isNotEmpty)
              _buildHealthierAlternativeCard(healthierAlternative),
            if (healthierAlternative.isNotEmpty) const SizedBox(height: 24),

            // AI Özet Yorumu
            if (aiSummary.isNotEmpty) _buildAISummaryCard(aiSummary),
            if (aiSummary.isNotEmpty) const SizedBox(height: 24),

            // "Yemeğimle Dalga Geç 😄" Butonu
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _loadingFunnyComment ? null : () => _showFunnyComment(context),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _mintColor.withOpacity(0.85),
                        _mintColor.withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _mintColor.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_loadingFunnyComment)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Text(
                          '😄',
                          style: TextStyle(fontSize: 22),
                        ),
                      const SizedBox(width: 12),
                      Text(
                        _loadingFunnyComment ? 'Yorum hazırlanıyor...' : 'Yemeğimle Dalga Geç 😄',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Günlüğe Ekle Butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : addToDiary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mintColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 2,
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Günlüğe Ekle',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodNameSection(String name, double confidence, List alternatives) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _mintColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: _mintColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${(confidence * 100).toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _mintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (alternatives.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Alternatif Öneriler:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: alternatives
                .take(3)
                .map((alt) => Chip(
                      label: Text(
                        alt.toString(),
                        style: GoogleFonts.poppins(fontSize: 11),
                      ),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: GoogleFonts.poppins(color: Colors.black87),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildHealthScoreCard(int score) {
    final color = _getHealthScoreColor(score);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                '$score',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sağlık Skoru',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortionCard(String portion) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _softGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _mintColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant, color: _mintColor, size: 22),
          ),
          const SizedBox(width: 16),
          Text(
            'Porsiyon: $portion',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieImpactCard() {
    final percentage = _getCaloriePercentage();
    final calories = (widget.foodData['calories'] ?? 0) as num;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _mintColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günlük Kalori Hedefine Etkisi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${calories.toInt()} kcal',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _mintColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Günlük hedefin %${percentage.toStringAsFixed(1)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_mintColor),
                  strokeWidth: 5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterAnalysisCard() {
    // Yemeğin su içeriğini hesapla (yaklaşık olarak)
    // Genel olarak yemeklerin %60-80'i sudur, ama burada basit bir hesaplama yapacağız
    final protein = ((widget.foodData['protein'] ?? 0) as num).toDouble();
    final carbs = ((widget.foodData['carbs'] ?? 0) as num).toDouble();
    final fat = ((widget.foodData['fat'] ?? 0) as num).toDouble();
    
    // Yaklaşık su içeriği hesaplama (gram cinsinden)
    // Protein, karbonhidrat ve yağ içeren yemeklerin su içeriği genelde %50-70 arasındadır
    // Basit bir formül: Toplam ağırlık tahmini (protein + carbs + fat + su)
    // Su içeriği = toplam ağırlık × 0.6 (ortalama)
    final estimatedWeight = (protein + carbs + fat) * 1.5; // Yaklaşık toplam ağırlık
    final estimatedWaterContent = estimatedWeight * 0.6; // %60 su içeriği
    
    // Bardak sayısına çevir (1 bardak ≈ 250 ml ≈ 250 g su)
    final waterInCups = (estimatedWaterContent / 250).clamp(0.0, 5.0);
    
    // Günlük su hedefine etkisi (yüzde)
    final waterPercentage = _targetWater > 0 ? (waterInCups / _targetWater * 100).clamp(0.0, 100.0) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _softBlue.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _softBlue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: const Color(0xFF2196F3),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Su Analizi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '~${waterInCups.toStringAsFixed(1)} bardak',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Günlük hedefin %${waterPercentage.toStringAsFixed(1)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Günlük su hedefi: $_targetWater bardak',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: waterPercentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF2196F3)),
                  strokeWidth: 5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionValuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Besin Değerleri',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildNutritionCard('Kalori', '${widget.foodData['calories'] ?? 0}', 'kcal', const Color(0xFFFFB3BA), Icons.local_fire_department),
            _buildNutritionCard('Protein', '${widget.foodData['protein'] ?? 0}', 'g', const Color(0xFFBBDEFB), Icons.fitness_center),
            _buildNutritionCard('Karbonhidrat', '${widget.foodData['carbs'] ?? 0}', 'g', const Color(0xFFFFE0B2), Icons.energy_savings_leaf),
            _buildNutritionCard('Yağ', '${widget.foodData['fat'] ?? 0}', 'g', const Color(0xFFC5CAE9), Icons.water_drop),
            _buildNutritionCard('Lif', '${widget.foodData['fiber'] ?? 0}', 'g', const Color(0xFFC8E6C9), Icons.eco),
            _buildNutritionCard('Şeker', '${widget.foodData['sugar'] ?? 0}', 'g', const Color(0xFFFFE0B2), Icons.cake),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionCard(String label, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color.withOpacity(0.9), size: 20),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChart() {
    final protein = ((widget.foodData['protein'] ?? 0) as num).toDouble() * 4; // 1g protein = 4 kcal
    final carbs = ((widget.foodData['carbs'] ?? 0) as num).toDouble() * 4; // 1g carbs = 4 kcal
    final fat = ((widget.foodData['fat'] ?? 0) as num).toDouble() * 9; // 1g fat = 9 kcal
    final total = protein + carbs + fat;
    
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Makro Dağılımı',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: protein,
                          title: '${(protein / total * 100).toStringAsFixed(0)}%',
                          color: const Color(0xFF90CAF9),
                          radius: 80,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: carbs,
                          title: '${(carbs / total * 100).toStringAsFixed(0)}%',
                          color: const Color(0xFFFFCC80),
                          radius: 80,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: fat,
                          title: '${(fat / total * 100).toStringAsFixed(0)}%',
                          color: const Color(0xFFA5D6A7),
                          radius: 80,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Protein', const Color(0xFF90CAF9), protein / total),
                      const SizedBox(height: 14),
                      _buildLegendItem('Karbonhidrat', const Color(0xFFFFCC80), carbs / total),
                      const SizedBox(height: 14),
                      _buildLegendItem('Yağ', const Color(0xFFA5D6A7), fat / total),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double percentage) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          '${(percentage * 100).toStringAsFixed(0)}%',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(List mainIngredients, List toppingIngredients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Malzemeler',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (mainIngredients.isNotEmpty) ...[
          Text(
            'Ana Malzemeler',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mainIngredients
                .map((ingredient) => Chip(
                      label: Text(
                        ingredient.toString(),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      backgroundColor: _mintColor.withOpacity(0.1),
                      labelStyle: GoogleFonts.poppins(color: _mintColor),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (toppingIngredients.isNotEmpty) ...[
          Text(
            'Üst Malzemeler',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: toppingIngredients
                .map((ingredient) => Chip(
                      label: Text(
                        ingredient.toString(),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: GoogleFonts.poppins(color: Colors.black87),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAllergenWarnings(List allergens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  color: const Color(0xFFFFCDD2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_amber_rounded, color: const Color(0xFFE91E63), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Alerjen Uyarıları',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE91E63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allergens
                .map((allergen) => Chip(
                      label: Text(
                        allergen.toString(),
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: const Color(0xFFFFCDD2),
                      labelStyle: GoogleFonts.poppins(color: const Color(0xFFE91E63)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthierAlternativeCard(String alternative) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _mintColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  color: _mintColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb, color: _mintColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Daha Sağlıklı Alternatif',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _mintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            alternative,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISummaryCard(String summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF90CAF9).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  color: const Color(0xFF90CAF9).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.psychology, color: const Color(0xFF1976D2), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Özet Yorumu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            summary,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
  
  // Esprili yorum göster
  Future<void> _showFunnyComment(BuildContext context) async {
    setState(() => _loadingFunnyComment = true);
    
    try {
      // Yemek bilgilerini hazırla
      final foodName = widget.foodData['name']?.toString() ?? 'Yemek';
      final calories = (widget.foodData['calories'] as num?)?.toInt() ?? 0;
      final healthScore = (widget.foodData['health_score'] as num?)?.toInt() ?? 50;
      final protein = (widget.foodData['protein'] as num?)?.toDouble() ?? 0;
      final carbs = (widget.foodData['carbs'] as num?)?.toDouble() ?? 0;
      final fat = (widget.foodData['fat'] as num?)?.toDouble() ?? 0;
      final summary = widget.foodData['ai_summary']?.toString() ?? '';
      final mainIngredients = widget.foodData['main_ingredients'] as List? ?? [];
      
      // Gemini API'den esprili yorum üret
      final prompt = '''Sen eğlenceli ama saygılı bir sağlıklı yaşam asistanısın. Kullanıcının yemeği hakkında kısa, komik ama kırıcı olmayan bir yorum yap.

Yemek bilgileri:
- İsim: $foodName
- Kalori: $calories kcal
- Sağlık Skoru: $healthScore/100
- Protein: ${protein.toStringAsFixed(1)}g, Karbonhidrat: ${carbs.toStringAsFixed(1)}g, Yağ: ${fat.toStringAsFixed(1)}g
- Ana Malzemeler: ${mainIngredients.isNotEmpty ? mainIngredients.take(5).join(', ') : 'Bilinmiyor'}
- Özet: ${summary.isNotEmpty ? summary.substring(0, summary.length > 100 ? 100 : summary.length) : 'Yok'}

Maksimum 2 cümle, 1 emoji kullan. Hafif mizah, tatlı laf sokma şeklinde olsun. Asla kırıcı, aşağılayıcı veya suçlayıcı olmasın. Türkçe yaz.

Sadece yorumu yaz, başlık veya açıklama ekleme.''';

      final response = await _chatService.sendMessage(prompt);
      final comment = response.trim();
      
      if (mounted) {
        setState(() => _loadingFunnyComment = false);
        _showFunnyCommentDialog(context, comment);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFunnyComment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum üretilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Esprili yorum dialog'u göster
  void _showFunnyCommentDialog(BuildContext context, String comment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _mintColor.withOpacity(0.2),
                        _mintColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '😄',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Yemeğimle Dalga Geç',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Yorum
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _mintColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _mintColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                comment,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // Kapat butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mintColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Tamam',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
