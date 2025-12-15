import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ChatService chatService = ChatService();
  final Color _mintColor = const Color(0xFF2E7D32);
  final Color _softGrey = const Color(0xFFF2F2F2);

  List<Map<String, String>> messages = [];

  void sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    messages.add({"role": "user", "text": text});
    controller.clear();
    setState(() {});

    final reply = await chatService.sendMessage(text);

    messages.add({"role": "ai", "text": reply});
    setState(() {});
  }

  // Mesaj içeriğinde ikonlar için kelime-ikon eşleştirmesi
  Map<String, dynamic>? _getIconForWord(String word) {
    final lowerWord = word.toLowerCase();
    
    if (lowerWord.contains('yemek') || lowerWord.contains('tarif') || 
        lowerWord.contains('beslenme') || lowerWord.contains('öğün') || 
        lowerWord.contains('kalori') || lowerWord.contains('yemek') ||
        lowerWord.contains('somon') || lowerWord.contains('brokoli') ||
        lowerWord.contains('kinoa') || lowerWord.contains('malzeme')) {
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
                color: AppColors.getPrimaryText(context),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.getCardBackground(context),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'lib/assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.restaurant_menu,
                  color: AppColors.primaryGreen,
                  size: 24,
                );
              },
            ),
          ),
        ),
        title: Text(
          "AI BiBite",
          style: GoogleFonts.poppins(
            color: AppColors.getPrimaryText(context),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["role"] == "user";
                final text = msg["text"] ?? "";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primaryGreen : AppColors.getCardBackground(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isUser
                        ? Text(
                            text,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          )
                        : _buildAIMessage(text),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Bir şey yaz...",
                      hintStyle: GoogleFonts.poppins(color: AppColors.getSecondaryText(context)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.getCardBackground(context)
                          : AppColors.getCardBackground(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.getPrimaryText(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

