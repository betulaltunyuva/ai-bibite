import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import 'recommendations_tab.dart';
import 'chat_tab.dart';
import 'analysis_tab.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _mintColor = const Color(0xFF2E7D32);
  
  // Widget'ları sabit tutmak için - state korunması için
  late final List<Widget> _tabViews;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Widget'ları bir kez oluştur ve sabit tut - state korunması için
    _tabViews = [
      const RecommendationsTab(),
      const ChatTab(key: ValueKey('chat_tab')), // Key ile state korunması
      const AnalysisTab(),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          'Öneriler',
          style: GoogleFonts.poppins(
            color: AppColors.getPrimaryText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.getSecondaryText(context),
          indicatorColor: AppColors.primaryGreen,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Öneriler'),
            Tab(text: 'Sohbet'),
            Tab(text: 'Analiz'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Swipe'ı devre dışı bırak, sadece tab ile geçiş
        children: _tabViews, // Sabit widget listesi - state korunması için
      ),
    );
  }
}

