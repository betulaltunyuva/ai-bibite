import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Gizlilik Politikası',
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
              Text(
                'Gizlilik Politikamız',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryText(context),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '1. Veri Toplama',
                'Uygulamamız, sağlıklı beslenme takibi ve kişiselleştirilmiş öneriler sunabilmek için aşağıdaki verileri toplar:\n\n'
                '• Kişisel bilgiler (ad, soyad, e-posta)\n'
                '• Sağlık bilgileri (boy, kilo, yaş, cinsiyet)\n'
                '• Beslenme verileri (yemek fotoğrafları, kalori bilgileri)\n'
                '• Kullanım verileri (uygulama içi aktiviteler)',
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '2. Veri Kullanımı',
                'Toplanan veriler aşağıdaki amaçlarla kullanılır:\n\n'
                '• Kişiselleştirilmiş beslenme önerileri sunmak\n'
                '• Sağlık takibi ve analiz yapmak\n'
                '• Uygulama geliştirmeleri yapmak\n'
                '• Kullanıcı deneyimini iyileştirmek',
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '3. Veri Güvenliği',
                'Verileriniz güvenli sunucularda şifrelenmiş olarak saklanır. Üçüncü taraflarla veri paylaşımı yapılmaz.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '4. Veri Saklama',
                'Verileriniz, hesabınız aktif olduğu sürece saklanır. Hesabınızı sildiğinizde tüm verileriniz kalıcı olarak silinir.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '5. Haklarınız',
                'Verilerinize erişim, düzeltme, silme ve taşınabilirlik haklarınız bulunmaktadır. Bu haklarınızı kullanmak için bizimle iletişime geçebilirsiniz.',
              ),
              const SizedBox(height: 24),
              Text(
                'Son Güncelleme: ${DateTime.now().year}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.getSecondaryText(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.getPrimaryText(context),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

