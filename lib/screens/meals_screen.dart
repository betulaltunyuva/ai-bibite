import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/gemini_vision_service.dart';
import '../services/supabase_helper.dart';
import '../theme/meals_theme.dart';
import '../theme/app_colors.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  final supabase = Supabase.instance.client;
  final SupabaseHelper _supabaseHelper = SupabaseHelper();
  final ImagePicker _imagePicker = ImagePicker();
  final GeminiVisionService _geminiService = GeminiVisionService();
  
  String? _userId;
  late String _today;
  
  // Öğün verileri
  Map<String, MealData> _meals = {
    'sabah': MealData(),
    'ogle': MealData(),
    'aksam': MealData(),
  };

  @override
  void initState() {
    super.initState();
    _userId = supabase.auth.currentUser?.id;
    _today = DateFormat("yyyy-MM-dd").format(DateTime.now());
    _loadMeals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sadece tarih değiştiğinde verileri sıfırla ve yükle
    final currentDate = DateFormat("yyyy-MM-dd").format(DateTime.now());
    if (currentDate != _today) {
      // Yeni gün - öğünleri sıfırla
      _today = currentDate;
      setState(() {
        _meals = {
          'sabah': MealData(),
          'ogle': MealData(),
          'aksam': MealData(),
        };
      });
      _loadMeals();
    }
    // Aynı gün içinde sayfa açıldığında hiçbir şey yapma - veriler zaten yüklü
  }

  Future<void> _loadMeals() async {
    if (_userId == null) return;

    try {
      // Sadece bugünün verilerini yükle
      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('daily_meals')
            .select()
            .eq('user_id', _userId!)
            .eq('date', _today),
      );

      if (result != null && result is List) {
        // Önce mevcut verileri koru, sadece veritabanında olanları güncelle
        final updatedMeals = Map<String, MealData>.from(_meals);
        
        for (var meal in result) {
          final mealType = meal['meal_type'] as String?;
          if (mealType != null && updatedMeals.containsKey(mealType)) {
            updatedMeals[mealType] = MealData(
              imagePath: meal['image_url'] as String?,
              description: meal['description'] as String?,
              calories: (meal['calorie'] as num?)?.toInt() ?? 0,
              mealId: meal['id'] as String?,
            );
          }
        }
        
        // Sadece değişiklik varsa setState yap
        if (mounted) {
          setState(() {
            _meals = updatedMeals;
          });
        }
      }
      // Veritabanında veri yoksa mevcut state'i koru (hiçbir şey yapma)
    } catch (e) {
      print('Meal loading error: $e');
    }
  }

  Future<void> _addMealPhoto(String mealType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      final imageFile = File(image.path);

      // Resmi hemen Supabase Storage'a yükle
      String? imageUrl;
      try {
        final fileName = '${_userId}_${mealType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'meal_images/$fileName';

        await supabase.storage.from('meal_images').upload(path, imageFile);
        imageUrl = supabase.storage.from('meal_images').getPublicUrl(path);
      } catch (e) {
        print('Image upload error: $e');
        // Storage bucket yoksa devam et, image_url null kalacak
      }

      // Veritabanına kaydet (kalori 0 - sonra güncellenecek)
      String? mealId = _meals[mealType]?.mealId;
      if (mealId == null) {
        // Yeni kayıt oluştur
        final mealData = <String, dynamic>{
          'user_id': _userId!,
          'date': _today,
          'meal_type': mealType,
          'calorie': 0,
          'image_url': imageUrl,
          if (_meals[mealType]?.description != null && _meals[mealType]!.description!.isNotEmpty)
            'description': _meals[mealType]!.description,
        };

        final result = await _supabaseHelper.executeWithRetry(
          operation: () => supabase.from('daily_meals').insert(mealData).select(),
          silent: false,
        );

        if (result != null && (result as List).isNotEmpty) {
          mealId = result[0]['id'] as String?;
        }
      } else {
        // Mevcut kaydı güncelle (sadece image_url)
        await _supabaseHelper.executeWithRetry(
          operation: () => supabase
              .from('daily_meals')
              .update({'image_url': imageUrl})
              .eq('id', mealId!),
          silent: true,
        );
      }

      setState(() {
        _meals[mealType] = MealData(
          imagePath: imageUrl ?? image.path, // URL varsa URL, yoksa local path
          description: _meals[mealType]?.description,
          calories: _meals[mealType]?.calories ?? 0,
          mealId: mealId,
        );
      });

      // Kalori hesapla (kalori değerini güncelleyecek)
      await _calculateCalories(mealType, imageFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takeMealPhoto(String mealType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return;

      final imageFile = File(image.path);

      // Resmi hemen Supabase Storage'a yükle
      String? imageUrl;
      try {
        final fileName = '${_userId}_${mealType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'meal_images/$fileName';

        await supabase.storage.from('meal_images').upload(path, imageFile);
        imageUrl = supabase.storage.from('meal_images').getPublicUrl(path);
      } catch (e) {
        print('Image upload error: $e');
        // Storage bucket yoksa devam et, image_url null kalacak
      }

      // Veritabanına kaydet (kalori 0 - sonra güncellenecek)
      String? mealId = _meals[mealType]?.mealId;
      if (mealId == null) {
        // Yeni kayıt oluştur
        final mealData = <String, dynamic>{
          'user_id': _userId!,
          'date': _today,
          'meal_type': mealType,
          'calorie': 0,
          'image_url': imageUrl,
          if (_meals[mealType]?.description != null && _meals[mealType]!.description!.isNotEmpty)
            'description': _meals[mealType]!.description,
        };

        final result = await _supabaseHelper.executeWithRetry(
          operation: () => supabase.from('daily_meals').insert(mealData).select(),
          silent: false,
        );

        if (result != null && (result as List).isNotEmpty) {
          mealId = result[0]['id'] as String?;
        }
      } else {
        // Mevcut kaydı güncelle (sadece image_url)
        await _supabaseHelper.executeWithRetry(
          operation: () => supabase
              .from('daily_meals')
              .update({'image_url': imageUrl})
              .eq('id', mealId!),
          silent: true,
        );
      }

      setState(() {
        _meals[mealType] = MealData(
          imagePath: imageUrl ?? image.path, // URL varsa URL, yoksa local path
          description: _meals[mealType]?.description,
          calories: _meals[mealType]?.calories ?? 0,
          mealId: mealId,
        );
      });

      // Kalori hesapla (kalori değerini güncelleyecek)
      await _calculateCalories(mealType, imageFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf çekilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _calculateCalories(String mealType, File imageFile) async {
    if (_userId == null) return;

    try {
      // Loading göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Kalori hesaplanıyor...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Gemini API ile analiz
      final analysis = await _geminiService.analyzeFoodImage(imageFile);
      final calories = (analysis['calories'] as num?)?.toInt() ?? 0;

      // Sadece kalori değerini güncelle (image_url zaten kaydedilmiş)
      if (_meals[mealType]?.mealId != null) {
        await _supabaseHelper.executeWithRetry(
          operation: () => supabase
              .from('daily_meals')
              .update({'calorie': calories})
              .eq('id', _meals[mealType]!.mealId!),
          silent: false,
        );
      }

      setState(() {
        _meals[mealType] = MealData(
          imagePath: _meals[mealType]?.imagePath, // Mevcut imagePath'i koru
          description: _meals[mealType]?.description,
          calories: calories,
          mealId: _meals[mealType]?.mealId,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kalori hesaplandı: $calories kcal (Tahmini)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kalori hesaplanırken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMealPhoto(String mealType) async {
    if (_userId == null) return;

    // Onay iste
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Fotoğrafı Sil',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Bu fotoğrafı silmek istediğinize emin misiniz?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sil',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Eğer veritabanında kayıt varsa sil
      if (_meals[mealType]?.mealId != null) {
        await _supabaseHelper.executeWithRetry(
          operation: () => supabase
              .from('daily_meals')
              .delete()
              .eq('id', _meals[mealType]!.mealId!),
          silent: true,
        );
      }

      // Local state'i temizle
      setState(() {
        _meals[mealType] = MealData(
          imagePath: null,
          description: _meals[mealType]?.description,
          calories: 0,
          mealId: null,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fotoğraf silindi',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fotoğraf silinirken hata: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDescription(String mealType, String description) async {
    if (_userId == null) return;

    try {
      if (_meals[mealType]?.mealId != null) {
        // description sütunu varsa güncelle, yoksa hata verme
        final updateData = <String, dynamic>{};
        if (description.isNotEmpty) {
          updateData['description'] = description;
        }
        
        if (updateData.isNotEmpty) {
          await _supabaseHelper.executeWithRetry(
            operation: () => supabase
                .from('daily_meals')
                .update(updateData)
                .eq('id', _meals[mealType]!.mealId!),
            silent: true,
          );
        }
      }
    } catch (e) {
      // description sütunu yoksa sessizce devam et
      print('Description save error (ignored if column does not exist): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? AppColors.getBackground(context)
          : MealsTheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.getCardBackground(context)
            : MealsTheme.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: MealsTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Öğünler',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: MealsTheme.titleText,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bilgilendirme
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: MealsTheme.bannerBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: MealsTheme.bannerBorder,
                  width: 1.5,
                ),
                boxShadow: [MealsTheme.softShadow],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MealsTheme.bannerBorder.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline_rounded, color: MealsTheme.bannerIcon, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Kalori değerleri tahminidir ve yaklaşık değerlerdir.',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: MealsTheme.bannerIcon,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            
            // Sabah - Pastel sarı
            _buildMealCard(
              context,
              'Sabah',
              'sabah',
              Icons.wb_sunny_rounded,
              MealsTheme.accentMorning,
            ),
            const SizedBox(height: 24),
            
            // Öğle - Pastel pembe
            _buildMealCard(
              context,
              'Öğle',
              'ogle',
              Icons.restaurant_menu_rounded,
              MealsTheme.accentLunch,
            ),
            const SizedBox(height: 24),
            
            // Akşam - Pastel lavanta
            _buildMealCard(
              context,
              'Akşam',
              'aksam',
              Icons.dinner_dining_rounded,
              MealsTheme.accentDinner,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    String title,
    String mealType,
    IconData icon,
    Color accentColor,
  ) {
    final meal = _meals[mealType];
    final hasPhoto = meal?.imagePath != null;
    final calories = meal?.calories ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: MealsTheme.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: MealsTheme.cardBorder,
          width: 1,
        ),
        boxShadow: [MealsTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık bölümü - hafif pastel arka plan
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [MealsTheme.softShadow],
                  ),
                  child: Icon(icon, color: MealsTheme.primary, size: 24),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: MealsTheme.titleText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (calories > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          '$calories kcal',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: MealsTheme.descriptionText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (calories > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: MealsTheme.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$calories',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: MealsTheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          
                // Fotoğraf
                if (hasPhoto && meal!.imagePath!.startsWith('http'))
                  Stack(
                    children: [
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [MealsTheme.cardShadow],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            meal.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey.shade200,
                                      Colors.grey.shade100,
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => _deleteMealPhoto(mealType),
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (hasPhoto)
                  Stack(
                    children: [
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [MealsTheme.cardShadow],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(meal!.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey.shade200,
                                      Colors.grey.shade100,
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => _deleteMealPhoto(mealType),
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: MealsTheme.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: MealsTheme.cardBorder,
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: MealsTheme.inputBackground,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 52,
                            color: MealsTheme.descriptionText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Fotoğraf ekle',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: MealsTheme.titleText,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Yemeğinizi kaydedin',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: MealsTheme.descriptionText,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                
                // Fotoğraf butonları
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: MealsTheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [MealsTheme.softShadow],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _takeMealPhoto(mealType),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Fotoğraf Çek',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: MealsTheme.secondaryBorder,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: MealsTheme.cardSurface,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _addMealPhoto(mealType),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library_rounded, color: MealsTheme.secondaryText, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Galeriden Seç',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: MealsTheme.secondaryText,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                
                // Açıklama
                Container(
                  decoration: BoxDecoration(
                    color: MealsTheme.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: MealsTheme.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: TextEditingController(text: meal?.description ?? ''),
                    onChanged: (value) {
                      setState(() {
                        _meals[mealType] = MealData(
                          imagePath: meal?.imagePath,
                          description: value.isEmpty ? null : value,
                          calories: meal?.calories ?? 0,
                          mealId: meal?.mealId,
                        );
                      });
                      // Debounce ile kaydet
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _saveDescription(mealType, value);
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Açıklama (İsteğe bağlı)',
                      labelStyle: GoogleFonts.poppins(
                        color: MealsTheme.descriptionText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Örn: Ev yapımı, dışarıda yedim...',
                      hintStyle: GoogleFonts.poppins(
                        color: MealsTheme.descriptionText.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.all(18),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      color: MealsTheme.titleText,
                    ),
                    maxLines: 2,
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

class MealData {
  final String? imagePath;
  final String? description;
  final int calories;
  final String? mealId;

  MealData({
    this.imagePath,
    this.description,
    this.calories = 0,
    this.mealId,
  });
}

