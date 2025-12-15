import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/recipe_service.dart';
import '../../services/supabase_helper.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _messageController = TextEditingController();
  final RecipeService _recipeService = RecipeService();
  final SupabaseHelper _supabaseHelper = SupabaseHelper();
  final supabase = Supabase.instance.client;
  final Color _mintColor = const Color(0xFF2E7D32);
  final Color _softGrey = const Color(0xFFF2F2F2);

  List<Map<String, String>> _messages = [];
  bool _loading = false;
  bool _loadingMessages = false;
  Map<String, dynamic>? _profileData;
  String? _lastRecipeResponse;

  @override
  void initState() {
    super.initState();
    // ChatPage açıldığında initState() içinde loadChatMessages() çalıştır
    _loadProfile();
    loadChatMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle(),
      );

      if (result != null && mounted) {
        setState(() {
          _profileData = Map<String, dynamic>.from(result);
        });
      }
    } catch (e) {
      // Sessiz hata yönetimi
    }
  }

  /// ChatPage açıldığında Supabase'den tüm mesajları yükle
  /// Local listeyi sıfırlayıp sadece Supabase'den gelen mesajları göster
  Future<void> loadChatMessages() async {
    // Eğer zaten yükleme yapılıyorsa, tekrar başlatma
    if (_loadingMessages) return;

    setState(() {
      _loadingMessages = true;
      _messages = []; // Local listeyi sıfırla
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _messages = [];
            _loadingMessages = false;
          });
        }
        return;
      }

      // Supabase.from('chat_messages')
      //   .select('*')
      //   .eq('user_id', currentUser.id)
      //   .order('created_at', ascending: true)
      final result = await _supabaseHelper.executeQuerySilent(
        () => supabase
            .from('chat_messages')
            .select('*')
            .eq('user_id', user.id)
            .order('created_at', ascending: true),
      );

      if (mounted) {
        if (result != null) {
          // Gelen sonuçları local mesaj listesine ekle
          final List<Map<String, String>> loadedMessages = [];
          for (var msg in result) {
            loadedMessages.add({
              'role': msg['role']?.toString() ?? 'user',
              'text': msg['message']?.toString() ?? '',
            });
          }

          // setState() ile UI'yi güncelle
          setState(() {
            _messages = loadedMessages;
            _loadingMessages = false;
          });
        } else {
          // Veri yoksa boş liste
          setState(() {
            _messages = [];
            _loadingMessages = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages = [];
          _loadingMessages = false;
        });
      }
    }
  }

  /// Supabase chat_messages tablosuna mesaj kaydeden fonksiyon
  /// user_id: currentUser.id
  /// role: "user" veya "assistant"
  /// message: gönderilen içerik
  Future<void> saveChatMessage(String role, String message) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Mesajı Supabase'e kaydet
      await _supabaseHelper.executeWithRetry(
        operation: () => supabase
            .from('chat_messages')
            .insert({
              'user_id': user.id,
              'role': role, // "user" veya "assistant"
              'message': message,
              'created_at': DateTime.now().toIso8601String(),
            }),
        silent: true,
      );
    } catch (e) {
      // Sessiz hata yönetimi - mesaj kaydedilemese bile ekranda gösterilmeye devam eder
    }
  }

  /// Sohbeti sil butonu için deleteAllMessages fonksiyonu
  /// Supabase.from('chat_messages').delete().eq('user_id', currentUser.id)
  /// UI listesini temizle
  Future<void> deleteAllMessages() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Supabase.from('chat_messages').delete().eq('user_id', currentUser.id)
      await _supabaseHelper.executeWithRetry(
        operation: () => supabase
            .from('chat_messages')
            .delete()
            .eq('user_id', user.id),
        silent: false,
      );

      if (mounted) {
        // UI listesini temizle
        setState(() {
          _messages = [];
          _lastRecipeResponse = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sohbet temizlendi'),
            backgroundColor: _mintColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sohbet silinirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _loading) return;

    // Kullanıcı mesaj yazınca:
    // 1. Mesajı ekranda göster
    final userMessage = {"role": "user", "text": text};
    setState(() {
      _messages.add(userMessage);
      _loading = true;
    });
    _messageController.clear();

    // 2. Aynı anda saveChatMessage() ile Supabase'e kaydet
    await saveChatMessage('user', text);

    try {
      if (_profileData == null) {
        await _loadProfile();
      }

      final response = await _recipeService.getRecipeRecommendation(
        userMessage: text,
        profileData: _profileData ?? {},
      );

      if (mounted) {
        // Yapay zeka mesajı oluşturunca:
        // 3. Mesajı ekranda göster
        setState(() {
          _messages.add({"role": "ai", "text": response});
          _lastRecipeResponse = response;
          _loading = false;
        });

        // 4. Supabase'e kaydet
        await saveChatMessage('assistant', response);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = "Bir hata oluştu. Lütfen tekrar deneyin.";
        setState(() {
          _messages.add({
            "role": "ai",
            "text": errorMessage
          });
          _loading = false;
        });
        // Hata mesajını da kaydet
        await saveChatMessage('assistant', errorMessage);
      }
    }
  }

  Future<bool> saveRecipe(String title, String ingredients, String instructions) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        return false;
      }

      await Supabase.instance.client
          .from('saved_recipes')
          .insert({
            'user_id': userId,
            'title': title,
            'ingredients': ingredients,
            'instructions': instructions,
            'created_at': DateTime.now().toIso8601String(),
          });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Mesaj içeriğinde ikonlar için kelime-ikon eşleştirmesi
  Map<String, dynamic>? _getIconForWord(String word) {
    final lowerWord = word.toLowerCase();
    
    if (lowerWord.contains('yemek') || lowerWord.contains('tarif') || 
        lowerWord.contains('beslenme') || lowerWord.contains('öğün') || 
        lowerWord.contains('kalori') || lowerWord.contains('yemek') ||
        lowerWord.contains('somon') || lowerWord.contains('brokoli') ||
        lowerWord.contains('kinoa') || lowerWord.contains('malzeme') ||
        lowerWord.contains('ıspanak') || lowerWord.contains('limon')) {
      return {'icon': Icons.restaurant_menu, 'color': _mintColor};
    } else if (lowerWord.contains('su') || lowerWord.contains('su iç')) {
      return {'icon': Icons.water_drop, 'color': Colors.blue};
    } else if (lowerWord.contains('spor') || lowerWord.contains('egzersiz') ||
               lowerWord.contains('antrenman') || lowerWord.contains('fitness')) {
      return {'icon': Icons.fitness_center, 'color': Colors.orange};
    } else if (lowerWord.contains('sağlık') || lowerWord.contains('sağlıklı') ||
               lowerWord.contains('vitamin') || lowerWord.contains('mineral') ||
               lowerWord.contains('kalsiyum') || lowerWord.contains('d vitamini')) {
      return {'icon': Icons.favorite, 'color': Colors.red};
    } else if (lowerWord.contains('uyku') || lowerWord.contains('dinlenme')) {
      return {'icon': Icons.bedtime, 'color': Colors.indigo};
    } else if (lowerWord.contains('protein') || lowerWord.contains('karbonhidrat') ||
               lowerWord.contains('yağ') || lowerWord.contains('makro')) {
      return {'icon': Icons.analytics, 'color': Colors.purple};
    } else if (lowerWord.contains('öneri') || lowerWord.contains('tavsiye') ||
               lowerWord.contains('öner')) {
      return {'icon': Icons.lightbulb, 'color': Colors.amber};
    } else if (lowerWord.contains('tansiyon') || lowerWord.contains('sodyum') ||
               lowerWord.contains('potasyum')) {
      return {'icon': Icons.favorite, 'color': Colors.red};
    } else if (lowerWord.contains('kemik') || lowerWord.contains('kalsiyum')) {
      return {'icon': Icons.health_and_safety, 'color': Colors.green};
    }
    return null;
  }

  // AI mesajına uygun ikon ekle ve içerikte de ikonlar göster
  Widget _buildAIMessage(String text) {
    // Mesaj başlığı için ikon belirle
    IconData headerIcon;
    Color headerIconColor;

    final lowerText = text.toLowerCase();

    if (lowerText.contains('yemek') || lowerText.contains('tarif') || 
        lowerText.contains('beslenme') || lowerText.contains('öğün') || 
        lowerText.contains('kalori')) {
      headerIcon = Icons.restaurant_menu;
      headerIconColor = _mintColor;
    } else if (lowerText.contains('su') || lowerText.contains('su iç')) {
      headerIcon = Icons.water_drop;
      headerIconColor = Colors.blue;
    } else if (lowerText.contains('spor') || lowerText.contains('egzersiz') ||
               lowerText.contains('antrenman') || lowerText.contains('fitness')) {
      headerIcon = Icons.fitness_center;
      headerIconColor = Colors.orange;
    } else if (lowerText.contains('sağlık') || lowerText.contains('sağlıklı') ||
               lowerText.contains('vitamin') || lowerText.contains('mineral')) {
      headerIcon = Icons.favorite;
      headerIconColor = Colors.red;
    } else if (lowerText.contains('uyku') || lowerText.contains('dinlenme')) {
      headerIcon = Icons.bedtime;
      headerIconColor = Colors.indigo;
    } else if (lowerText.contains('protein') || lowerText.contains('karbonhidrat') ||
               lowerText.contains('yağ') || lowerText.contains('makro')) {
      headerIcon = Icons.analytics;
      headerIconColor = Colors.purple;
    } else if (lowerText.contains('öneri') || lowerText.contains('tavsiye') ||
               lowerText.contains('öner')) {
      headerIcon = Icons.lightbulb;
      headerIconColor = Colors.amber;
    } else {
      headerIcon = Icons.psychology;
      headerIconColor = _mintColor;
    }

    // Mesaj içeriğini parse et ve ikonlar ekle
    final textSpans = _parseTextWithIcons(text);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: headerIconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            headerIcon,
            size: 18,
            color: headerIconColor,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
              children: textSpans,
            ),
          ),
        ),
      ],
    );
  }

  // Metni parse edip sadece önemli yerlerde ikonlar ekle (çok az ikon)
  List<InlineSpan> _parseTextWithIcons(String text) {
    final spans = <InlineSpan>[];
    
    // Sadece çok önemli kelimeler için ikon ekle (çok az ikon olacak şekilde)
    // Sadece anahtar kelimeler: kahvaltı/öğle/akşam, kemik sağlığı, tansiyon, süt alerjisi
    final importantPatterns = [
      RegExp(r'\b(kahvaltı|öğle yemeği|akşam yemeği)\b', caseSensitive: false),
      RegExp(r'\b(kemik sağlığı)\b', caseSensitive: false),
      RegExp(r'\b(tansiyon)\b', caseSensitive: false),
      RegExp(r'\b(süt alerjisi)\b', caseSensitive: false),
    ];
    
    int lastIndex = 0;
    final matches = <Match>[];
    
    // Tüm önemli eşleşmeleri bul
    for (var pattern in importantPatterns) {
      final patternMatches = pattern.allMatches(text);
      matches.addAll(patternMatches);
    }
    
    // Eşleşmeleri pozisyona göre sırala
    matches.sort((a, b) => a.start.compareTo(b.start));
    
    // Her eşleşme için sadece bir kez ikon ekle
    final addedPositions = <int>{};
    
    for (var match in matches) {
      // Aynı pozisyona birden fazla ikon ekleme
      if (addedPositions.contains(match.start)) continue;
      
      // Önceki metni ekle
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      
      // İkon ekle (sadece önemli kelimeler için)
      final matchedText = match.group(0) ?? '';
      final iconData = _getIconForWord(matchedText);
      
      if (iconData != null) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              iconData['icon'] as IconData,
              size: 16,
              color: iconData['color'] as Color,
            ),
          ),
        ));
        addedPositions.add(match.start);
      }
      
      // Eşleşen metni ekle
      spans.add(TextSpan(text: matchedText));
      lastIndex = match.end;
    }
    
    // Kalan metni ekle
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }
    
    // Eğer hiç eşleşme yoksa, sadece metni döndür
    if (spans.isEmpty) {
      return [TextSpan(text: text)];
    }
    
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Sohbeti Sil butonu
          if (_messages.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Sohbeti Sil',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: Text(
                            'Tüm sohbet geçmişini silmek istediğinize emin misiniz?',
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'İptal',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: Text(
                                'Sil',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await deleteAllMessages();
                      }
                    },
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 20),
                    label: Text(
                      'Sohbeti Sil',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loadingMessages
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_lastRecipeResponse != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _messages.length) {
                        final msg = _messages[index];
                        final isUser = msg["role"] == "user";

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser ? _mintColor : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isUser
                                ? Text(
                                    msg["text"] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white,
                                      height: 1.5,
                                    ),
                                  )
                                : _buildAIMessage(msg["text"] ?? ''),
                          ),
                        );
                      } else {
                        // Kaydet butonu
                        return Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _mintColor, width: 2),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Bu tarifi kaydetmek ister misin?',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_lastRecipeResponse != null && _lastRecipeResponse!.isNotEmpty) {
                                      final success = await saveRecipe(
                                        'AI Tarif Önerisi',
                                        _lastRecipeResponse!,
                                        '', // Hazırlama adımları boş bırakılıyor
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(success 
                                              ? 'Tarif kaydedildi!' 
                                              : 'Tarif kaydedilemedi. Lütfen tekrar deneyin.'),
                                            backgroundColor: success ? _mintColor : Colors.red,
                                          ),
                                        );
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Kaydedilecek tarif bulunamadı.'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _mintColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Kaydet',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Örn: Kahvaltı öner',
                      filled: true,
                      fillColor: _softGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _mintColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _loading ? null : _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
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
