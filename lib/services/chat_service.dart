import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class ChatService {
  final String apiKey = "AIzaSyAfmPRo8i4KMMyf7OTlma4PMuM8V4pK8Nk";

  Future<String> sendMessage(String userMessage) async {
    try {
      // API key kontrolü
      if (apiKey == "YOUR_API_KEY" || apiKey.isEmpty) {
        return "Hata: API anahtarı ayarlanmamış. Lütfen chat_service.dart dosyasında apiKey değişkenine gerçek API anahtarınızı ekleyin.";
      }

      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": userMessage}
              ]
            }
          ]
        }),
      );

      final data = jsonDecode(response.body);

      // Hata kontrolü
      if (response.statusCode != 200) {
        final errorMessage = data["error"]?["message"] ?? "Bilinmeyen hata";
        final errorMessageLower = errorMessage.toLowerCase();
        
        // 503 veya "overloaded" içeren hatalar için özel mesaj
        if (response.statusCode == 503 || errorMessageLower.contains("overloaded")) {
          // Teknik hata detaylarını sadece console'a logla
          developer.log(
            "Chat API Error - Status: ${response.statusCode}, Message: $errorMessage",
            name: "ChatService",
            error: data,
          );
          
          // Kullanıcıya dostça mesaj göster
          return "Şu anda biraz yoğunum 😅\nYemek önerini hazırlamak için kısa bir mola verdim.\n1–2 dakika sonra tekrar dener misin?";
        }
        
        // Rate limit hatası
        if (response.statusCode == 429) {
          return "Çok fazla istek gönderildi. Lütfen birkaç dakika sonra tekrar deneyin.";
        }
        
        return "API Hatası (${response.statusCode}): $errorMessage";
      }

      // Yanıt kontrolü
      if (data["candidates"] == null || data["candidates"].isEmpty) {
        return "Hata: API'den yanıt alınamadı. Yanıt: ${response.body}";
      }

      return data["candidates"][0]["content"]["parts"][0]["text"];
    } catch (e) {
      // Teknik hata detaylarını sadece console'a logla
      developer.log(
        "Chat API Exception",
        name: "ChatService",
        error: e,
      );
      
      // Eğer hata mesajında "overloaded" geçiyorsa özel mesaj göster
      final errorString = e.toString().toLowerCase();
      if (errorString.contains("overloaded") || errorString.contains("503")) {
        return "Şu anda biraz yoğunum 😅\nYemek önerini hazırlamak için kısa bir mola verdim.\n1–2 dakika sonra tekrar dener misin?";
      }
      
      return "Hata oluştu: $e";
    }
  }
}
