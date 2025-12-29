import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.forward();
    
    // 3 saniye sonra LoginScreen'e geçiş
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan görseli (tam ekran)
          Image.asset(
            'lib/assets/images/splash_full.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print("Splash image error: $error");
              // Görsel yüklenemezse açık yeşil arka plan göster
              return Container(
                color: const Color(0xFFE8F5E9),
              );
            },
          ),
          
          // İçerik (SafeArea içinde, Column ile hizalı)
          SafeArea(
            child: Column(
              children: [
                // Üst kısım boşluk
                const Spacer(),
                
                // Alt kısım - Hazırlanıyor ve Progress Bar (üstten boşluk)
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hazırlanıyor',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _progressAnimation.value,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
