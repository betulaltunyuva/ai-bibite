import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Color _mintColor = const Color(0xFF2E7D32);
  final Color _softGrey = const Color(0xFFF2F2F2);
  final Color _textGrey = const Color(0xFF9E9E9E);

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Şifreler eşleşmiyor. Lütfen kontrol edin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Şifreyi güncelle
      final updateResult = await _authService.updatePassword(
        newPassword: passwordController.text.trim(),
      );

      if (mounted) {
        if (updateResult['success'] == true) {
          // Şifre güncellendi, otomatik giriş yap
          final loginResult = await _authService.login(
            email: widget.email,
            password: passwordController.text.trim(),
          );

          if (loginResult['success'] == true) {
            // Başarılı giriş, anasayfaya yönlendir
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            // Giriş başarısız, login ekranına yönlendir
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Şifre güncellendi. Lütfen giriş yapın.'),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(updateResult['error'] ?? 'Şifre güncellenemedi. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Bir hata oluştu. Lütfen tekrar deneyin."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'lib/assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.restaurant_menu,
                            size: 50,
                            color: AppColors.primaryGreen,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Başlık
                  Text(
                    "Yeni Şifre Belirle",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getPrimaryText(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Açıklama
                  Text(
                    "Yeni şifrenizi belirleyin",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.getSecondaryText(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Yeni Şifre
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Yeni Şifre",
                      labelStyle: GoogleFonts.poppins(color: AppColors.getSecondaryText(context)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.getCardBackground(context)
                          : AppColors.getCardBackground(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.getSecondaryText(context),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.getPrimaryText(context),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre gereklidir';
                      }
                      if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalıdır';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Şifre Tekrar
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "Şifre Tekrar",
                      labelStyle: GoogleFonts.poppins(color: AppColors.getSecondaryText(context)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.getCardBackground(context)
                          : AppColors.getCardBackground(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.getSecondaryText(context),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.getPrimaryText(context),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre tekrar gereklidir';
                      }
                      if (value != passwordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Onayla Butonu
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: loading ? null : _resetPassword,
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Onayla",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

