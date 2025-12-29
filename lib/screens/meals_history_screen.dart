import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/supabase_helper.dart';
import '../theme/app_colors.dart';
import 'diary_detail_screen.dart';
import 'recipe_detail_screen.dart';

class MealsHistoryScreen extends StatefulWidget {
  const MealsHistoryScreen({super.key});

  @override
  State<MealsHistoryScreen> createState() => _MealsHistoryScreenState();
}

class _MealsHistoryScreenState extends State<MealsHistoryScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final SupabaseHelper _supabaseHelper = SupabaseHelper();
  final Color _mintColor = const Color(0xFF2E7D32);

  List<Map<String, dynamic>> _meals = [];
  List<Map<String, dynamic>> _recipes = [];
  bool _loading = true;
  bool _loadingRecipes = true;
  DateTime _selectedDate = DateTime.now();
  String? _userId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _userId = supabase.auth.currentUser?.id;
    _tabController = TabController(length: 2, vsync: this);
    _initializeLocale();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('tr_TR', null);
    _loadMeals();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _loadingRecipes = true);

    try {
      if (_userId == null) {
        setState(() {
          _recipes = [];
          _loadingRecipes = false;
        });
        return;
      }

      final selectedDateStr = DateFormat("yyyy-MM-dd").format(_selectedDate);

      // Tarihe göre tarifleri filtrele
      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('saved_recipes')
            .select()
            .eq('user_id', _userId!)
            .gte('created_at', '${selectedDateStr}T00:00:00Z')
            .lte('created_at', '${selectedDateStr}T23:59:59Z')
            .order('created_at', ascending: false),
      );

      if (mounted) {
        setState(() {
          _recipes = result != null ? (result as List<dynamic>).cast<Map<String, dynamic>>() : [];
          _loadingRecipes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recipes = [];
          _loadingRecipes = false;
        });
      }
    }
  }

  Future<void> _loadMeals() async {
    setState(() => _loading = true);

    try {
      if (_userId == null) {
        setState(() {
          _meals = [];
          _loading = false;
        });
        return;
      }

      final selectedDateStr = DateFormat("yyyy-MM-dd").format(_selectedDate);

      // diary tablosundan bugünün kayıtlarını çek
      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('diary')
            .select()
            .eq('user_id', _userId!)
            .gte('created_at', '${selectedDateStr}T00:00:00Z')
            .lte('created_at', '${selectedDateStr}T23:59:59Z')
            .order('created_at', ascending: false),
      );

      if (mounted) {
        setState(() {
          _meals = result != null ? (result as List<dynamic>).cast<Map<String, dynamic>>() : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _meals = [];
          _loading = false;
        });
      }
    }
  }

  String _getFormattedDateSync() {
    // Türkçe ay isimleri
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final day = _selectedDate.day;
    final month = months[_selectedDate.month - 1];
    final year = _selectedDate.year;
    return '$day $month $year';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _mintColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMeals();
      _loadRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getCardBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yemek Geçmişi',
          style: GoogleFonts.poppins(
            color: AppColors.getPrimaryText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppColors.getCardBackground(context),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: AppColors.getSecondaryText(context),
              indicatorColor: AppColors.primaryGreen,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Yemek Geçmişi'),
                Tab(text: 'Tariflerim'),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Yemek Geçmişi Tab
                Column(
                  children: [
                    // Tarih Seçici
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.getCardBackground(context),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left, color: AppColors.primaryGreen),
                            onPressed: () {
                              setState(() {
                                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                              });
                              _loadMeals();
                              _loadRecipes();
                            },
                          ),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, color: AppColors.primaryGreen, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getFormattedDateSync(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right, color: AppColors.primaryGreen),
                            onPressed: _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                                ? () {
                                    setState(() {
                                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                                    });
                                    _loadMeals();
                                    _loadRecipes();
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // Yemek Listesi
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _meals.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu,
                                        size: 64,
                                        color: AppColors.getBorderDivider(context),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Bu tarihte yemek kaydı yok',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: AppColors.getSecondaryText(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _meals.length,
                                  itemBuilder: (context, index) {
                                    final meal = _meals[index];
                                    return _buildMealCard(meal);
                                  },
                                ),
                    ),
                  ],
                ),

                // Tariflerim Tab
                Column(
                  children: [
                    // Tarih Seçici
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.getCardBackground(context),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left, color: AppColors.primaryGreen),
                            onPressed: () {
                              setState(() {
                                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                              });
                              _loadMeals();
                              _loadRecipes();
                            },
                          ),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, color: AppColors.primaryGreen, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getFormattedDateSync(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right, color: AppColors.primaryGreen),
                            onPressed: _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                                ? () {
                                    setState(() {
                                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                                    });
                                    _loadMeals();
                                    _loadRecipes();
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // Tarif Listesi
                    Expanded(
                      child: _loadingRecipes
                          ? const Center(child: CircularProgressIndicator())
                          : _recipes.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.menu_book,
                                        size: 64,
                                        color: AppColors.getBorderDivider(context),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Bu tarihte tarif kaydınız yok',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: AppColors.getSecondaryText(context),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Öneriler sekmesinden tarif kaydedebilirsiniz',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.getSecondaryText(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _recipes.length,
                                  itemBuilder: (context, index) {
                                    final recipe = _recipes[index];
                                    return _buildRecipeCard(recipe);
                                  },
                                ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    // diary tablosu için alan adları
    final mealName = meal['food_name']?.toString() ?? meal['meal_name']?.toString() ?? 'Bilinmeyen';
    final calories = (meal['calories'] as num?)?.toInt() ?? 0;
    final protein = meal['protein'] != null ? (meal['protein'] as num).toDouble() : null;
    final carbs = meal['carbs'] != null ? (meal['carbs'] as num).toDouble() : null;
    final fat = meal['fat'] != null ? (meal['fat'] as num).toDouble() : null;
    final imageUrl = meal['image_url']?.toString();

    return InkWell(
      onTap: () async {
        // Detail ekranına yönlendir
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryDetailScreen(diaryData: meal),
          ),
        );

        // Eğer silme işlemi yapıldıysa (result == true), listeyi yenile
        if (result == true) {
          _loadMeals();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail (varsa)
            if (imageUrl != null && imageUrl.isNotEmpty)
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.getBorderDivider(context),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.restaurant_menu, color: AppColors.getSecondaryText(context));
                    },
                  ),
                ),
              ),

            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Yemek Adı
                  Text(
                    mealName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Kalori
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 16, color: Colors.orange.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '$calories kcal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Makrolar (varsa)
                  if (protein != null || carbs != null || fat != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (protein != null)
                          _buildMacroChip('Protein', '${protein.toStringAsFixed(1)}g', const Color(0xFFFFB3BA)),
                        if (carbs != null)
                          _buildMacroChip('Karbonhidrat', '${carbs.toStringAsFixed(1)}g', const Color(0xFFFFE5B4)),
                        if (fat != null)
                          _buildMacroChip('Yağ', '${fat.toStringAsFixed(1)}g', const Color(0xFFB3E5FC)),
                      ],
                    ),
                ],
              ),
            ),
            // Tıklanabilir olduğunu gösteren ok ikonu
            Icon(Icons.chevron_right, color: AppColors.getSecondaryText(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final title = recipe['title']?.toString() ?? 'Tarif';
    final createdAt = recipe['created_at']?.toString();

    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
      } catch (e) {
        formattedDate = createdAt;
      }
    }

    return InkWell(
      onTap: () async {
        // Detail ekranına yönlendir
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );

        // Eğer silme işlemi yapıldıysa (result == true), listeyi yenile
        if (result == true) {
          _loadRecipes();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarif Adı
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (formattedDate.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Tıklanabilir olduğunu gösteren ok ikonu
            Icon(Icons.chevron_right, color: AppColors.getSecondaryText(context)),
          ],
        ),
      ),
    );
  }
}

