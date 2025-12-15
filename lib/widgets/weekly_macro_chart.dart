import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Haftalık makro besin tüketimini gösteren bar chart widget'ı
/// Protein, Karbonhidrat ve Yağ değerlerini gösterir
class WeeklyMacroChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData; // Her gün için {date: DateTime, protein: double, carbohydrate: double, fat: double}

  const WeeklyMacroChart({
    super.key,
    required this.weeklyData,
  });

  /// Güvenli tarih formatlama - locale initialize edilmemişse fallback kullan
  String _formatDate(DateTime date, {bool short = false}) {
    try {
      if (short) {
        return DateFormat('dd MMM', 'tr_TR').format(date);
      }
      return DateFormat('dd\nMMM', 'tr_TR').format(date);
    } catch (e) {
      // Fallback to numeric format if locale not initialized
      if (short) {
        return DateFormat('dd/MM').format(date);
      }
      return DateFormat('dd\nMM').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer veri yoksa boş grafik göster
    if (weeklyData.isEmpty) {
      return _buildEmptyChart();
    }

    // En yüksek makro değerini bul (grafik yüksekliği için)
    double maxMacro = 0;
    for (var data in weeklyData) {
      final protein = (data['protein'] as num?)?.toDouble() ?? 0;
      final carbohydrate = (data['carbohydrate'] as num?)?.toDouble() ?? 0;
      final fat = (data['fat'] as num?)?.toDouble() ?? 0;
      final total = protein + carbohydrate + fat;
      if (total > maxMacro) maxMacro = total;
    }
    
    final maxValue = (maxMacro * 1.2); // %20 padding ekle

    // Renkler
    const proteinColor = Color(0xFFFFB3BA); // Açık pembe
    const carbColor = Color(0xFFFFD93D); // Sarı
    const fatColor = Color(0xFFB3E5FC); // Açık mavi

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Haftalık Makro Besinler',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Grafik
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.grey.shade800,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = weeklyData[groupIndex]['date'] as DateTime;
                      final protein = (weeklyData[groupIndex]['protein'] as num?)?.toDouble() ?? 0;
                      final carbohydrate = (weeklyData[groupIndex]['carbohydrate'] as num?)?.toDouble() ?? 0;
                      final fat = (weeklyData[groupIndex]['fat'] as num?)?.toDouble() ?? 0;
                      
                      return BarTooltipItem(
                        '${_formatDate(date, short: true)}\n\n'
                        'Protein: ${protein.toStringAsFixed(1)}g\n'
                        'Karbonhidrat: ${carbohydrate.toStringAsFixed(1)}g\n'
                        'Yağ: ${fat.toStringAsFixed(1)}g',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < weeklyData.length) {
                          final date = weeklyData[index]['date'] as DateTime;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _formatDate(date),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 50,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value % 50 == 0 || value == maxValue) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: weeklyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final protein = (data['protein'] as num?)?.toDouble() ?? 0;
                  final carbohydrate = (data['carbohydrate'] as num?)?.toDouble() ?? 0;
                  final fat = (data['fat'] as num?)?.toDouble() ?? 0;

                  // Stacked bar chart için
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      // Protein (alt)
                      BarChartRodData(
                        toY: protein,
                        color: proteinColor,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.zero,
                          bottom: Radius.zero,
                        ),
                      ),
                      // Karbonhidrat (orta)
                      BarChartRodData(
                        fromY: protein,
                        toY: protein + carbohydrate,
                        color: carbColor,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.zero,
                          bottom: Radius.zero,
                        ),
                      ),
                      // Yağ (üst)
                      BarChartRodData(
                        fromY: protein + carbohydrate,
                        toY: protein + carbohydrate + fat,
                        color: fatColor,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                          bottom: Radius.zero,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend (Açıklama)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Protein', proteinColor),
              const SizedBox(width: 16),
              _buildLegendItem('Karbonhidrat', carbColor),
              const SizedBox(width: 16),
              _buildLegendItem('Yağ', fatColor),
            ],
          ),
        ],
      ),
    );
  }

  /// Legend item widget'ı
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Veri yoksa gösterilecek boş grafik
  Widget _buildEmptyChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Haftalık Makro Besinler',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz veri yok',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yemek kaydettikçe grafik burada görünecek',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

