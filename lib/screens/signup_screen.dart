import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
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

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => loading = true);

    try {
      final result = await _authService.signup(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        surname: surnameController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          // After signup, go to OTP verification screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerificationScreen(
                email: emailController.text.trim(),
                name: nameController.text.trim(),
                surname: surnameController.text.trim(),
              ),
            ),
          );
        } else {
          String errorMessage = "Kayıt başarısız. Lütfen tekrar deneyin.";
          final errorStr = result['error'].toString().toLowerCase();
          bool shouldNavigateToLogin = false;
          
          if (errorStr.contains('user already registered') ||
              errorStr.contains('already registered') ||
              errorStr.contains('duplicate key') ||
              errorStr.contains('email')) {
            errorMessage = "Bu e-posta adresi zaten kayıtlı. Giriş sayfasına yönlendiriliyorsunuz...";
            shouldNavigateToLogin = true;
          } else if (errorStr.contains('password') || errorStr.contains('weak')) {
            errorMessage = "Şifre çok zayıf. Daha güçlü bir şifre seçin (en az 6 karakter).";
          } else if (errorStr.contains('profil')) {
            errorMessage = "Kullanıcı oluşturuldu ancak profil kaydedilemedi. Lütfen giriş yapmayı deneyin.";
            shouldNavigateToLogin = true;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          
          if (shouldNavigateToLogin) {
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }
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
          icon: Icon(Icons.arrow_back, color: _mintColor),
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
                  const SizedBox(height: 20),
                  
                  // Başlık
                  Text(
                    "Yeni Hesap Oluştur",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getPrimaryText(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Hesabınızı oluşturun ve başlayın",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.getSecondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // İsim
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "İsim",
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
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.getPrimaryText(context),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'İsim gereklidir';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Soyisim
                  TextFormField(
                    controller: surnameController,
                    decoration: InputDecoration(
                      labelText: "Soyisim",
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
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.getPrimaryText(context),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Soyisim gereklidir';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // E-posta
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "E-posta",
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
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.getPrimaryText(context),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta gereklidir';
                      }
                      if (!value.contains('@')) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Şifre
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Şifre",
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
                  
                  // Kayıt Butonu
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _mintColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: loading ? null : _signup,
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Kaydol",
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
                  const SizedBox(height: 24),
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
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

