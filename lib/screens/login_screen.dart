import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => loading = true);

    try {
      final result = await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          // Login başarılı - direkt anasayfaya git
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          String errorMessage = "Giriş başarısız. Lütfen tekrar deneyin.";
          if (result['error'].toString().contains('Invalid login credentials')) {
            errorMessage = "E-posta veya şifre hatalı.";
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Arka plan dekoratif elementler
          _buildBackgroundDecoration(context),
          
          // Beyaz overlay (görsellerin çok silik görünmesi için)
          Container(
            color: Colors.white.withOpacity(0.85),
          ),
          
          // Ana içerik
          SafeArea(
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
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'lib/assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.restaurant_menu,
                                size: 60,
                                color: AppColors.primaryGreen,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Başlık - "AI Bi'Bite" (tipografik hiyerarşi ile)
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "AI ",
                              style: GoogleFonts.nunito(
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2C2C2C),
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextSpan(
                              text: "Bi'Bite",
                              style: GoogleFonts.nunito(
                                fontSize: 38,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2F6F3E),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Sağlıklı Yaşam Asistanın",
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: const Color(0xFF8FAE9A),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // E-posta
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "E-posta",
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF9E9E9E)),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF2C2C2C),
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
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF9E9E9E)),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF9E9E9E),
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
                          color: const Color(0xFF2C2C2C),
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
                      const SizedBox(height: 32),
                      
                      // Giriş Butonu
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F6F3E),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2F6F3E).withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: loading ? null : _login,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: loading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      "Giriş Yap",
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
                      const SizedBox(height: 12),
                      
                      // Şifremi Unuttum linki
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: loading ? null : () {
                            Navigator.pushNamed(context, '/forgot-password');
                          },
                          child: Text(
                            "Şifremi Unuttum",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF2F6F3E).withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Signup link
                      TextButton(
                        onPressed: loading ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: Text(
                          "Hesabın yok mu? Kaydol",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF2F6F3E).withOpacity(0.8),
                            fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  // Arka plan dekoratif elementler
  Widget _buildBackgroundDecoration(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Yaprak ikonları - sol üst
          Positioned(
            top: 80,
            left: 20,
            child: Opacity(
              opacity: 0.04,
              child: Icon(
                Icons.eco,
                size: 120,
                color: const Color(0xFF2F6F3E),
              ),
            ),
          ),
          // Sebze ikonu - sağ üst
          Positioned(
            top: 120,
            right: 30,
            child: Opacity(
              opacity: 0.05,
              child: Icon(
                Icons.agriculture,
                size: 100,
                color: const Color(0xFF2F6F3E),
              ),
            ),
          ),
          // Tabak ikonu - sol alt
          Positioned(
            bottom: 150,
            left: 40,
            child: Opacity(
              opacity: 0.03,
              child: Icon(
                Icons.restaurant,
                size: 140,
                color: const Color(0xFF2F6F3E),
              ),
            ),
          ),
          // Avokado/yeşillik ikonu - sağ alt
          Positioned(
            bottom: 200,
            right: 20,
            child: Opacity(
              opacity: 0.04,
              child: Icon(
                Icons.spa,
                size: 110,
                color: const Color(0xFF2F6F3E),
              ),
            ),
          ),
          // Orta kısımda küçük dekoratif elementler
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: MediaQuery.of(context).size.width * 0.15,
            child: Opacity(
              opacity: 0.03,
              child: Icon(
                Icons.local_dining,
                size: 80,
                color: const Color(0xFF2F6F3E),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.5,
            right: MediaQuery.of(context).size.width * 0.2,
            child: Opacity(
              opacity: 0.04,
              child: Icon(
                Icons.breakfast_dining,
                size: 90,
                color: const Color(0xFF2F6F3E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
