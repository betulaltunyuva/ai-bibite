import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';
import '../services/supabase_helper.dart';
import '../services/user_mood_service.dart' show UserMoodService, MoodType;

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final supabase = Supabase.instance.client;
  final SupabaseHelper _supabaseHelper = SupabaseHelper();
  final UserMoodService _moodService = UserMoodService();

  Map<String, dynamic>? _profileData;
  bool _loading = true;
  MoodType _currentMood = MoodType.neutral;
  bool _moodLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUserMood();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle(),
      );

      if (mounted) {
        setState(() {
          _profileData = result != null ? Map<String, dynamic>.from(result) : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadUserMood() async {
    setState(() => _moodLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _moodLoading = false;
        });
        return;
      }

      final mood = await _moodService.getUserMood(user.id);

      if (mounted) {
        setState(() {
          _currentMood = mood;
          _moodLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _moodLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Hesabı Sil',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.getPrimaryText(context),
            ),
          ),
          content: Text(
            'Bu işlem geri alınamaz. Hesabınız kalıcı olarak silinecektir.',
            style: GoogleFonts.poppins(
              color: AppColors.getPrimaryText(context),
            ),
          ),
          backgroundColor: AppColors.getCardBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Vazgeç',
                style: GoogleFonts.poppins(
                  color: AppColors.getSecondaryText(context),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: Text(
                'Evet, Sil',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı bilgisi bulunamadı.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // profiles tablosunda delete_requested ve delete_requested_at güncelle
      await _supabaseHelper.executeWithRetry(
        operation: () => supabase
            .from('profiles')
            .update({
              'delete_requested': true,
              'delete_requested_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId),
        silent: false,
      );

      print('Hesap silme talebi kaydedildi - userId: $userId');

      // Bilgilendirme mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hesap silme talebiniz alınmıştır. Hesabınız en kısa sürede silinecektir.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Hesap silme işlemi başarısız: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getValue(String key) {
    if (_profileData == null) return 'Bilgi Yok';
    final value = _profileData![key];
    if (value == null) return 'Bilgi Yok';
    return value.toString();
  }

  String _getListValue(String key) {
    if (_profileData == null) return 'Bilgi Yok';
    final value = _profileData![key];
    if (value == null) return 'Bilgi Yok';
    if (value is List) {
      if (value.isEmpty) return 'Bilgi Yok';
      return value.join(', ');
    }
    if (value is String) {
      if (value.isEmpty) return 'Bilgi Yok';
      if (value.contains(',')) {
        return value;
      }
      return value;
    }
    return value.toString();
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
          'Profil',
          style: GoogleFonts.poppins(
            color: AppColors.getPrimaryText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil Başlık Kartı
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Dinamik Yüz Ifadesi
                        _buildMoodAvatar(context),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getValue('name'),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getPrimaryText(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getValue('email'),
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
                  ),
                  const SizedBox(height: 24),

                  // Kişisel Bilgiler Kartı
                  _buildSectionCard(
                    context: context,
                    title: 'Kişisel Bilgiler',
                    children: [
                      _buildInfoTile(
                        context: context,
                        icon: Icons.phone,
                        title: 'Telefon',
                        value: _getValue('phone'),
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context: context,
                        icon: Icons.person,
                        title: 'Cinsiyet',
                        value: _getValue('gender'),
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context: context,
                        icon: Icons.fitness_center,
                        title: 'Aktivite Düzeyi',
                        value: _getValue('activity_level'),
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context: context,
                        icon: Icons.flag,
                        title: 'Hedef',
                        value: _getValue('goal'),
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context: context,
                        icon: Icons.cake,
                        title: 'Yaş',
                        value: _getValue('age'),
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context: context,
                        icon: Icons.height,
                        title: 'Boy',
                        value: _getValue('height') == 'Bilgi Yok' 
                            ? 'Bilgi Yok' 
                            : '${_getValue('height')} cm',
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context: context,
                        icon: Icons.monitor_weight,
                        title: 'Kilo',
                        value: _getValue('weight') == 'Bilgi Yok' 
                            ? 'Bilgi Yok' 
                            : '${_getValue('weight')} kg',
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context: context,
                        icon: Icons.warning,
                        title: 'Alerjiler',
                        value: _getListValue('allergies'),
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context: context,
                        icon: Icons.medical_services,
                        title: 'Hastalıklar',
                        value: _getListValue('diseases'),
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context: context,
                        icon: Icons.restaurant_menu,
                        title: 'Diyet Tipi',
                        value: _getValue('diet_type'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Profili Düzenle Butonu
                  _buildActionButton(
                    context: context,
                    icon: Icons.edit,
                    title: 'Profili Düzenle',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                      // Eğer güncelleme yapıldıysa (result == true), verileri yenile
                      if (result == true) {
                        _loadProfile();
                        _loadUserMood(); // Yüz ifadesini de güncelle
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Ayarlar Butonu
                  _buildActionButton(
                    context: context,
                    icon: Icons.settings,
                    title: 'Ayarlar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Yardım ve Destek Butonu
                  _buildActionButton(
                    context: context,
                    icon: Icons.help_outline,
                    title: 'Yardım ve Destek',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SupportScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Çıkış Yap Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Çıkış Yap',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Hesabı Sil Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _showDeleteAccountDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Hesabı Sil',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getPrimaryText(context),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.getPrimaryText(context),
        ),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: value == 'Bilgi Yok' ? AppColors.getSecondaryText(context) : AppColors.getPrimaryText(context),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: AppColors.getBorderDivider(context),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getBorderDivider(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getPrimaryText(context),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.getSecondaryText(context)),
          ],
        ),
      ),
    );
  }

  /// Dinamik yüz ifadesi avatar widget'ı (animasyonlu)
  Widget _buildMoodAvatar(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(_currentMood),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Color(UserMoodService.getMoodColor(_currentMood)).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(UserMoodService.getMoodColor(_currentMood)).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: _moodLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen,
                    ),
                  ),
                )
              : Text(
                  UserMoodService.getMoodEmoji(_currentMood),
                  style: const TextStyle(fontSize: 32),
                ),
        ),
      ),
    );
  }
}

