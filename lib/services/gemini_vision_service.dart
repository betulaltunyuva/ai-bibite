import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class GeminiVisionService {
  final String apiKey = "AIzaSyAfmPRo8i4KMMyf7OTlma4PMuM8V4pK8Nk";

  Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    try {
      // Resmi base64'e çevir
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imageFile.path);

      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "Bu yemeğin detaylı besin analizini yap. Şu bilgileri JSON formatında döndür: {\"name\": \"yemek adı\", \"calories\": sayı, \"protein\": sayı, \"carbs\": sayı, \"fat\": sayı, \"ingredients\": [\"malzeme1\", \"malzeme2\"]}. Sadece JSON döndür, başka açıklama yapma."
                },
                {
                  "inline_data": {
                    "mime_type": mimeType,
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("API Hatası: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";

      // JSON'u parse et
      try {
        // JSON'u temizle (markdown code block varsa kaldır)
        String cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      } catch (e) {
        // JSON parse edilemezse text'ten bilgileri çıkar
        return _parseTextResponse(text);
      }
    } catch (e) {
      throw Exception("Görüntü analizi hatası: $e");
    }
  }

  Future<Map<String, dynamic>> analyzeFoodText(String foodText) async {
    try {
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey");

      final prompt = "$foodText besin değeri nedir? Şu bilgileri JSON formatında döndür: {\"name\": \"yemek adı\", \"calories\": sayı, \"protein\": sayı, \"carbs\": sayı, \"fat\": sayı, \"ingredients\": [\"malzeme1\", \"malzeme2\"]}. Sadece JSON döndür, başka açıklama yapma.";

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("API Hatası: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";

      try {
        String cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      } catch (e) {
        return _parseTextResponse(text);
      }
    } catch (e) {
      throw Exception("Metin analizi hatası: $e");
    }
  }

  String _getMimeType(String path) {
    final ext = extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Detaylı besin analizi (tüm özelliklerle)
  Future<Map<String, dynamic>> analyzeFoodImageDetailed(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imageFile.path);

      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey");

      final detailedPrompt = """
Bu fotoğraftaki yemeğin detaylı besin analizini yap. Aşağıdaki JSON formatını kullanarak tüm bilgileri döndür. Sadece JSON döndür, başka açıklama yapma.

{
  "name": "yemek adı",
  "confidence": 0.0-1.0 arası güven skoru,
  "alternatives": ["alternatif yemek adı 1", "alternatif yemek adı 2"],
  "calories": sayı,
  "protein": sayı (gram),
  "carbs": sayı (gram),
  "fat": sayı (gram),
  "fiber": sayı (gram),
  "sugar": sayı (gram),
  "portion": "1 porsiyon" veya "2 porsiyon" veya "büyük dilim" gibi,
  "portion_multiplier": 1.0 (porsiyon çarpanı),
  "main_ingredients": ["ana malzeme 1", "ana malzeme 2"],
  "topping_ingredients": ["üst malzeme 1", "üst malzeme 2"],
  "allergens": ["fındık", "süt", "gluten", "şeker"] veya [],
  "health_score": 0-100 arası sağlık skoru,
  "healthier_alternative": "Daha sağlıklı alternatif önerisi",
  "ai_summary": "2-3 cümlelik AI özet yorumu"
}
""";

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": detailedPrompt},
                {
                  "inline_data": {
                    "mime_type": mimeType,
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("API Hatası: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";

      try {
        String cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final result = jsonDecode(cleanJson) as Map<String, dynamic>;
        
        // Varsayılan değerleri ekle
        return _enrichAnalysisData(result);
      } catch (e) {
        return _parseTextResponse(text);
      }
    } catch (e) {
      throw Exception("Detaylı görüntü analizi hatası: $e");
    }
  }

  /// Metin tabanlı detaylı analiz
  Future<Map<String, dynamic>> analyzeFoodTextDetailed(String foodText) async {
    try {
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey");

      final detailedPrompt = """
"$foodText" besin değeri nedir? Aşağıdaki JSON formatını kullanarak tüm bilgileri döndür. Sadece JSON döndür, başka açıklama yapma.

{
  "name": "yemek adı",
  "confidence": 0.0-1.0 arası güven skoru,
  "alternatives": ["alternatif yemek adı 1", "alternatif yemek adı 2"],
  "calories": sayı,
  "protein": sayı (gram),
  "carbs": sayı (gram),
  "fat": sayı (gram),
  "fiber": sayı (gram),
  "sugar": sayı (gram),
  "portion": "1 porsiyon" veya "2 porsiyon" veya "büyük dilim" gibi,
  "portion_multiplier": 1.0 (porsiyon çarpanı),
  "main_ingredients": ["ana malzeme 1", "ana malzeme 2"],
  "topping_ingredients": ["üst malzeme 1", "üst malzeme 2"],
  "allergens": ["fındık", "süt", "gluten", "şeker"] veya [],
  "health_score": 0-100 arası sağlık skoru,
  "healthier_alternative": "Daha sağlıklı alternatif önerisi",
  "ai_summary": "2-3 cümlelik AI özet yorumu"
}
""";

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": detailedPrompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("API Hatası: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";

      try {
        String cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final result = jsonDecode(cleanJson) as Map<String, dynamic>;
        return _enrichAnalysisData(result);
      } catch (e) {
        return _parseTextResponse(text);
      }
    } catch (e) {
      throw Exception("Detaylı metin analizi hatası: $e");
    }
  }

  /// Analiz verilerini zenginleştir (varsayılan değerler ekle)
  Map<String, dynamic> _enrichAnalysisData(Map<String, dynamic> data) {
    // Porsiyon çarpanını hesapla
    double portionMultiplier = 1.0;
    if (data['portion_multiplier'] != null) {
      portionMultiplier = (data['portion_multiplier'] as num).toDouble();
    } else if (data['portion'] != null) {
      final portion = data['portion'].toString().toLowerCase();
      if (portion.contains('2') || portion.contains('iki')) {
        portionMultiplier = 2.0;
      } else if (portion.contains('yarım') || portion.contains('0.5')) {
        portionMultiplier = 0.5;
      }
    }

    // Porsiyon çarpanına göre değerleri güncelle
    final multiplier = portionMultiplier;
    final calories = ((data['calories'] ?? 0) as num).toDouble() * multiplier;
    final protein = ((data['protein'] ?? 0) as num).toDouble() * multiplier;
    final carbs = ((data['carbs'] ?? 0) as num).toDouble() * multiplier;
    final fat = ((data['fat'] ?? 0) as num).toDouble() * multiplier;
    final fiber = ((data['fiber'] ?? 0) as num).toDouble() * multiplier;
    final sugar = ((data['sugar'] ?? 0) as num).toDouble() * multiplier;

    return {
      "name": data['name'] ?? "Bilinmeyen Yemek",
      "confidence": (data['confidence'] ?? 0.8) as num,
      "alternatives": data['alternatives'] ?? [],
      "calories": calories.toInt(),
      "protein": protein.toInt(),
      "carbs": carbs.toInt(),
      "fat": fat.toInt(),
      "fiber": (fiber).toInt(),
      "sugar": (sugar).toInt(),
      "portion": data['portion'] ?? "1 porsiyon",
      "portion_multiplier": portionMultiplier,
      "main_ingredients": data['main_ingredients'] ?? [],
      "topping_ingredients": data['topping_ingredients'] ?? [],
      "allergens": data['allergens'] ?? [],
      "health_score": (data['health_score'] ?? 50) as num,
      "healthier_alternative": data['healthier_alternative'] ?? "",
      "ai_summary": data['ai_summary'] ?? "",
      // Eski format uyumluluğu için
      "ingredients": [
        ...(data['main_ingredients'] ?? []),
        ...(data['topping_ingredients'] ?? [])
      ],
    };
  }

  Map<String, dynamic> _parseTextResponse(String text) {
    // Fallback: Text'ten bilgileri çıkarmaya çalış
    return {
      "name": "Analiz edilen yemek",
      "confidence": 0.5,
      "alternatives": [],
      "calories": 0,
      "protein": 0,
      "carbs": 0,
      "fat": 0,
      "fiber": 0,
      "sugar": 0,
      "portion": "1 porsiyon",
      "portion_multiplier": 1.0,
      "main_ingredients": [],
      "topping_ingredients": [],
      "allergens": [],
      "health_score": 50,
      "healthier_alternative": "",
      "ai_summary": "",
      "ingredients": [],
      "raw_response": text,
    };
  }
}

