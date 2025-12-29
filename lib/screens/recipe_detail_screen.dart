import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final Color _mintColor = const Color(0xFF2E7D32);

  Future<void> deleteRecipe() async {
    try {
      final recipeId = widget.recipe['id'];

      await Supabase.instance.client
          .from('saved_recipes')
          .delete()
          .eq('id', recipeId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif silindi')),
      );

      // Liste ekranına "true" sonucu ile geri dön
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silinirken bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.recipe['title']?.toString() ?? 'Tarif';
    final ingredients = widget.recipe['ingredients']?.toString() ?? '';
    final instructions = widget.recipe['instructions']?.toString() ?? '';
    final nutritionalValue = widget.recipe['nutritional_value']?.toString() ?? 
                            widget.recipe['nutrition']?.toString() ?? '';
    final recommendations = widget.recipe['recommendations']?.toString() ?? 
                           widget.recipe['advice']?.toString() ?? '';
    final createdAt = widget.recipe['created_at']?.toString();

    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = DateFormat('dd MMMM yyyy HH:mm', 'tr_TR').format(date);
      } catch (e) {
        formattedDate = createdAt;
      }
    }

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
          'Tarif Detayı',
          style: GoogleFonts.poppins(
            color: Colors.black87,
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
                color: _mintColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.menu_book, color: _mintColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
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
                        if (formattedDate.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Malzemeler
            if (ingredients.isNotEmpty) ...[
              Text(
                'Malzemeler',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  ingredients,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Hazırlama Adımları
            if (instructions.isNotEmpty) ...[
              Text(
                'Hazırlama Adımları',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  instructions,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Besin Değeri
            if (nutritionalValue.isNotEmpty) ...[
              Text(
                'Besin Değeri',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  nutritionalValue,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Tavsiyeler
            if (recommendations.isNotEmpty) ...[
              Text(
                'Tavsiyeler',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _mintColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _mintColor.withOpacity(0.3)),
                ),
                child: Text(
                  recommendations,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Eğer hiçbir içerik yoksa
            if (ingredients.isEmpty && instructions.isEmpty && 
                nutritionalValue.isEmpty && recommendations.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tarif detayları bulunamadı',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu tarif kaydedilirken detay bilgisi eklenmemiş.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Silme Butonu (Her zaman görünür)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: deleteRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Bu Tarifi Sil',
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
    );
  }
}

