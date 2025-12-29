import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aibibite/screens/profile_screen.dart';


class KvkkPage extends StatefulWidget {
  final String name;
  final String surname;
  final String email;

  const KvkkPage({
    super.key,
    required this.name,
    required this.surname,
    required this.email,
  });

  @override
  State<KvkkPage> createState() => _KvkkPageState();
}

class _KvkkPageState extends State<KvkkPage> {
  final supabase = Supabase.instance.client;
  bool loading = false;
  bool kvkkAccepted = false;
  final Color _mintColor = const Color(0xFF2E7D32);

  Future<void> acceptKvkk() async {
    if (!kvkkAccepted) return;

    setState(() => loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      try {
        // Profil var mı kontrol et
        final existing = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (existing == null) {
          // Yeni profil oluştur - upsert kullan (insert veya update)
          await supabase.from('profiles').upsert({
            'id': user.id,
            'name': widget.name,
            'surname': widget.surname,
            'email': widget.email,
            // Note: is_info_completed column doesn't exist in the database
          });
        } else {
          // Mevcut profili güncelle
          await supabase.from('profiles').update({
            'name': widget.name,
            'surname': widget.surname,
            'email': widget.email,
            // Note: is_info_completed column doesn't exist in the database
          }).eq('id', user.id);
        }
      } catch (profileError) {
        // Profil kaydetme hatası - logla ama devam et
        print('KVKK Profile save error: $profileError');
        
        // Duplicate key veya benzeri hatalar normal, devam et
        final errorStr = profileError.toString().toLowerCase();
        if (!errorStr.contains('duplicate key') && 
            !errorStr.contains('unique constraint') &&
            !errorStr.contains('already exists')) {
          // Normal olmayan bir hata, tekrar fırlat
          rethrow;
        }
        // Normal hatalar için devam et
      }

      // Profil kaydedildiyse veya hata normal bir hata ise, profil sayfasına git
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
        final errorStr = e.toString().toLowerCase();
        
        // More specific error messages
        if (errorStr.contains('null value') || errorStr.contains('not null')) {
          errorMessage = 'Eksik bilgi var. Lütfen tüm alanları doldurun.';
        } else if (errorStr.contains('permission') || errorStr.contains('policy')) {
          errorMessage = 'Yetki hatası. Lütfen tekrar deneyin.';
        } else if (errorStr.contains('network') || errorStr.contains('connection')) {
          errorMessage = 'İnternet bağlantısı yok. Lütfen tekrar deneyin.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Hata olsa bile profil sayfasına git (profil zaten oluşturulmuş olabilir)
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _mintColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'KVKK Aydınlatma Metni',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _mintColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'lib/assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.security,
                                  color: _mintColor,
                                  size: 28,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Kişisel Verilerin Korunması',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _mintColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Giriş
                  _buildSection(
                    '1. Aydınlatma Metni',
                    '6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") uyarınca, kişisel verilerinizin işlenmesi hakkında sizi bilgilendirmek isteriz. Bu aydınlatma metni, AI BiBite uygulaması kapsamında kişisel verilerinizin işlenmesine ilişkin bilgileri içermektedir.',
                  ),

                  // Veri Sorumlusu
                  _buildSection(
                    '2. Veri Sorumlusu',
                    'Veri sorumlusu: AI BiBite\nAdres: [Şirket Adresi]\nE-posta: [E-posta Adresi]\nTelefon: [Telefon Numarası]',
                  ),

                  // İşlenen Kişisel Veriler
                  _buildSection(
                    '3. İşlenen Kişisel Veriler',
                    'Uygulamamız kapsamında aşağıdaki kişisel verileriniz işlenmektedir:\n\n'
                    '• Kimlik Bilgileri: Ad, Soyad\n'
                    '• İletişim Bilgileri: E-posta adresi\n'
                    '• Kullanıcı Hesap Bilgileri: Kullanıcı adı, şifre, profil bilgileri\n'
                    '• Uygulama Kullanım Verileri: Uygulama içi etkileşimler, tercihler, kullanım geçmişi\n'
                    '• Teknik Veriler: IP adresi, cihaz bilgileri, konum verileri (izin verildiğinde)',
                  ),

                  // İşleme Amaçları
                  _buildSection(
                    '4. Kişisel Verilerin İşlenme Amaçları',
                    'Kişisel verileriniz aşağıdaki amaçlarla işlenmektedir:\n\n'
                    '• Uygulama hizmetlerinin sunulması ve yönetimi\n'
                    '• Kullanıcı hesabının oluşturulması ve yönetimi\n'
                    '• Müşteri hizmetleri ve destek süreçlerinin yürütülmesi\n'
                    '• Yasal yükümlülüklerin yerine getirilmesi\n'
                    '• İş süreçlerinin planlanması ve yürütülmesi\n'
                    '• Pazarlama ve iletişim faaliyetlerinin gerçekleştirilmesi (açık rıza ile)\n'
                    '• Güvenlik ve dolandırıcılık önleme',
                  ),

                  // Hukuki Sebep
                  _buildSection(
                    '5. Kişisel Verilerin İşlenmesinin Hukuki Sebebi',
                    'Kişisel verileriniz aşağıdaki hukuki sebeplere dayanarak işlenmektedir:\n\n'
                    '• KVKK\'nın 5. maddesi 2. fıkrası (a) bendi: Açık rızanız\n'
                    '• KVKK\'nın 5. maddesi 2. fıkrası (c) bendi: Sözleşmenin kurulması veya ifası\n'
                    '• KVKK\'nın 5. maddesi 2. fıkrası (e) bendi: Veri sorumlusunun hukuki yükümlülüğünü yerine getirmesi\n'
                    '• KVKK\'nın 5. maddesi 2. fıkrası (f) bendi: Meşru menfaatlerimiz',
                  ),

                  // Veri Aktarımı
                  _buildSection(
                    '6. Kişisel Verilerin Aktarılması',
                    'Kişisel verileriniz, yukarıda belirtilen amaçların gerçekleştirilmesi için:\n\n'
                    '• Hizmet sağlayıcılarımız (bulut sunucu, analitik servisler)\n'
                    '• İş ortaklarımız\n'
                    '• Yasal yükümlülükler çerçevesinde yetkili kamu kurum ve kuruluşları\n\n'
                    'ile paylaşılabilir. Verileriniz yurt dışına aktarılabilir; bu durumda KVKK\'nın 9. maddesi hükümleri uygulanır.',
                  ),

                  // Veri Saklama
                  _buildSection(
                    '7. Kişisel Verilerin Saklanma Süresi',
                    'Kişisel verileriniz, işlenme amaçlarının gerektirdiği süre boyunca ve yasal saklama sürelerine uygun olarak saklanmaktadır. Hizmet sözleşmesi sona erdiğinde veya rızanızı geri çektiğinizde, verileriniz yasal saklama süreleri dışında silinir veya anonimleştirilir.',
                  ),

                  // Haklar
                  _buildSection(
                    '8. KVKK Kapsamındaki Haklarınız',
                    'KVKK\'nın 11. maddesi uyarınca aşağıdaki haklara sahipsiniz:\n\n'
                    '• Kişisel verilerinizin işlenip işlenmediğini öğrenme\n'
                    '• İşlenmişse buna ilişkin bilgi talep etme\n'
                    '• İşlenme amacını ve bunların amacına uygun kullanılıp kullanılmadığını öğrenme\n'
                    '• Yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme\n'
                    '• Eksik veya yanlış işlenmişse düzeltilmesini isteme\n'
                    '• KVKK\'da öngörülen şartlar çerçevesinde silinmesini veya yok edilmesini isteme\n'
                    '• Aktarıldığı üçüncü kişilere bildirilmesini isteme\n'
                    '• İşlenmesine itiraz etme\n'
                    '• Kanuna aykırı işlenmesi sebebiyle zarara uğramanız halinde zararın giderilmesini talep etme',
                  ),

                  // Başvuru
                  _buildSection(
                    '9. Başvuru Hakkı',
                    'Kişisel verilerinizin işlenmesi ile ilgili haklarınızı kullanmak için:\n\n'
                    '• E-posta: [E-posta Adresi]\n'
                    '• Posta: [Posta Adresi]\n\n'
                    'yoluyla başvurabilirsiniz. Başvurunuz en geç 30 gün içinde sonuçlandırılır.\n\n'
                    'Ayrıca, Kişisel Verileri Koruma Kurulu\'na şikayette bulunma hakkınız bulunmaktadır.',
                  ),

                  // Güvenlik
                  _buildSection(
                    '10. Güvenlik',
                    'Kişisel verilerinizin güvenliği için teknik ve idari önlemler alınmıştır. Verileriniz, yetkisiz erişim, kayıp, değiştirme veya ifşa edilme riskine karşı korunmaktadır.',
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Alt kısım - Checkbox ve Buton
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kvkkAccepted
                        ? _mintColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kvkkAccepted ? _mintColor : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: kvkkAccepted,
                        activeColor: _mintColor,
                        onChanged: (value) {
                          setState(() {
                            kvkkAccepted = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'KVKK Aydınlatma Metnini okudum, anladım ve kabul ediyorum.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (loading || !kvkkAccepted) ? null : acceptKvkk,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mintColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: kvkkAccepted ? 4 : 0,
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Kabul Et ve Devam Et',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
