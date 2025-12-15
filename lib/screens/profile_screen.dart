import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_helper.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  
  final Color _mintColor = const Color(0xFF2E7D32);
  final Color _softGrey = const Color(0xFFF2F2F2);
  
  String? _selectedGender;
  int? _birthYear;
  double? _height;
  double? _weight;
  String? _selectedGoal;
  String? _selectedActivityLevel;
  List<String> _selectedAllergies = [];
  List<String> _selectedDiseases = [];
  String? _selectedDietType;
  
  bool _loading = false;
  bool _showAllergyOther = false;
  bool _showDiseaseOther = false;
  
  final TextEditingController _allergyOtherController = TextEditingController();
  final TextEditingController _diseaseOtherController = TextEditingController();

  final List<String> _goals = [
    'Kilo Vermek',
    'Kilo Almak',
    'Kilo Koruma',
    'Kas Yapmak',
    'Sağlıklı Beslenme',
    'Diyabet Kontrolü',
    'Kalp Sağlığı',
    'Kolesterol Düşürme',
    'Tansiyon Kontrolü',
    'Kemik Sağlığı',
    'Bağışıklık Güçlendirme',
    'Enerji Artırma',
    'Uyku Kalitesi',
    'Sindirim Sağlığı',
    'Cilt Sağlığı',
  ];

  final List<String> _activityLevels = [
    'Hareketsiz',
    'Az Aktif (Haftada 1-3 gün)',
    'Orta Aktif (Haftada 3-5 gün)',
    'Aktif (Haftada 6-7 gün)',
    'Çok Aktif (Günde 2+ kez)',
  ];

  final List<String> _dietTypes = [
    'Vejetaryen',
    'Vegan',
    'Ketojenik',
    'Akdeniz',
    'Düşük Karbonhidrat',
    'Düşük Yağ',
    'Glutensiz',
    'Laktozsuz',
    'Hiçbiri (Normal Beslenme)',
  ];

  final List<String> _allergiesList = [
    'Fındık',
    'Yer Fıstığı',
    'Süt',
    'Yumurta',
    'Balık',
    'Kabuklu Deniz Ürünleri',
    'Soya',
    'Buğday',
    'Susam',
  ];

  final List<String> _diseasesList = [
    'Tansiyon',
    'Kolesterol',
    'Diyabet',
    'Hipertansiyon',
    'Kalp Hastalığı',
    'Böbrek Hastalığı',
    'Karaciğer Hastalığı',
    'Tiroid Hastalığı',
    'Çölyak Hastalığı',
    'İrritabl Bağırsak Sendromu',
    'Gut',
  ];

  @override
  void dispose() {
    _allergyOtherController.dispose();
    _diseaseOtherController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Yaş hesaplama
      int? age;
      if (_birthYear != null) {
        age = DateTime.now().year - _birthYear!;
      }

      // Height ve Weight'i int'e çevir
      final int parsedHeight = _height?.toInt() ?? 0;
      final int parsedWeight = _weight?.toInt() ?? 0;

      // Alerji değeri
      List<String> allergiesList = List.from(_selectedAllergies);
      if (_allergyOtherController.text.trim().isNotEmpty) {
        allergiesList.add(_allergyOtherController.text.trim());
      }
      String? allergies = allergiesList.isEmpty ? null : allergiesList.join(', ');

      // Hastalık değeri
      List<String> diseasesList = List.from(_selectedDiseases);
      if (_diseaseOtherController.text.trim().isNotEmpty) {
        diseasesList.add(_diseaseOtherController.text.trim());
      }
      String? diseases = diseasesList.isEmpty ? null : diseasesList.join(', ');

      // Supabase'e gönderilecek map
      final Map<String, dynamic> profileData = {
        'id': user.id,
        'gender': _selectedGender,
        'birth_year': _birthYear,
        'height': parsedHeight,
        'weight': parsedWeight,
        'goal': _selectedGoal,
        'activity_level': _selectedActivityLevel,
        'allergies': allergies,
        'diseases': diseases,
        'diet_type': _selectedDietType,
        'age': age,
        // Note: is_info_completed column doesn't exist in the database
      };

      // Use SupabaseHelper for better error handling and retry mechanism
      final supabaseHelper = SupabaseHelper();
      await supabaseHelper.executeWithRetry(
        operation: () => supabase.from('profiles').upsert(profileData),
        silent: false, // Show errors for debugging
      );
      print('Profile saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil bilgileriniz kaydedildi!'),
            backgroundColor: _mintColor,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e, stackTrace) {
      // Log the actual error for debugging
      print('=== PROFILE SAVE ERROR ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Error string: ${e.toString()}');
      print('Stack trace: $stackTrace');
      print('========================');
      
      if (mounted) {
        String errorMessage = 'Profil kaydedilemedi. Lütfen tekrar deneyin.';
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('network') || errorStr.contains('connection') || errorStr.contains('timeout') || errorStr.contains('internet')) {
          errorMessage = 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.';
        } else if (errorStr.contains('permission') || errorStr.contains('policy') || errorStr.contains('row-level security') || errorStr.contains('rls') || errorStr.contains('unauthorized')) {
          errorMessage = 'Yetki hatası. Lütfen tekrar deneyin.';
        } else if (errorStr.contains('null value') || errorStr.contains('not null') || errorStr.contains('required') || errorStr.contains('missing')) {
          errorMessage = 'Eksik bilgi var. Lütfen tüm zorunlu alanları doldurun.';
        } else if (errorStr.contains('duplicate key') || errorStr.contains('unique constraint')) {
          // Profile already exists, try to update instead
          try {
            final user = supabase.auth.currentUser;
            if (user != null) {
              // Recalculate values for update
              int? age;
              if (_birthYear != null) {
                age = DateTime.now().year - _birthYear!;
              }
              final int parsedHeight = _height?.toInt() ?? 0;
              final int parsedWeight = _weight?.toInt() ?? 0;
              
              List<String> allergiesList = List.from(_selectedAllergies);
              if (_allergyOtherController.text.trim().isNotEmpty) {
                allergiesList.add(_allergyOtherController.text.trim());
              }
              String? allergies = allergiesList.isEmpty ? null : allergiesList.join(', ');
              
              List<String> diseasesList = List.from(_selectedDiseases);
              if (_diseaseOtherController.text.trim().isNotEmpty) {
                diseasesList.add(_diseaseOtherController.text.trim());
              }
              String? diseases = diseasesList.isEmpty ? null : diseasesList.join(', ');
              
              final updateData = {
                'gender': _selectedGender,
                'birth_year': _birthYear,
                'height': parsedHeight,
                'weight': parsedWeight,
                'goal': _selectedGoal,
                'activity_level': _selectedActivityLevel,
                'allergies': allergies,
                'diseases': diseases,
                'diet_type': _selectedDietType,
                'age': age,
                // Note: is_info_completed column doesn't exist in the database
              };
              await supabase.from('profiles').update(updateData).eq('id', user.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Profil bilgileriniz güncellendi!'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
              return;
            }
          } catch (updateError) {
            errorMessage = 'Profil güncellenemedi. Lütfen tekrar deneyin.';
            print('Profile update error: $updateError');
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    setState(() => _loading = false);
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.getPrimaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? AppColors.getCardBackground(context)
                : AppColors.getCardBackground(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.getCardBackground(context)
                  : AppColors.getCardBackground(context),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.getPrimaryText(context),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: validator,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.getPrimaryText(context),
            ),
            dropdownColor: AppColors.getCardBackground(context),
            iconEnabledColor: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required String? Function(String?)? validator,
    required Function(double?) onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.getPrimaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark 
                ? AppColors.getCardBackground(context)
                : AppColors.getCardBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.getPrimaryText(context),
          ),
          validator: validator,
          onChanged: (value) {
            if (value.isNotEmpty) {
              onChanged(double.tryParse(value));
            } else {
              onChanged(null);
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMultiSelectChips({
    required String label,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
    required TextEditingController otherController,
    required bool showOther,
    required Function(bool) onOtherToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.getPrimaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showMultiSelectDialog(
            context,
            label: label,
            items: items,
            selectedItems: selectedItems,
            onSelectionChanged: onSelectionChanged,
            otherController: otherController,
            showOther: showOther,
            onOtherToggle: onOtherToggle,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.getCardBackground(context)
                  : AppColors.getCardBackground(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedItems.isEmpty && !showOther
                        ? 'Seçim yapın...'
                        : selectedItems.isEmpty
                            ? 'Diğer: ${otherController.text}'
                            : selectedItems.length == 1
                                ? selectedItems.first
                                : '${selectedItems.length} seçim yapıldı',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: selectedItems.isEmpty && !showOther
                          ? AppColors.getSecondaryText(context)
                          : AppColors.getPrimaryText(context),
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
              ],
            ),
          ),
        ),
        if (showOther) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: otherController,
            decoration: InputDecoration(
              hintText: 'Lütfen belirtiniz...',
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.getCardBackground(context)
                  : AppColors.getCardBackground(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.getPrimaryText(context),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _showMultiSelectDialog(
    BuildContext context, {
    required String label,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
    required TextEditingController otherController,
    required bool showOther,
    required Function(bool) onOtherToggle,
  }) async {
    List<String> tempSelected = List.from(selectedItems);
    bool tempShowOther = showOther;
    final tempOtherController = TextEditingController(text: otherController.text);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...items.map((item) {
                  final isSelected = tempSelected.contains(item);
                  return CheckboxListTile(
                    title: Text(
                      item,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    value: isSelected,
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          tempSelected.add(item);
                        } else {
                          tempSelected.remove(item);
                        }
                      });
                    },
                    activeColor: AppColors.primaryGreen,
                  );
                }),
                const Divider(),
                CheckboxListTile(
                  title: Text(
                    'Diğer',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  value: tempShowOther,
                  onChanged: (checked) {
                    setDialogState(() {
                      tempShowOther = checked ?? false;
                      if (!tempShowOther) {
                        tempOtherController.clear();
                      }
                    });
                  },
                  activeColor: AppColors.primaryGreen,
                ),
                if (tempShowOther) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: tempOtherController,
                    decoration: InputDecoration(
                      hintText: 'Lütfen belirtiniz...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.getPrimaryText(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: GoogleFonts.poppins(color: AppColors.getSecondaryText(context)),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  onSelectionChanged(tempSelected);
                  onOtherToggle(tempShowOther);
                  if (tempShowOther) {
                    otherController.text = tempOtherController.text;
                  } else {
                    otherController.clear();
                  }
                });
                Navigator.pop(context);
              },
              child: Text(
                'Tamam',
                style: GoogleFonts.poppins(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cinsiyet',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.getPrimaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption('Erkek', Icons.male, context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption('Kadın', Icons.female, context),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGenderOption(String label, IconData icon, BuildContext context) {
    final isSelected = _selectedGender == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = label),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryGreen : AppColors.getSecondaryText(context)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primaryGreen : AppColors.getPrimaryText(context),
              ),
            ),
          ],
        ),
      ),
    );
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
          'Profil Bilgileri',
          style: GoogleFonts.poppins(
            color: AppColors.getPrimaryText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık kartı
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.getCardBackground(context),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'lib/assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person_outline,
                              color: AppColors.primaryGreen,
                              size: 32,
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
                            'Sağlık Profiliniz',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kişiselleştirilmiş öneriler için bilgilerinizi girin',
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
              ),
              const SizedBox(height: 24),

              // Cinsiyet
              _buildGenderSelector(),

              // Doğum Yılı
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doğum Yılı',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getPrimaryText(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Örn: 1990',
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.getCardBackground(context)
                          : AppColors.getCardBackground(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.getPrimaryText(context),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen doğum yılınızı girin';
                      }
                      final year = int.tryParse(value);
                      if (year == null || year < 1900 || year > DateTime.now().year) {
                        return 'Geçerli bir yıl girin';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() => _birthYear = int.tryParse(value));
                      } else {
                        setState(() => _birthYear = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),

              // Boy
              _buildNumberField(
                label: 'Boy (cm)',
                hint: 'Örn: 175',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen boyunuzu girin';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height < 50 || height > 250) {
                    return 'Geçerli bir boy girin (50-250 cm)';
                  }
                  return null;
                },
                onChanged: (value) => setState(() => _height = value),
              ),

              // Kilo
              _buildNumberField(
                label: 'Kilo (kg)',
                hint: 'Örn: 70',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen kilonuzu girin';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight < 20 || weight > 300) {
                    return 'Geçerli bir kilo girin (20-300 kg)';
                  }
                  return null;
                },
                onChanged: (value) => setState(() => _weight = value),
              ),

              // Hedef
              _buildDropdown(
                label: 'Hedef',
                value: _selectedGoal,
                items: _goals,
                onChanged: (value) => setState(() => _selectedGoal = value),
                validator: (value) => value == null ? 'Lütfen bir hedef seçin' : null,
              ),

              // Aktivite Düzeyi
              _buildDropdown(
                label: 'Aktivite Düzeyi',
                value: _selectedActivityLevel,
                items: _activityLevels,
                onChanged: (value) => setState(() => _selectedActivityLevel = value),
                validator: (value) => value == null ? 'Lütfen aktivite düzeyinizi seçin' : null,
              ),

              // Alerjiler
              _buildMultiSelectChips(
                label: 'Alerjiler',
                items: _allergiesList,
                selectedItems: _selectedAllergies,
                onSelectionChanged: (selected) {
                  setState(() {
                    _selectedAllergies = selected;
                  });
                },
                otherController: _allergyOtherController,
                showOther: _showAllergyOther,
                onOtherToggle: (show) {
                  setState(() {
                    _showAllergyOther = show;
                    if (!show) {
                      _allergyOtherController.clear();
                    }
                  });
                },
              ),

              // Hastalıklar
              _buildMultiSelectChips(
                label: 'Hastalıklar',
                items: _diseasesList,
                selectedItems: _selectedDiseases,
                onSelectionChanged: (selected) {
                  setState(() {
                    _selectedDiseases = selected;
                  });
                },
                otherController: _diseaseOtherController,
                showOther: _showDiseaseOther,
                onOtherToggle: (show) {
                  setState(() {
                    _showDiseaseOther = show;
                    if (!show) {
                      _diseaseOtherController.clear();
                    }
                  });
                },
              ),

              // Diyet Tipi
              _buildDropdown(
                label: 'Diyet Tipi',
                value: _selectedDietType,
                items: _dietTypes,
                onChanged: (value) => setState(() => _selectedDietType = value),
                validator: (value) => value == null ? 'Lütfen diyet tipinizi seçin' : null,
              ),

              const SizedBox(height: 24),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    disabledBackgroundColor: AppColors.getSecondaryText(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Kaydet',
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
      ),
    );
  }
}

