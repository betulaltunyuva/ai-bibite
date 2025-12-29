import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class DataSecurityScreen extends StatelessWidget {
  const DataSecurityScreen({super.key});

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
          'Veri Güvenliği',
          style: GoogleFonts.poppins(
            color: AppColors.getPrimaryText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.getCardBackground(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [AppColors.softShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.security,
                      color: AppColors.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Verileriniz Güvende',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getPrimaryText(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSecurityFeature(
                context,
                Icons.lock_outline,
                'Şifreleme',
                'Tüm verileriniz end-to-end şifreleme ile korunmaktadır. Verileriniz sadece siz tarafından görüntülenebilir.',
              ),
              const SizedBox(height: 20),
              _buildSecurityFeature(
                context,
                Icons.cloud_done_outlined,
                'Güvenli Sunucular',
                'Verileriniz güvenli bulut sunucularında saklanır. Düzenli yedeklemeler yapılmaktadır.',
              ),
              const SizedBox(height: 20),
              _buildSecurityFeature(
                context,
                Icons.verified_user_outlined,
                'Kimlik Doğrulama',
                'Hesabınıza erişim için güçlü kimlik doğrulama yöntemleri kullanılmaktadır.',
              ),
              const SizedBox(height: 20),
              _buildSecurityFeature(
                context,
                Icons.privacy_tip_outlined,
                'Gizlilik',
                'Verileriniz üçüncü taraflarla paylaşılmaz. Sadece uygulama geliştirme ve iyileştirme amaçlı anonim veriler kullanılır.',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verileriniz GDPR ve KVKK uyumlu olarak işlenmektedir.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.getPrimaryText(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityFeature(BuildContext context, IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.secondaryGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getPrimaryText(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.getSecondaryText(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

