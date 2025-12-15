import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'login_screen.dart';
import '../services/theme_service.dart';
import '../services/supabase_helper.dart';
import '../theme/app_colors.dart';
import 'change_password_screen.dart';
import 'privacy_policy_screen.dart';
import 'data_security_screen.dart';
import 'language_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;
  final ThemeService _themeService = ThemeService();
  final SupabaseHelper _supabaseHelper = SupabaseHelper();
  String? _userId;

  // Ayarlar durumları
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  String _selectedLanguage = 'Türkçe';

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
    _userId = supabase.auth.currentUser?.id;
    _loadSettings();
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    if (_userId == null) return;

    try {
      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('user_settings')
            .select()
            .eq('user_id', _userId!)
            .maybeSingle(),
      );

      if (result != null && mounted) {
        setState(() {
          _notificationsEnabled = result['notifications_enabled'] ?? true;
          _emailNotifications = result['email_notifications'] ?? true;
          _pushNotifications = result['push_notifications'] ?? true;
          _selectedLanguage = result['language'] ?? 'Türkçe';
        });
      }
    } catch (e) {
      // Tablo yoksa sessizce devam et
      print('Settings load error: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (_userId == null) return;

    try {
      await _supabaseHelper.executeWithRetry(
        operation: () => supabase.from('user_settings').upsert({
          'user_id': _userId!,
          'notifications_enabled': _notificationsEnabled,
          'email_notifications': _emailNotifications,
          'push_notifications': _pushNotifications,
          'language': _selectedLanguage,
          'updated_at': DateTime.now().toIso8601String(),
        }),
        silent: true,
      );
    } catch (e) {
      // Tablo yoksa sessizce devam et
      print('Settings save error: $e');
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
          'Ayarlar',
          style: GoogleFonts.poppins(
            color: AppColors.getPrimaryText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bildirimler Bölümü
            _buildSectionCard(
              title: 'Bildirimler',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: 'Bildirimler',
                  subtitle: 'Tüm bildirimleri aç/kapat',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                      if (!value) {
                        _emailNotifications = false;
                        _pushNotifications = false;
                      }
                    });
                    _saveSettings();
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.email,
                  title: 'E-posta Bildirimleri',
                  subtitle: 'E-posta ile bildirim al',
                  value: _emailNotifications,
                  enabled: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                    _saveSettings();
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.notification_important,
                  title: 'Push Bildirimleri',
                  subtitle: 'Anlık bildirimler al',
                  value: _pushNotifications,
                  enabled: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Gizlilik ve Güvenlik Bölümü
            _buildSectionCard(
              title: 'Gizlilik ve Güvenlik',
              children: [
                _buildActionTile(
                  icon: Icons.lock,
                  title: 'Şifre Değiştir',
                  subtitle: 'Hesap şifrenizi güncelleyin',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.privacy_tip,
                  title: 'Gizlilik Politikası',
                  subtitle: 'Gizlilik politikamızı okuyun',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.security,
                  title: 'Veri Güvenliği',
                  subtitle: 'Verilerinizin güvenliği hakkında bilgi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DataSecurityScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Uygulama Bölümü
            _buildSectionCard(
              title: 'Uygulama',
              children: [
                _buildActionTile(
                  icon: Icons.language,
                  title: 'Dil',
                  subtitle: _selectedLanguage,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LanguageScreen()),
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _selectedLanguage = result;
                      });
                      _saveSettings();
                    }
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  title: 'Karanlık Mod',
                  subtitle: 'Karanlık tema kullan',
                  value: _themeService.isDarkMode,
                  onChanged: (value) {
                    _themeService.toggleTheme();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _themeService.isDarkMode ? 'Karanlık mod açıldı' : 'Karanlık mod kapatıldı',
                          ),
                          backgroundColor: AppColors.primaryGreen,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.storage,
                  title: 'Önbelleği Temizle',
                  subtitle: 'Uygulama önbelleğini temizle',
                  onTap: () async {
                    try {
                      // Cache dizinini temizle
                      final cacheDir = await getTemporaryDirectory();
                      if (cacheDir.existsSync()) {
                        await cacheDir.delete(recursive: true);
                        await cacheDir.create();
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Önbellek başarıyla temizlendi'),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Önbellek temizlenirken hata: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.info,
                  title: 'Hakkında',
                  subtitle: 'Uygulama versiyonu ve bilgileri',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'AI BiBite',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Versiyon: 1.0.0',
                              style: GoogleFonts.poppins(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sağlıklı yaşam asistanınız',
                              style: GoogleFonts.poppins(),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Tamam',
                              style: GoogleFonts.poppins(color: AppColors.primaryGreen),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.softShadow],
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? AppColors.secondaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: enabled ? AppColors.primaryGreen : Colors.grey, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: enabled ? AppColors.getPrimaryText(context) : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: enabled ? AppColors.getSecondaryText(context) : Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.secondaryGreen,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.getPrimaryText(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.getSecondaryText(context),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.getSecondaryText(context)),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      color: AppColors.getBorderDivider(context),
    );
  }
}
