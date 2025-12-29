import 'dart:convert';
import 'package:http/http.dart' as http;

class NutritionixService {
  // Nutritionix API için appId ve appKey gerekli
  // Ücretsiz hesap için: https://developer.nutritionix.com/
  final String appId = "YOUR_NUTRITIONIX_APP_ID";
  final String appKey = "YOUR_NUTRITIONIX_APP_KEY";

  Future<Map<String, dynamic>> getProductInfo(String barcode) async {
    try {
      if (appId == "YOUR_NUTRITIONIX_APP_ID" || appKey == "YOUR_NUTRITIONIX_APP_KEY") {
        throw Exception("Nutritionix API anahtarları ayarlanmamış");
      }

      final url = Uri.parse("https://trackapi.nutritionix.com/v2/search/item?upc=$barcode");

      final response = await http.get(
        url,
        headers: {
          "x-app-id": appId,
          "x-app-key": appKey,
        },
      );

      if (response.statusCode != 200) {
        throw Exception("API Hatası: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      
      if (data["foods"] == null || data["foods"].isEmpty) {
        throw Exception("Ürün bulunamadı");
      }

      final food = data["foods"][0];

      return {
        "name": food["food_name"] ?? "Bilinmeyen ürün",
        "calories": (food["nf_calories"] ?? 0).toInt(),
        "protein": (food["nf_protein"] ?? 0).toInt(),
        "carbs": (food["nf_total_carbohydrate"] ?? 0).toInt(),
        "fat": (food["nf_total_fat"] ?? 0).toInt(),
        "ingredients": food["nf_ingredient_statement"]?.toString().split(',') ?? [],
      };
    } catch (e) {
      throw Exception("Barkod okuma hatası: $e");
    }
  }
}


