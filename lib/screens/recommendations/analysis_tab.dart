import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_helper.dart';
import '../../services/nutrition_calculator_service.dart';

class AnalysisTab extends StatefulWidget {
  const AnalysisTab({super.key});

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  final supabase = Supabase.instance.client;
  final SupabaseHelper _supabaseHelper = SupabaseHelper();
  final Color _mintColor = const Color(0xFF2E7D32);
  Map<String, dynamic>? _profileData;
  bool _loading = true;
  int _waterCount = 0; // Bugün içilen su miktarı (bardak)
  int _targetWater = 8; // Günlük hedef su (bardak)

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadWaterCount();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle(),
      );

      if (result != null && mounted) {
        setState(() {
          _profileData = Map<String, dynamic>.from(result);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _getValue(String key) {
    if (_profileData == null) return 'Bilgi Yok';
    final value = _profileData![key];
    if (value == null) return 'Bilgi Yok';
    return value.toString();
  }

  int? _getIntValue(String key) {
    if (_profileData == null) return null;
    final value = _profileData![key];
    if (value == null) return null;
    return value is int ? value : int.tryParse(value.toString());
  }

  double? _calculateTDEE() {
    final height = _getIntValue('height');
    final weight = _getIntValue('weight');
    final birthYear = _getIntValue('birth_year');
    final age = NutritionCalculatorService.calculateAge(birthYear);
    final gender = _getValue('gender');
    final activityLevel = _getValue('activity_level');
    final goal = _getValue('goal');

    if (height == null || weight == null || age == null || gender == 'Bilgi Yok') {
      return null;
    }

    // NutritionCalculatorService kullanarak TDEE hesapla
    final tdee = NutritionCalculatorService.calculateTDEE(
      gender: gender,
      age: age,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
      goal: goal,
    );

    return tdee.toDouble();
  }

  double? _getRecommendedWater() {
    final weight = _getIntValue('weight');

    if (weight == null) return null;

    // Su ihtiyacı: kilo × 0.033 litre
    double waterInLiters = weight * 0.033;
    
    return waterInLiters;
  }

  Future<void> _loadWaterCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('water_tracking')
            .select()
            .eq('user_id', user.id)
            .eq('date', todayStr)
            .maybeSingle(),
      );

      if (result != null && mounted) {
        final recordDate = result['date'] as String?;
        if (recordDate == todayStr) {
          setState(() {
            _waterCount = (result['count'] as num?)?.toInt() ?? 0;
          });
        }
      }

      // Su hedefini kilo bazında hesapla (NutritionCalculatorService kullanarak)
      final weight = _getIntValue('weight');
      if (mounted) {
        setState(() {
          _targetWater = NutritionCalculatorService.calculateWaterTarget(weight);
        });
      }
    } catch (e) {
      // Sessiz mod: hata loglanmaz
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tdee = _calculateTDEE();
    final recommendedWater = _getRecommendedWater();

    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analiz Başlık Kartı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _mintColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: _mintColor, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profil Analizi',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kişiselleştirilmiş öneriler',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Günlük Kalori Hedefi
            if (tdee != null)
              _buildAnalysisCard(
                icon: Icons.local_fire_department,
                title: 'Günlük Kalori Hedefi',
                value: '${tdee.toInt()} kcal',
                description: 'Aktivite düzeyinize ve vücut özelliklerinize göre hesaplanan günlük kalori ihtiyacınız.',
                color: Colors.orange,
              ),

            // Su Tüketimi Önerisi
            if (recommendedWater != null)
              _buildAnalysisCard(
                icon: Icons.water_drop,
                title: 'Su Takibi',
                value: '$_waterCount / $_targetWater bardak',
                description: 'Kilonuza göre hesaplanan günlük su ihtiyacınız ${recommendedWater.toStringAsFixed(1)} litre (yaklaşık $_targetWater bardak). Bugün $_waterCount bardak su içtiniz.',
                color: Colors.blue,
              ),

            // Profil Özeti
            _buildAnalysisCard(
              icon: Icons.person,
              title: 'Profil Özeti',
              value: _getValue('gender'),
              description: 'Cinsiyet: ${_getValue('gender')}\n'
                  'Yaş: ${NutritionCalculatorService.calculateAge(_getIntValue('birth_year')) ?? 'Bilinmiyor'}\n'
                  'Boy: ${_getValue('height')} cm\n'
                  'Kilo: ${_getValue('weight')} kg\n'
                  'Hedef: ${_getValue('goal')}\n'
                  'Aktivite: ${_getValue('activity_level')}',
              color: _mintColor,
            ),

            // Diyet Tipi
            if (_getValue('diet_type') != 'Bilgi Yok')
              _buildAnalysisCard(
                icon: Icons.restaurant_menu,
                title: 'Diyet Tipi',
                value: _getValue('diet_type'),
                description: 'Seçtiğiniz diyet tipine uygun öneriler sunulmaktadır.',
                color: Colors.green,
              ),

            // Alerji ve Hastalık Uyarıları
            if (_getValue('allergies') != 'Bilgi Yok' || _getValue('diseases') != 'Bilgi Yok')
              _buildAnalysisCard(
                icon: Icons.warning,
                title: 'Önemli Notlar',
                value: 'Dikkat',
                description: '${_getValue('allergies') != 'Bilgi Yok' ? 'Alerjiler: ${_getValue('allergies')}\n' : ''}'
                    '${_getValue('diseases') != 'Bilgi Yok' ? 'Hastalıklar: ${_getValue('diseases')}' : ''}',
                color: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}


