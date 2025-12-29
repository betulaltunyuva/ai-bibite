import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DiaryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> diaryData;

  const DiaryDetailScreen({
    super.key,
    required this.diaryData,
  });

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  final Color _mintColor = const Color(0xFF2E7D32);

  Future<void> deleteDiaryEntry() async {
    try {
      final diaryId = widget.diaryData['id'];

      await Supabase.instance.client
          .from('diary')
          .delete()
          .eq('id', diaryId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt silindi')),
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
    final foodName = widget.diaryData['food_name']?.toString() ?? 'Bilinmeyen';
    final calories = (widget.diaryData['calories'] as num?)?.toInt() ?? 0;
    final protein = widget.diaryData['protein'] != null
        ? (widget.diaryData['protein'] as num?)?.toDouble()
        : null;
    final carbs = widget.diaryData['carbs'] != null
        ? (widget.diaryData['carbs'] as num?)?.toDouble()
        : null;
    final fat = widget.diaryData['fat'] != null
        ? (widget.diaryData['fat'] as num?)?.toDouble()
        : null;
    final allergens = widget.diaryData['allergens'];
    final summary = widget.diaryData['summary']?.toString() ?? '';
    final createdAt = widget.diaryData['created_at']?.toString();

    String formattedDate = 'Tarih bilgisi yok';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(date);
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
          'Yemek Detayı',
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
            // Yemek Adı
            Text(
              foodName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Tarih
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Kalori
            _buildInfoCard(
              icon: Icons.local_fire_department,
              iconColor: Colors.orange,
              title: 'Kalori',
              value: '$calories kcal',
            ),
            const SizedBox(height: 16),

            // Protein (varsa)
            if (protein != null)
              _buildInfoCard(
                icon: Icons.fitness_center,
                iconColor: Colors.pink,
                title: 'Protein',
                value: '${protein.toStringAsFixed(1)} g',
              ),
            if (protein != null) const SizedBox(height: 16),

            // Karbonhidrat (varsa)
            if (carbs != null)
              _buildInfoCard(
                icon: Icons.energy_savings_leaf,
                iconColor: Colors.orange,
                title: 'Karbonhidrat',
                value: '${carbs.toStringAsFixed(1)} g',
              ),
            if (carbs != null) const SizedBox(height: 16),

            // Yağ (varsa)
            if (fat != null)
              _buildInfoCard(
                icon: Icons.water_drop,
                iconColor: Colors.blue,
                title: 'Yağ',
                value: '${fat.toStringAsFixed(1)} g',
              ),
            if (fat != null) const SizedBox(height: 16),

            // Alerjenler (varsa)
            if (allergens != null && allergens is List && allergens.isNotEmpty)
              _buildAllergensCard(allergens),
            if (allergens != null && allergens is List && allergens.isNotEmpty)
              const SizedBox(height: 16),

            // AI Özet Yorumu
            if (summary.isNotEmpty) _buildSummaryCard(summary),
            if (summary.isNotEmpty) const SizedBox(height: 24),

            // Silme Butonu
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: deleteDiaryEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Bu Kaydı Sil',
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

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergensCard(List allergens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Alerjenler',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergens.map((allergen) {
              final allergenStr = allergen.toString();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  allergenStr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Özet Yorumu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

