import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'food_analysis_screen.dart';

class FoodAnalyzingScreen extends StatefulWidget {
  final Map<String, dynamic> foodData;
  final File? imageFile;
  final String source; // 'camera', 'gallery', 'barcode', 'manual'

  const FoodAnalyzingScreen({
    super.key,
    required this.foodData,
    this.imageFile,
    required this.source,
  });

  @override
  State<FoodAnalyzingScreen> createState() => _FoodAnalyzingScreenState();
}

class _FoodAnalyzingScreenState extends State<FoodAnalyzingScreen> {
  @override
  void initState() {
    super.initState();
    // 3-4 saniye sonra otomatik olarak analiz ekranına geç
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FoodAnalysisScreen(
              foodData: widget.foodData,
              imageFile: widget.imageFile,
              source: widget.source,
            ),
          ),
        );
      }
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: PopScope(
        canPop: false, // Geri tuşunu devre dışı bırak
        child: SafeArea(
          child: Stack(
            children: [
              // Ana içerik
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Merkez: Büyük yeşil dairesel border içinde fotoğraf
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryGreen,
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.imageFile != null
                          ? Image.file(
                              widget.imageFile!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.primaryGreen.withOpacity(0.1),
                                  child: Icon(
                                    Icons.restaurant_menu,
                                    size: 120,
                                    color: AppColors.primaryGreen,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 120,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Alt Metin - "Hmm, something tasty..." benzeri
                  Text(
                    "Hmm, lezzetli bir şeyler...",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getPrimaryText(context),
                      letterSpacing: 0.3,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // En altta: Kalpler ve AI BiBite karakteri
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Column(
                      children: [
                        // Uygulamaya uygun metin
                        Text(
                          "Yemeğini analiz ediyorum…",
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.getSecondaryText(context),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // AI BiBite karakteri - beyaz kare içinde, ortada
                        Center(
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'lib/assets/images/ai_bibite_analyzing.png.jpg',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.primaryGreen.withOpacity(0.1),
                                    child: Icon(
                                      Icons.psychology,
                                      size: 80,
                                      color: AppColors.primaryGreen,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Üstte X butonu (görsel olarak, ama etkileşim yok)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.getCardBackground(context).withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppColors.getSecondaryText(context),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}

