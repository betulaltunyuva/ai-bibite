import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'Türkçe';

  final List<Map<String, String>> _languages = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getCardBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dil Seçimi',
          style: GoogleFonts.poppins(
            color: AppColors.getPrimaryText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.getCardBackground(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [AppColors.softShadow],
          ),
          child: Column(
            children: _languages.map((language) {
              final isSelected = _selectedLanguage == language['name'];
              return Column(
                children: [
                  ListTile(
                    leading: Text(
                      language['flag']!,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      language['name']!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getPrimaryText(context),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: AppColors.primaryGreen)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLanguage = language['name']!;
                      });
                      Navigator.pop(context, language['name']);
                    },
                  ),
                  if (language != _languages.last)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: AppColors.getBorderDivider(context),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

