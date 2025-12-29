import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_vision_service.dart';
import 'food_analysis_screen.dart';

class ManualFoodEntryScreen extends StatefulWidget {
  const ManualFoodEntryScreen({super.key});

  @override
  State<ManualFoodEntryScreen> createState() => _ManualFoodEntryScreenState();
}

class _ManualFoodEntryScreenState extends State<ManualFoodEntryScreen> {
  final TextEditingController _foodController = TextEditingController();
  final GeminiVisionService _geminiService = GeminiVisionService();
  bool _loading = false;
  final Color _mintColor = const Color(0xFF2E7D32);
  final Color _softGrey = const Color(0xFFF2F2F2);

  Future<void> _analyzeFood() async {
    final text = _foodController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen yemek adını girin')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _geminiService.analyzeFoodTextDetailed(text);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodAnalysisScreen(
              foodData: result,
              source: 'manual',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _foodController.dispose();
    super.dispose();
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
          'Manuel Yemek Ekle',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yemek Adı',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _foodController,
              decoration: InputDecoration(
                hintText: 'Örn: 100 gram tavuklu pilav',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF9E9E9E)),
                filled: true,
                fillColor: _softGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _mintColor, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _analyzeFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mintColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Analiz Et',
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

