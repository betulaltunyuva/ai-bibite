import 'dart:convert';
import 'package:http/http.dart' as http;

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
        
        // 503 hatası için özel mesaj
        if (response.statusCode == 503) {
          return "Model şu anda aşırı yüklü. Lütfen birkaç saniye sonra tekrar deneyin.";
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
      return "Hata oluştu: $e";
    }
  }
}
