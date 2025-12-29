import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_helper.dart';
import '../../services/chat_service.dart';
import '../../services/nutrition_calculator_service.dart';

class RecommendationsTab extends StatefulWidget {
  const RecommendationsTab({super.key});

  @override
  State<RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<RecommendationsTab> {
  final Color _mintColor = const Color(0xFF2E7D32);
  final supabase = Supabase.instance.client;
  final SupabaseHelper _supabaseHelper = SupabaseHelper();
  final ChatService _chatService = ChatService();

  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _recommendations = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadProfileAndGenerateRecommendations();
  }

  Future<void> _loadProfileAndGenerateRecommendations() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = true;
        });
        return;
      }

      // Profil verilerini yükle
      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle(),
      );

      if (result == null) {
        setState(() {
          _loading = false;
          _error = true;
        });
        return;
      }

      setState(() {
        _profileData = Map<String, dynamic>.from(result);
      });

      // Gemini ile öneriler üret
      await _generateRecommendations();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _generateRecommendations() async {
    if (_profileData == null) return;

    final age = NutritionCalculatorService.calculateAge(
      _profileData!['birth_year'] as int?,
    );
    final weight = _profileData!['weight'] as int?;
    final gender = _profileData!['gender']?.toString() ?? '';
    final activityLevel = _profileData!['activity_level']?.toString() ?? '';
    final goal = _profileData!['goal']?.toString() ?? '';
    final allergies = _profileData!['allergies']?.toString() ?? '';
    final dietType = _profileData!['diet_type']?.toString() ?? '';

    // Öneri kategorileri
    final categories = [
      {
        'icon': Icons.local_dining,
        'title': 'Kahvaltı Önerisi',
        'color': Colors.orange,
        'prompt': _buildBreakfastPrompt(age, weight, gender, dietType, allergies, goal),
      },
      {
        'icon': Icons.water_drop,
        'title': 'Su Tüketimi',
        'color': Colors.blue,
        'prompt': _buildWaterPrompt(weight, activityLevel),
      },
      {
        'icon': Icons.fitness_center,
        'title': 'Egzersiz Önerisi',
        'color': Colors.purple,
        'prompt': _buildExercisePrompt(age, activityLevel, weight, goal),
      },
      {
        'icon': Icons.nightlight,
        'title': 'Uyku Düzeni',
        'color': Colors.indigo,
        'prompt': _buildSleepPrompt(age, activityLevel),
      },
      {
        'icon': Icons.eco,
        'title': 'Sebze Tüketimi',
        'color': Colors.green,
        'prompt': _buildVegetablePrompt(allergies, dietType, goal),
      },
    ];

    // Önce boş kartları göster (kullanıcıya feedback için)
    if (mounted) {
      setState(() {
        _recommendations = categories.map((cat) => {
          'icon': cat['icon'],
          'title': cat['title'],
          'description': 'Yükleniyor...',
          'color': cat['color'],
        }).toList();
        _loading = false; // Ana loading'i kapat, kartlar yükleniyor olarak göster
      });
    }

    // Tüm önerileri gerçekten paralel olarak yükle (Future.wait kullan)
    final results = await Future.wait(
      categories.map((category) async {
        try {
          final response = await _chatService.sendMessage(category['prompt'] as String);
          
          // Yanıtı temizle ve kısalt
          String cleanedResponse = response.trim();
          if (cleanedResponse.length > 200) {
            cleanedResponse = cleanedResponse.substring(0, 200) + '...';
          }

          return {
            'icon': category['icon'],
            'title': category['title'],
            'description': cleanedResponse,
            'color': category['color'],
          };
        } catch (e) {
          // Hata durumunda varsayılan mesaj
          return {
            'icon': category['icon'],
            'title': category['title'],
            'description': 'Öneri yüklenirken bir hata oluştu. Lütfen tekrar deneyin.',
            'color': category['color'],
          };
        }
      }),
    );

    // Tüm öneriler yüklendikten sonra ekranda göster
    if (mounted) {
      setState(() {
        _recommendations = results;
      });
    }
  }

  String _buildBreakfastPrompt(int? age, int? weight, String gender, String dietType, String allergies, String goal) {
    return '''Beslenme uzmanı olarak, kısa bir kahvaltı önerisi ver:
Yaş:${age ?? '?'} Kilo:${weight ?? '?'}kg Cinsiyet:$gender Diyet:${dietType.isNotEmpty ? dietType : 'Standart'} Alerji:${allergies.isNotEmpty ? allergies : 'Yok'} Hedef:$goal
Maksimum 80 kelime, sadece öneri, Türkçe.''';
  }

  String _buildWaterPrompt(int? weight, String activityLevel) {
    final waterAmount = weight != null ? (weight * 0.033).toStringAsFixed(1) : '2.5';
    final glasses = (double.parse(waterAmount) * 4).round();
    return '''Sağlık uzmanı olarak, kısa su tüketimi önerisi ver:
Kilo:${weight ?? '?'}kg Aktivite:$activityLevel Önerilen:$waterAmount litre (~$glasses bardak)
Maksimum 80 kelime, motivasyonel, Türkçe, sadece öneri.''';
  }

  String _buildExercisePrompt(int? age, String activityLevel, int? weight, String goal) {
    return '''Fitness uzmanı olarak, kısa egzersiz önerisi ver:
Yaş:${age ?? '?'} Aktivite:$activityLevel Kilo:${weight ?? '?'}kg Hedef:$goal
Maksimum 80 kelime, uygulanabilir, Türkçe, sadece öneri.''';
  }

  String _buildSleepPrompt(int? age, String activityLevel) {
    final recommendedSleep = age != null 
        ? (age < 18 ? '8-10' : age < 65 ? '7-9' : '7-8')
        : '7-9';
    return '''Uyku uzmanı olarak, kısa uyku düzeni önerisi ver:
Yaş:${age ?? '?'} Aktivite:$activityLevel Önerilen:$recommendedSleep saat
Maksimum 80 kelime, uygulanabilir, Türkçe, sadece öneri.''';
  }

  String _buildVegetablePrompt(String allergies, String dietType, String goal) {
    return '''Beslenme uzmanı olarak, kısa sebze tüketimi önerisi ver:
Alerji:${allergies.isNotEmpty ? allergies : 'Yok'} Diyet:${dietType.isNotEmpty ? dietType : 'Standart'} Hedef:$goal
Maksimum 80 kelime, alerjileri dikkate al, Türkçe, sadece öneri.''';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error || _recommendations.isEmpty) {
      return Container(
        color: Colors.grey.shade50,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Öneriler yüklenemedi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadProfileAndGenerateRecommendations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mintColor,
                ),
                child: Text(
                  'Tekrar Dene',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: RefreshIndicator(
        onRefresh: _loadProfileAndGenerateRecommendations,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _recommendations.length,
          itemBuilder: (context, index) {
            final recommendation = _recommendations[index];
            return RecommendationCard(
              icon: recommendation['icon'] as IconData,
              title: recommendation['title'] as String,
              description: recommendation['description'] as String,
              color: recommendation['color'] as Color,
              mintColor: _mintColor,
            );
          },
        ),
      ),
    );
  }
}

class RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color mintColor;

  const RecommendationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.mintColor,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
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
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
