import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  final Color _mintColor = const Color(0xFF2E7D32);

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'destek@aibibite.com',
      query: 'subject=Yardım ve Destek Talebi',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // E-posta uygulaması yoksa kopyala
      // Clipboard'a kopyalama işlemi burada yapılabilir
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          'Yardım ve Destek',
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
            // Başlık Kartı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: AppColors.primaryGreen, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Size Nasıl Yardımcı Olabiliriz?',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimaryText(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sorularınız için bizimle iletişime geçin',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.getSecondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sık Sorulan Sorular
            _buildSectionCard(
              context: context,
              title: 'Sık Sorulan Sorular',
              children: [
                _buildFAQItem(
                  context: context,
                  question: 'Uygulamayı nasıl kullanırım?',
                  answer: 'Uygulamayı kullanmak için önce profil bilgilerinizi doldurmanız gerekiyor. Ardından yemek fotoğrafı çekebilir, galeriden seçebilir, barkod tarayabilir veya manuel olarak yemek ekleyebilirsiniz.',
                ),
                _buildDivider(context),
                _buildFAQItem(
                  context: context,
                  question: 'Yemek analizi nasıl yapılır?',
                  answer: 'Yemek fotoğrafı çektiğinizde veya galeriden seçtiğinizde, yapay zeka yemeğinizi analiz eder ve besin değerlerini gösterir.',
                ),
                _buildDivider(context),
                _buildFAQItem(
                  context: context,
                  question: 'Günlük kalori hedefi nasıl belirlenir?',
                  answer: 'Günlük kalori hedefiniz, profil bilgilerinize (cinsiyet, yaş, boy, kilo, aktivite düzeyi, hedef) göre otomatik olarak hesaplanır.',
                ),
                _buildDivider(context),
                _buildFAQItem(
                  context: context,
                  question: 'Yemek geçmişimi nasıl görüntülerim?',
                  answer: 'Ana sayfadaki alt menüden "Geçmiş" sekmesine tıklayarak günlük yemek geçmişinizi görüntüleyebilirsiniz.',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // İletişim Bölümü
            _buildSectionCard(
              context: context,
              title: 'İletişim',
              children: [
                _buildContactTile(
                  context: context,
                  icon: Icons.email,
                  title: 'E-posta',
                  subtitle: 'destek@aibibite.com',
                  onTap: _launchEmail,
                ),
                _buildDivider(context),
                _buildContactTile(
                  context: context,
                  icon: Icons.phone,
                  title: 'Telefon',
                  subtitle: '+90 (555) 123 45 67',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Telefon numarası yakında aktif olacak'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  },
                ),
                _buildDivider(context),
                _buildContactTile(
                  context: context,
                  icon: Icons.language,
                  title: 'Web Sitesi',
                  subtitle: 'www.aibibite.com',
                  onTap: () => _launchURL('https://www.aibibite.com'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Yardımcı Kaynaklar
            _buildSectionCard(
              context: context,
              title: 'Yardımcı Kaynaklar',
              children: [
                _buildActionTile(
                  context: context,
                  icon: Icons.book,
                  title: 'Kullanım Kılavuzu',
                  subtitle: 'Uygulama kullanım rehberi',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.getCardBackground(context),
                        title: Text(
                          'Kullanım Kılavuzu',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimaryText(context),
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildGuideSection(
                                context,
                                '1. Profil Oluşturma',
                                'Profil bilgilerinizi (cinsiyet, yaş, boy, kilo, aktivite düzeyi, hedef) doldurun. Bu bilgiler günlük kalori hedefinizin hesaplanması için gereklidir.',
                              ),
                              const SizedBox(height: 16),
                              _buildGuideSection(
                                context,
                                '2. Yemek Ekleme',
                                'Yemek eklemek için 4 yöntem kullanabilirsiniz:\n• Fotoğraf çekme\n• Galeriden seçme\n• Barkod tarama\n• Manuel giriş',
                              ),
                              const SizedBox(height: 16),
                              _buildGuideSection(
                                context,
                                '3. Kalori Takibi',
                                'Eklediğiniz yemeklerin kalori değerleri otomatik olarak hesaplanır ve günlük hedefinize göre ilerlemeniz gösterilir.',
                              ),
                              const SizedBox(height: 16),
                              _buildGuideSection(
                                context,
                                '4. Geçmiş Görüntüleme',
                                'Ana sayfadaki "Geçmiş" sekmesinden önceki günlerin yemek geçmişinizi görüntüleyebilirsiniz.',
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Tamam',
                              style: GoogleFonts.poppins(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _buildDivider(context),
                _buildActionTile(
                  context: context,
                  icon: Icons.video_library,
                  title: 'Video Eğitimler',
                  subtitle: 'Uygulama kullanım videoları',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.getCardBackground(context),
                        title: Text(
                          'Video Eğitimler',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimaryText(context),
                          ),
                        ),
                        content: Text(
                          'Video eğitimler yakında YouTube kanalımızda yayınlanacaktır. Güncellemeler için bizi takip edin!',
                          style: GoogleFonts.poppins(
                            color: AppColors.getSecondaryText(context),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Tamam',
                              style: GoogleFonts.poppins(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _buildDivider(context),
                _buildActionTile(
                  context: context,
                  icon: Icons.feedback,
                  title: 'Geri Bildirim Gönder',
                  subtitle: 'Önerilerinizi bizimle paylaşın',
                  onTap: () {
                    _launchEmail();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

  Widget _buildFAQItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      leading: Icon(Icons.help_outline, color: AppColors.primaryGreen),
      title: Text(
        question,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.getPrimaryText(context),
        ),
      ),
      children: [
        Text(
          answer,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.getSecondaryText(context),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.getPrimaryText(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.getSecondaryText(context),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.getSecondaryText(context)),
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.getPrimaryText(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.getSecondaryText(context),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.getSecondaryText(context)),
      onTap: onTap,
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: AppColors.getBorderDivider(context),
    );
  }

  Widget _buildGuideSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.getSecondaryText(context),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
