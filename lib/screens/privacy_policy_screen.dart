import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchPrivacyPolicyURL(BuildContext context) async {
    try {
      final Uri url = Uri.parse('https://betulaltunyuva.github.io/ai-bibite-privacy-policy/');
      
      // URL'yi harici tarayıcıda açmayı dene
      try {
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched) {
          // Eğer externalApplication çalışmazsa platformDefault dene
          await launchUrl(
            url,
            mode: LaunchMode.platformDefault,
          );
        }
      } catch (e) {
        // Eğer launchUrl başarısız olursa, kullanıcıya bilgi ver
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'URL açılamadı. Lütfen internet bağlantınızı kontrol edin veya tarayıcınızı manuel olarak açın.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bir hata oluştu: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
              // İkon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.privacy_tip,
                    color: AppColors.primaryGreen,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Kısa Açıklama Metni
              Text(
                'AI Bi\'Bite kullanıcı gizliliğine önem verir. Uygulama kapsamında kullanıcıdan alınan veriler, yalnızca hizmetin sunulması ve kullanıcı deneyiminin iyileştirilmesi amacıyla kullanılır.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.getPrimaryText(context),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Maddeler Halinde Özet Bilgiler
              _buildInfoSection(
                context,
                'Toplanan Veriler',
                'E-posta, uygulama içi kullanım verileri, cihaz bilgileri',
                Icons.data_usage,
              ),
              const SizedBox(height: 20),
              
              _buildInfoSection(
                context,
                'Verilerin Kullanım Amacı',
                'Hizmetin sunulması ve kullanıcı deneyiminin iyileştirilmesi',
                Icons.settings,
              ),
              const SizedBox(height: 20),
              
              _buildInfoSection(
                context,
                'Üçüncü Taraflarla Paylaşım',
                'Üçüncü taraflarla veri paylaşımı yapılmamaktadır',
                Icons.shield,
              ),
              const SizedBox(height: 20),
              
              _buildInfoSection(
                context,
                'Yaş Sınırı',
                'Uygulama 13 yaş altı çocuklara yönelik değildir',
                Icons.child_care,
              ),
              const SizedBox(height: 32),
              
              // Gizlilik Politikasının Tamamını Görüntüle Butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _launchPrivacyPolicyURL(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_new,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Gizlilik Politikasının\nTamamını Görüntüle',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getPrimaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.getSecondaryText(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

