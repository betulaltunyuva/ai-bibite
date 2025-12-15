import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/gemini_vision_service.dart';
import '../services/nutritionix_service.dart';
import '../services/supabase_helper.dart';
import '../services/nutrition_calculator_service.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import 'food_analyzing_screen.dart';
import 'manual_food_entry_screen.dart';
import 'meals_history_screen.dart';
import 'profile_view_screen.dart';
import 'recommendations/recommendations_screen.dart';
import 'meals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  // Beslenme verileri - Supabase'den hesaplanacak
  int _dailyCalories = 0; // Bugün tüketilen kalori
  int _targetCalories = 2000; // Günlük hedef kalori (TDEE'den hesaplanacak)
  int _protein = 80; // Günlük protein hedefi (gram)
  int _carbs = 200; // Günlük karbonhidrat hedefi (gram)
  int _fat = 60; // Günlük yağ hedefi (gram)
  int _waterCount = 0; // Kullanıcının o gün içtiği su miktarı
  int _targetWater = 8; // Günlük hedef: 8 bardak
  bool _waterGoalReachedShown = false; // Su hedefine ulaşma mesajı gösterildi mi?
  List<String> _selectedSuggestions = []; // Günlük öneriler (4-5 madde)
  bool _loadingSuggestion = false; // Günlük öneri yükleniyor mu
  
  // Dinamik karşılama mesajı
  String _userName = ''; // Kullanıcı adı
  String _greetingMessage = 'Bugün ne yiyorsun?'; // Karşılama mesajı
  bool _loadingGreeting = false; // Karşılama mesajı yükleniyor mu
  String _lastGreetingDate = ''; // Son mesaj üretilen tarih
  List<String> _recentGreetings = []; // Son 10 mesaj (tekrar önleme için)

  // Tarih ve kullanıcı bilgileri
  late String _today;
  String? _userId;

  // Supabase client
  final supabase = Supabase.instance.client;
  final SupabaseHelper _supabaseHelper = SupabaseHelper();

  // Servisler
  final ImagePicker _imagePicker = ImagePicker();
  final GeminiVisionService _geminiService = GeminiVisionService();
  final NutritionixService _nutritionixService = NutritionixService();
  final ChatService _chatService = ChatService();
  bool _loading = false;

  // Animasyonlar
  late AnimationController _blinkController;
  late AnimationController _successController;
  late AnimationController _checkIconController;
  late Animation<double> _blinkAnimation;
  late Animation<double> _successAnimation;
  late Animation<double> _checkIconAnimation;

  // Supabase'den su sayısını getir
  Future<void> _fetchWaterCount() async {
    try {
      if (_userId == null) return;

      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('water_tracking')
            .select()
            .eq('user_id', _userId!)
            .eq('date', _today)
            .maybeSingle(),
      );

      if (result != null && mounted) {
        final recordDate = result['date'] as String?;
        
        // Eğer kayıt bugünün tarihine aitse
        if (recordDate == _today) {
          setState(() {
            _waterCount = (result['count'] as num?)?.toInt() ?? 0;
            // Yeni gün başladıysa mesaj flag'ini sıfırla
            _waterGoalReachedShown = _waterCount >= _targetWater;
          });
          // Eğer hedef tamamlandıysa check icon animasyonunu başlat
          if (_waterCount == _targetWater) {
            _checkIconController.forward();
          }
        } else {
          // Eski güne ait kayıt varsa waterCount = 0 yap ve flag'i sıfırla
          setState(() {
            _waterCount = 0;
            _waterGoalReachedShown = false;
          });
        }
      } else if (mounted) {
        // Kayıt yoksa waterCount = 0 ve flag'i sıfırla
        setState(() {
          _waterCount = 0;
          _waterGoalReachedShown = false;
        });
      }
    } catch (e) {
      // Sessiz mod: hata loglanmaz
      if (mounted) {
        setState(() {
          _waterCount = 0;
          _waterGoalReachedShown = false;
        });
      }
    }
  }

  // Supabase'e su sayısını kaydet/güncelle (sadece bugünün verisi)
  Future<void> _updateWaterCount() async {
    try {
      if (_userId == null) return;

      // Sadece bugünün tarihine ait kaydı güncelle
      // Önce bugünün kaydı var mı kontrol et
      final existing = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('water_tracking')
            .select()
            .eq('user_id', _userId!)
            .eq('date', _today)
            .maybeSingle(),
      );

      if (existing != null) {
        // Bugünün kaydı varsa güncelle
        final recordDate = existing['date'] as String?;
        if (recordDate == _today) {
          await _supabaseHelper.executeWithRetry(
            operation: () => supabase
                .from('water_tracking')
                .update({'count': _waterCount})
                .eq('user_id', _userId!)
                .eq('date', _today),
            silent: true,
          );
        }
        // Eğer tarih farklıysa (eski gün), güncelleme yapma
      } else {
        // Bugünün kaydı yoksa yeni kayıt oluştur
        await _supabaseHelper.executeWithRetry(
          operation: () => supabase.from('water_tracking').insert({
            'user_id': _userId!,
            'date': _today,
            'count': _waterCount,
          }),
          silent: true,
        );
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Sessiz mod: hata loglanmaz
    }
  }

  // Su ekleme fonksiyonu
  Future<void> _addWater() async {
    if (_waterCount < _targetWater) {
      setState(() {
        _waterCount++;
      });
      await _updateWaterCount();

      // Hedef tamamlandıysa animasyon göster (sadece bir kere)
      if (_waterCount == _targetWater && !_waterGoalReachedShown) {
        _waterGoalReachedShown = true;
        _playSuccessAnimation();
      }
    }
  }

  // Başarı animasyonu
  void _playSuccessAnimation() {
    // Yanıp söndürme animasyonu
    _blinkController.repeat(reverse: true);
    
    // Başarı animasyonu
    _successController.forward();

    // Check icon animasyonu
    _checkIconController.forward();

    // 500ms sonra animasyonları durdur
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _blinkController.stop();
        _blinkController.reset();
        _successController.reverse();
        // Check icon animasyonu kalıcı olarak kalacak
      }
    });

    // Snackbar göster
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Günlük su hedefine ulaştın!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Su çıkarma fonksiyonu
  Future<void> _removeWater() async {
    if (_waterCount > 0) {
      setState(() {
        _waterCount--;
        // Eğer hedefin altına düştüyse flag'i sıfırla
        if (_waterCount < _targetWater) {
          _waterGoalReachedShown = false;
        }
      });
      await _updateWaterCount();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Animasyon controller'ları başlat
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _checkIconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkIconController, curve: Curves.elasticOut),
    );

    // Tarih ve kullanıcı bilgilerini ayarla
    _today = DateFormat("yyyy-MM-dd").format(DateTime.now());
    _userId = supabase.auth.currentUser?.id;
    
    // Bugünün tarihini kontrol et (günlük yenileme için)
    _lastGreetingDate = DateFormat("yyyy-MM-dd").format(DateTime.now());

    // Önce su sayısını getir, sonra profil verilerini yükle ve hesapla
    _fetchWaterCount().then((_) {
      // Profil verilerini yükle ve kalori/makro hesapla
      _loadProfileAndCalculate().then((_) {
        // Gemini ile kişiselleştirilmiş öneri üret
        _generatePersonalizedSuggestion();
        // Karşılama mesajı zaten _loadProfileAndCalculate içinde yükleniyor
      });
    });
  }

  // Profil verilerini yükle ve kalori/makro hesapla
  Future<void> _loadProfileAndCalculate() async {
    try {
      if (_userId == null) return;

      final profile = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('profiles')
            .select()
            .eq('id', _userId!)
            .maybeSingle(),
      );

      // Profil verisi olsun veya olmasın, hesaplama yap
      final gender = profile?['gender'] as String?;
      final birthYear = profile?['birth_year'] as int?;
      final height = profile?['height'] as int?;
      final weight = profile?['weight'] as int?;
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

      // Makroları hesapla (profil bilgileri eksik olsa bile hesaplama yapılır)
      final protein = NutritionCalculatorService.calculateProtein(weight);
      final fat = NutritionCalculatorService.calculateFat(targetCalories);
      final carbs = NutritionCalculatorService.calculateCarbs(
        targetCalories,
        protein,
        fat,
      );

      // Bugün tüketilen kaloriyi getir
      final todayCalories = await _getTodayCalories();

      // Su hedefini kilo bazında hesapla
      int calculatedWaterTarget = 8; // Varsayılan değer
      if (weight != null && weight > 0) {
        final waterInLiters = weight * 0.033;
        calculatedWaterTarget = (waterInLiters * 3.75).round();
        // Minimum 4, maksimum 12 bardak olsun
        if (calculatedWaterTarget < 4) calculatedWaterTarget = 4;
        if (calculatedWaterTarget > 12) calculatedWaterTarget = 12;
      }

      if (mounted) {
        setState(() {
          _targetCalories = targetCalories;
          _protein = protein;
          _carbs = carbs;
          _fat = fat;
          _dailyCalories = todayCalories;
          _targetWater = calculatedWaterTarget;
          // Profil verilerini sakla (öneri üretimi için)
          _profileData = profile;
          // Kullanıcı adını al
          _userName = profile?['name']?.toString() ?? '';
        });
        // Karşılama mesajını yükle
        _loadGreetingMessage();
      }
    } catch (e) {
      // Sessiz mod: hata loglanmaz
      // Hata durumunda varsayılan değerler kullanılır (zaten başlangıç değerleri var)
    }
  }

  Map<String, dynamic>? _profileData; // Profil verileri (öneri üretimi için)
  
  // Yedek karşılama mesajları (Gemini çalışmazsa)
  final List<String> _fallbackGreetings = [
    'Bugün sağlıklı beslenmeye odaklan! 💪',
    'Hedeflerine bir adım daha yaklaş! 🌟',
    'Su içmeyi unutma! 💧',
    'Bugün de harika bir gün olacak! ✨',
    'Sağlıklı seçimler yap! 🥗',
    'Hedefine ulaşmak için devam et! 🎯',
    'Bugün de kendine iyi bak! ❤️',
    'Küçük adımlar büyük değişiklikler yaratır! 🌱',
  ];
  
  // Dinamik karşılama mesajı yükle
  Future<void> _loadGreetingMessage() async {
    // Bugünün tarihini kontrol et
    final today = DateFormat("yyyy-MM-dd").format(DateTime.now());
    
    // Eğer bugün için mesaj üretilmişse ve mesaj varsa, tekrar üretme
    if (_lastGreetingDate == today && _greetingMessage != 'Bugün ne yiyorsun?' && _greetingMessage.isNotEmpty) {
      return; // Bugün için mesaj zaten var, tekrar üretme
    }
    
    // Yeni gün başladıysa flag'i sıfırla
    if (_lastGreetingDate != today) {
      _lastGreetingDate = today;
      _recentGreetings.clear(); // Yeni gün için mesaj geçmişini temizle
    }
    
    // Önce yedek mesaj göster (hızlı yükleme için)
    if (_greetingMessage == 'Bugün ne yiyorsun?' || _greetingMessage.isEmpty) {
      setState(() {
        _greetingMessage = _fallbackGreetings[DateTime.now().millisecondsSinceEpoch % _fallbackGreetings.length];
      });
    }
    
    // Arka planda Gemini'dan yeni mesaj çek
    _generateGreetingFromGemini();
  }
  
  // Gemini API'den karşılama mesajı üret
  Future<void> _generateGreetingFromGemini() async {
    if (_userId == null) return;
    
    setState(() => _loadingGreeting = true);
    
    try {
      final profile = _profileData;
      final name = _userName.isNotEmpty ? _userName : 'Kullanıcı';
      final goal = profile?['goal']?.toString() ?? 'Bilgi Yok';
      final allergies = profile?['allergies']?.toString() ?? 'Yok';
      final activityLevel = profile?['activity_level']?.toString() ?? 'Bilgi Yok';
      final dailyCalories = _dailyCalories;
      final targetCalories = _targetCalories;
      final waterCount = _waterCount;
      final targetWater = _targetWater;
      
      // Son 10 mesajı kontrol et (tekrar önleme)
      final recentMessages = _recentGreetings.join('\n');
      
      final prompt = '''Sen AI BiBite sağlıklı yaşam asistanısın. Kullanıcının adı: $name, hedefi: $goal, alerjileri: $allergies, aktivite: $activityLevel. Bugün $dailyCalories / $targetCalories kcal tüketmiş, $waterCount / $targetWater bardak su içmiş.

Maksimum 4-5 kelimelik çok kısa bir karşılama mesajı yaz. Sadece 1 cümle, emoji 1 tane kullan. Pozitif ve motive edici olsun. Çok uzun yazma, sadece kısa bir mesaj.

Son mesajlar (bunlara benzer yazma):
$recentMessages

Sadece mesajı yaz, başlık veya açıklama ekleme. Maksimum 5 kelime!''';

      final response = await _chatService.sendMessage(prompt);
      
      // Mesajı temizle ve kontrol et
      String cleanMessage = response.trim();
      if (cleanMessage.isEmpty) {
        throw Exception('Boş mesaj');
      }
      
      // Mesajı maksimum 5 kelimeye kısalt (emoji'ler kelime sayılmaz)
      // Önce emoji'leri ayır
      final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true);
      final emojis = emojiRegex.allMatches(cleanMessage).map((m) => m.group(0)).toList();
      final textWithoutEmoji = cleanMessage.replaceAll(emojiRegex, '').trim();
      
      // Kelimeleri say (boşluklara göre)
      final words = textWithoutEmoji.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      
      if (words.length > 5) {
        // İlk 5 kelimeyi al
        final shortenedText = words.take(5).join(' ');
        // Emoji'leri geri ekle (varsa)
        cleanMessage = emojis.isNotEmpty 
            ? '$shortenedText ${emojis.join(' ')}'
            : shortenedText;
      }
      
      // Son 10 mesajı güncelle
      _recentGreetings.add(cleanMessage);
      if (_recentGreetings.length > 10) {
        _recentGreetings.removeAt(0);
      }
      
      // Bugünün tarihini kaydet
      _lastGreetingDate = DateFormat("yyyy-MM-dd").format(DateTime.now());
      
      if (mounted) {
        setState(() {
          _greetingMessage = cleanMessage;
          _loadingGreeting = false;
        });
      }
    } catch (e) {
      // Hata durumunda yedek mesaj kullan
      if (mounted) {
        setState(() {
          _greetingMessage = _fallbackGreetings[DateTime.now().millisecondsSinceEpoch % _fallbackGreetings.length];
          _loadingGreeting = false;
        });
      }
    }
  }

  // Gemini ile kişiselleştirilmiş günlük öneri üret
  Future<void> _generatePersonalizedSuggestion() async {
    if (_userId == null) return;

    setState(() => _loadingSuggestion = true);

    try {
      // Profil verilerini al
      final profile = _profileData;
      if (profile == null) {
        // Profil yoksa varsayılan öneri
        setState(() {
          _selectedSuggestions = ['Bugün sağlıklı beslenmeye odaklan!'];
          _loadingSuggestion = false;
        });
        return;
      }

      final age = NutritionCalculatorService.calculateAge(
        profile['birth_year'] as int?,
      );
      final weight = profile['weight'] as int?;
      final gender = profile['gender']?.toString() ?? '';
      final activityLevel = profile['activity_level']?.toString() ?? '';
      final goal = profile['goal']?.toString() ?? '';
      final allergies = profile['allergies']?.toString() ?? '';
      final dietType = profile['diet_type']?.toString() ?? '';
      final dailyCalories = _dailyCalories;
      final targetCalories = _targetCalories;

      // Gemini'ye prompt gönder
      final prompt = '''Sen bir sağlık ve beslenme uzmanısın. Aşağıdaki kullanıcı bilgilerine göre 4-5 adet kısa, motivasyonel ve uygulanabilir günlük sağlık önerisi ver:

- Yaş: ${age ?? 'Bilinmiyor'}
- Kilo: ${weight ?? 'Bilinmiyor'} kg
- Cinsiyet: $gender
- Aktivite Düzeyi: $activityLevel
- Hedef: $goal
- Diyet Tipi: ${dietType.isNotEmpty ? dietType : 'Standart'}
- Alerjiler: ${allergies.isNotEmpty ? allergies : 'Yok'}
- Bugün tüketilen kalori: $dailyCalories / $targetCalories kcal

Her öneri çok kısa olsun: maksimum 1 cümle ve 10-15 kelime. Önerileri numaralandırma (1., 2., 3. gibi) veya madde işareti (-) kullanmadan, sadece metin olarak ver. Her öneri ayrı bir satırda olsun. Türkçe yanıt ver. Sadece önerileri yaz, başlık veya açıklama ekleme.''';

      final response = await _chatService.sendMessage(prompt);

      if (mounted) {
        // Yanıtı satırlara böl ve temizle
        final suggestions = response
            .trim()
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) {
              // Numaralandırma ve madde işaretlerini kaldır
              return line
                  .replaceAll(RegExp(r'^\d+[\.\)]\s*'), '')
                  .replaceAll(RegExp(r'^[-•]\s*'), '')
                  .trim();
            })
            .where((line) => line.isNotEmpty)
            .take(5) // Maksimum 5 öneri
            .toList();

        setState(() {
          _selectedSuggestions = suggestions.isNotEmpty
              ? suggestions
              : ['Bugün sağlıklı beslenmeye odaklan!'];
          _loadingSuggestion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedSuggestions = ['Bugün sağlıklı beslenmeye odaklan!'];
          _loadingSuggestion = false;
        });
      }
    }
  }

  // Bugün tüketilen toplam kaloriyi getir
  Future<int> _getTodayCalories() async {
    try {
      if (_userId == null) return 0;

      int total = 0;

      // meals_history tablosundan bugünün kalorilerini çek
      final mealsHistoryResult = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('meals_history')
            .select('calories')
            .eq('user_id', _userId!)
            .eq('date', _today),
      );

      if (mealsHistoryResult != null) {
        final logs = mealsHistoryResult as List<dynamic>? ?? [];
        for (var item in logs) {
          final calories = (item as Map<String, dynamic>?)?['calories'] as num?;
          total += calories?.toInt() ?? 0;
        }
      }

      // daily_meals tablosundan bugünün kalorilerini çek
      final dailyMealsResult = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('daily_meals')
            .select('calorie')
            .eq('user_id', _userId!)
            .eq('date', _today),
      );

      if (dailyMealsResult != null) {
        final meals = dailyMealsResult as List<dynamic>? ?? [];
        for (var item in meals) {
          final calorie = (item as Map<String, dynamic>?)?['calorie'] as num?;
          total += calorie?.toInt() ?? 0;
        }
      }

      return total;
    } catch (e) {
      return 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blinkController.dispose();
    _successController.dispose();
    _checkIconController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar açıldığında verileri yenile
      _refreshData();
    }
  }

  // Verileri yenile
  Future<void> _refreshData() async {
    await _loadProfileAndCalculate();
    await _fetchWaterCount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: Stack(
        children: [
          Container(
            color: AppColors.getBackground(context),
            child: SafeArea(
              child: Column(
                children: [
                  // Üst Bar - Logo ve Başlık
                  _buildTopBar(theme),
                  
                  // Ana İçerik
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Merhaba Mesajı
                          _buildGreetingCard(theme),
                          const SizedBox(height: 24),
                          
                          // Günlük Öneriler
                          if (_selectedSuggestions.isNotEmpty)
                            _buildDailySuggestionCard(theme),
                          if (_selectedSuggestions.isNotEmpty)
                            const SizedBox(height: 24),
                          const SizedBox(height: 24),
                          
                          // Günlük Kalori Kartı
                          _buildCalorieCard(theme),
                          const SizedBox(height: 20),
                          
                          // Makro Besinler (Protein, Karbonhidrat, Yağ)
                          _buildMacroCards(theme, isSmallScreen, context),
                          const SizedBox(height: 20),
                          
                          // Aksiyon Butonları (2x2 Grid)
                          _buildActionButtons(theme, isSmallScreen, context),
                          const SizedBox(height: 20),
                          
                          // Su Takibi
                          _buildWaterTracker(theme, context),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'lib/assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.restaurant_menu,
                    color: AppColors.primaryGreen,
                    size: 28,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI BiBite',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getPrimaryText(context),
                  ),
                ),
                Text(
                  'Sağlıklı Yaşam Asistanın',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.getSecondaryText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingCard(ThemeData theme) {
    // Kullanıcı adı varsa "Merhaba {name} 👋", yoksa "Merhaba 👋"
    final greetingTitle = _userName.isNotEmpty 
        ? 'Merhaba $_userName 👋'
        : 'Merhaba 👋';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppColors.softShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text(
                '👋',
                style: TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greetingTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getPrimaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                _loadingGreeting
                    ? Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mesaj hazırlanıyor...',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.getSecondaryText(context),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _greetingMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.getSecondaryText(context),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySuggestionCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppColors.softShadow],
      ),
      child: _loadingSuggestion
          ? Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Kişiselleştirilmiş öneriler hazırlanıyor...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.getSecondaryText(context),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.primaryGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Günlük Öneriler',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimaryText(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._selectedSuggestions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final suggestion = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _selectedSuggestions.length - 1 ? 12 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6, right: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.getPrimaryText(context),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }

  Widget _buildCalorieCard(ThemeData theme) {
    final progress = _dailyCalories / _targetCalories;
    final remaining = _targetCalories - _dailyCalories;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Günlük Kalori',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.progressFilled.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_dailyCalories / _targetCalories * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_dailyCalories',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ $_targetCalories kcal',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Custom Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              minHeight: 14,
              backgroundColor: AppColors.progressEmpty,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.progressFilled),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            remaining > 0 
                ? '$remaining kcal kaldı'
                : 'Hedef aşıldı! 🎉',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '* Kalori değerleri tahminidir',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCards(ThemeData theme, bool isSmallScreen, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMacroCard(
            theme,
            'Protein',
            _protein,
            'g',
            const Color(0xFFFFB3BA), // Soft pink
            Icons.fitness_center,
            context,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMacroCard(
            theme,
            'Karbonhidrat',
            _carbs,
            'g',
            const Color(0xFFFFE5B4), // Soft yellow
            Icons.energy_savings_leaf,
            context,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMacroCard(
            theme,
            'Yağ',
            _fat,
            'g',
            const Color(0xFFB3E5FC), // Soft blue
            Icons.water_drop,
            context,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard(
    ThemeData theme,
    String label,
    int value,
    String unit,
    Color color,
    IconData icon,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorderDivider(context), width: 1),
        boxShadow: [AppColors.softShadow],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            '$value$unit',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.getPrimaryText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.getSecondaryText(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isSmallScreen, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yemek Ekle',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.getPrimaryText(context),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.1,
          children: [
            _buildActionButton(
              theme,
              'Fotoğraf Çek',
              Icons.camera_alt,
              AppColors.accentCamera,
              _takePhoto,
              context,
            ),
            _buildActionButton(
              theme,
              'Galeriden Seç',
              Icons.photo_library,
              AppColors.accentGallery,
              _selectFromGallery,
              context,
            ),
            _buildActionButton(
              theme,
              'Barkod Tara',
              Icons.qr_code_scanner,
              AppColors.accentBarcode,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Barkod tarama özelliği şu anda kullanılamıyor.'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              },
              context,
            ),
            _buildActionButton(
              theme,
              'Manuel Ekle',
              Icons.edit,
              AppColors.accentManual,
              _manualEntry,
              context,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.getCardBackground(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.getBorderDivider(context), width: 1),
            boxShadow: [AppColors.softShadow],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getPrimaryText(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterTracker(ThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppColors.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.waterFilled.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.water_drop,
                          color: AppColors.waterFilled,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Su Takibi',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getPrimaryText(context),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$_waterCount / $_targetWater',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.waterFilled,
                    ),
                  ),
                ],
              ),
              // Sağ üstte animasyonlu check icon
              if (_waterCount == _targetWater)
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _checkIconAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _checkIconAnimation.value,
                        child: Opacity(
                          opacity: _checkIconAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.primaryGreen,
                              size: 28,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: Listenable.merge([_blinkController, _successController]),
            builder: (context, child) {
              return Row(
                children: List.generate(
                  _targetWater,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: _addWater,
                      onLongPress: _removeWater,
                      child: Transform.scale(
                        scale: _waterCount == _targetWater && index < _waterCount
                            ? 1.0 + (_successAnimation.value * 0.1)
                            : 1.0,
                        child: Container(
                          margin: EdgeInsets.only(
                            right: index < _targetWater - 1 ? 8 : 0,
                          ),
                          height: 40,
                          decoration: BoxDecoration(
                            color: index < _waterCount
                                ? (_waterCount == _targetWater
                                    ? Color.lerp(
                                        AppColors.waterFilled,
                                        Colors.white,
                                        _blinkAnimation.value * 0.3,
                                      ) ?? AppColors.waterFilled
                                    : AppColors.waterFilled)
                                : AppColors.waterEmpty,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _waterCount == _targetWater && index < _waterCount
                                ? [
                                    // Kalıcı yeşil glow efekti
                                    BoxShadow(
                                      color: AppColors.primaryGreen.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: AppColors.secondaryGreen.withOpacity(0.3),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                    // Animasyon sırasında mavi yanıp söndürme efekti
                                    if (_blinkController.isAnimating)
                                      BoxShadow(
                                        color: AppColors.waterFilled.withOpacity(
                                          _blinkAnimation.value * 0.4,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                  ]
                                : null,
                          ),
                          child: _waterCount == _targetWater && index < _waterCount
                              ? Center(
                                  child: Opacity(
                                    opacity: _blinkAnimation.value,
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int _currentNavIndex = 0;

  Widget _buildBottomNavBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        boxShadow: [AppColors.softShadow],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildNavItem(theme, Icons.home, 'Ana Sayfa', 0),
              ),
              Expanded(
                child: _buildNavItem(theme, Icons.history, 'Geçmiş', 1),
              ),
              Expanded(
                child: _buildNavItem(theme, Icons.lightbulb, 'Öneriler', 2),
              ),
              Expanded(
                child: _buildNavItem(theme, Icons.restaurant_menu, 'Öğünler', 3),
              ),
              Expanded(
                child: _buildNavItem(theme, Icons.person, 'Profil', 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(ThemeData theme, IconData icon, String label, int index) {
    final isActive = _currentNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
        _handleNavigation(index);
      },
      borderRadius: BorderRadius.circular(12),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.navActive : AppColors.navInactive,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isActive ? AppColors.navActive : AppColors.navInactive,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Ana Sayfa - zaten buradayız
        break;
      case 1:
        // Geçmiş
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MealsHistoryScreen()),
        ).then((_) {
          // Geri dönünce index'i sıfırla
          setState(() {
            _currentNavIndex = 0;
          });
        });
        break;
      case 2:
        // Öneriler
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
        ).then((_) {
          // Geri dönünce index'i sıfırla
          setState(() {
            _currentNavIndex = 0;
          });
        });
        break;
      case 3:
        // Öğünler
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MealsScreen()),
        ).then((_) {
          // Geri dönünce verileri yenile (kalori hesaplaması için)
          _refreshData();
          setState(() {
            _currentNavIndex = 0;
          });
        });
        break;
      case 4:
        // Profil
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileViewScreen()),
        ).then((_) {
          // Geri dönünce verileri yenile (profil bilgileri değişmiş olabilir)
          _refreshData();
          setState(() {
            _currentNavIndex = 0;
          });
        });
        break;
    }
  }

  // Fotoğraf Çek
  Future<void> _takePhoto() async {
    if (_loading) return;

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return;

      setState(() => _loading = true);

      final imageFile = File(photo.path);
      final result = await _geminiService.analyzeFoodImageDetailed(imageFile);

      // meals_history'ye kaydet (meal_type olmadan)
      await _saveToMealsHistory(result, imageFile);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodAnalyzingScreen(
              foodData: result,
              imageFile: imageFile,
              source: 'camera',
            ),
          ),
        ).then((_) => _refreshData());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Galeriden Seç
  Future<void> _selectFromGallery() async {
    if (_loading) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _loading = true);

      final imageFile = File(image.path);
      final result = await _geminiService.analyzeFoodImageDetailed(imageFile);

      // meals_history'ye kaydet (meal_type olmadan)
      await _saveToMealsHistory(result, imageFile);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodAnalyzingScreen(
              foodData: result,
              imageFile: imageFile,
              source: 'gallery',
            ),
          ),
        ).then((_) => _refreshData());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }


  // Manuel Ekle
  void _manualEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ManualFoodEntryScreen(),
      ),
    ).then((_) => _refreshData());
  }

  // meals_history tablosuna kaydet (meal_type olmadan)
  Future<void> _saveToMealsHistory(Map<String, dynamic> foodData, File? imageFile) async {
    if (_userId == null) return;

    try {
      String? imageUrl;
      if (imageFile != null) {
        try {
          final fileName = '${_userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final path = 'meal_images/$fileName';

          await supabase.storage.from('meal_images').upload(path, imageFile);
          imageUrl = supabase.storage.from('meal_images').getPublicUrl(path);
        } catch (e) {
          print('Image upload error: $e');
        }
      }

      final mealData = {
        'user_id': _userId!,
        'date': _today,
        'meal_name': foodData['name'] ?? 'Yemek',
        'calories': (foodData['calories'] as num?)?.toInt() ?? 0,
        'protein': (foodData['protein'] as num?)?.toDouble() ?? 0.0,
        'carbs': (foodData['carbs'] as num?)?.toDouble() ?? 0.0,
        'fat': (foodData['fat'] as num?)?.toDouble() ?? 0.0,
        'image_url': imageUrl,
        // meal_type eklenmiyor - bu anasayfadan eklenen yemekler için
      };

      await _supabaseHelper.executeWithRetry(
        operation: () => supabase.from('meals_history').insert(mealData),
        silent: true,
      );
    } catch (e) {
      print('Save to meals_history error: $e');
    }
  }

}

