import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeService {
  final String apiKey = "AIzaSyAfmPRo8i4KMMyf7OTlma4PMuM8V4pK8Nk";

  Future<String> getRecipeRecommendation({
    required String userMessage,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      // Profil bilgilerinden özet oluştur
      final profileSummary = _buildProfileSummary(profileData);
      
      // Kullanıcı mesajına profil bilgilerini ekle
      final enhancedMessage = '''
$profileSummary

Kullanıcı isteği: $userMessage

Lütfen kullanıcının profil bilgilerine uygun, detaylı bir tarif öner. Tarif şunları içermeli:
- Malzemeler listesi
- Hazırlama adımları
- Porsiyon bilgisi
- Besin değerleri (kalori, protein, karbonhidrat, yağ)
- Hazırlama süresi

Türkçe olarak yanıt ver.
''';

      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": enhancedMessage}
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        final errorMessage = data["error"]?["message"] ?? "Bilinmeyen hata";
        return "API Hatası (${response.statusCode}): $errorMessage";
      }

      final data = jsonDecode(response.body);

      if (data["candidates"] == null || data["candidates"].isEmpty) {
        return "Hata: API'den yanıt alınamadı.";
      }

      return data["candidates"][0]["content"]["parts"][0]["text"];
    } catch (e) {
      return "Hata oluştu: $e";
    }
  }

  String _buildProfileSummary(Map<String, dynamic> profileData) {
    final buffer = StringBuffer();
    buffer.writeln("Kullanıcı Profil Bilgileri:");
    
    if (profileData['gender'] != null) {
      buffer.writeln("- Cinsiyet: ${profileData['gender']}");
    }
    if (profileData['age'] != null) {
      buffer.writeln("- Yaş: ${profileData['age']}");
    }
    if (profileData['height'] != null) {
      buffer.writeln("- Boy: ${profileData['height']} cm");
    }
    if (profileData['weight'] != null) {
      buffer.writeln("- Kilo: ${profileData['weight']} kg");
    }
    if (profileData['goal'] != null) {
      buffer.writeln("- Hedef: ${profileData['goal']}");
    }
    if (profileData['activity_level'] != null) {
      buffer.writeln("- Aktivite Düzeyi: ${profileData['activity_level']}");
    }
    if (profileData['allergies'] != null && profileData['allergies'].toString().isNotEmpty) {
      buffer.writeln("- Alerjiler: ${profileData['allergies']}");
    }
    if (profileData['diseases'] != null && profileData['diseases'].toString().isNotEmpty) {
      buffer.writeln("- Hastalıklar: ${profileData['diseases']}");
    }
    if (profileData['diet_type'] != null) {
      buffer.writeln("- Diyet Tipi: ${profileData['diet_type']}");
    }
    
    return buffer.toString();
  }
}


