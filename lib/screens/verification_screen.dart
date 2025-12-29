import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'kvkk_page.dart';
import 'reset_password_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  final String surname;
  final bool isPasswordReset;

  const VerificationScreen({
    super.key,
    required this.email,
    required this.name,
    required this.surname,
    this.isPasswordReset = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final AuthService _authService = AuthService();
  bool loading = false;
  bool resending = false;

  final Color _mintColor = const Color(0xFF2E7D32);
  final Color _softGrey = const Color(0xFFF2F2F2);
  final Color _textGrey = const Color(0xFF9E9E9E);

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Tüm alanlar doluysa doğrula
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    if (loading) return;

    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen 6 haneli kodu giriniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      Map<String, dynamic> result;
      
      if (widget.isPasswordReset) {
        // Şifre sıfırlama için recovery OTP doğrula
        result = await _authService.verifyPasswordResetOTP(
          email: widget.email,
          token: code,
        );
      } else {
        // Normal kayıt için email OTP doğrula
        result = await _authService.verifyOTP(
          email: widget.email,
          token: code,
        );
      }

      if (mounted) {
        if (result['success'] == true) {
          if (widget.isPasswordReset) {
            // Şifre sıfırlama: Yeni şifre belirleme ekranına git
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(
                  email: widget.email,
                ),
              ),
            );
          } else {
            // Normal kayıt: KVKK ekranına git
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => KvkkPage(
                  name: widget.name,
                  surname: widget.surname,
                  email: widget.email,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Kod doğrulanamadı. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.red,
            ),
          );
          // Hatalı kodu temizle
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bir hata oluştu. Lütfen tekrar deneyin.'),
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

  Future<void> _resendCode() async {
    if (resending) return;

    setState(() => resending = true);

    try {
      Map<String, dynamic> result;
      
      if (widget.isPasswordReset) {
        // Şifre sıfırlama için reset password email gönder
        result = await _authService.resetPasswordForEmail(
          email: widget.email,
        );
      } else {
        // Normal kayıt için OTP gönder
        result = await _authService.resendOTP(email: widget.email);
      }

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Kod tekrar gönderildi. Lütfen e-postanızı kontrol edin.'),
                backgroundColor: AppColors.primaryGreen,
            ),
          );
          // Kod alanlarını temizle
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Kod gönderilemedi. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bir hata oluştu. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => resending = false);
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
                  "Doğrulama Kodu",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getPrimaryText(context),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Açıklama
                Text(
                  "E-posta adresinize gönderilen 6 haneli kodu giriniz",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.getSecondaryText(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // E-posta adresi
                Text(
                  widget.email,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Kod giriş alanları
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 50,
                      height: 60,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getPrimaryText(context),
                        ),
                        decoration: InputDecoration(
                          counterText: '',
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
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) => _onCodeChanged(index, value),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                
                // Doğrula Butonu
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
                      onTap: loading ? null : _verifyCode,
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Doğrula",
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
                
                // Kodu tekrar gönder
                TextButton(
                  onPressed: resending ? null : _resendCode,
                  child: resending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          "Kodu tekrar gönder",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

