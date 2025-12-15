import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Haftalık kalori tüketimini gösteren bar chart widget'ı
class WeeklyCalorieChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData; // Her gün için {date: DateTime, calories: int}
  final int? targetCalories; // Günlük hedef kalori (opsiyonel)

  const WeeklyCalorieChart({
    super.key,
    required this.weeklyData,
    this.targetCalories,
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

    // En yüksek kalori değerini bul (grafik yüksekliği için)
    final maxCalories = weeklyData
        .map((d) => (d['calories'] as num?)?.toInt() ?? 0)
        .reduce((a, b) => a > b ? a : b);
    
    // Target kalori varsa onu da dikkate al
    final maxValue = targetCalories != null && targetCalories! > maxCalories
        ? targetCalories!.toDouble()
        : (maxCalories * 1.2).toDouble(); // %20 padding ekle

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
                  Icons.local_fire_department,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Haftalık Kalori Tüketimi',
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
                    getTooltipColor: (group) => const Color(0xFF2E7D32),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = weeklyData[groupIndex]['date'] as DateTime;
                      final calories = (weeklyData[groupIndex]['calories'] as num?)?.toInt() ?? 0;
                      return BarTooltipItem(
                        '${_formatDate(date, short: true)}\n$calories kcal',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
                        if (value % 500 == 0 || value == maxValue) {
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
                  horizontalInterval: 500,
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
                  final calories = (data['calories'] as num?)?.toInt() ?? 0;
                  final isTargetReached = targetCalories != null && calories >= targetCalories!;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: calories.toDouble(),
                        color: isTargetReached
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF2E7D32).withOpacity(0.6),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          // Hedef çizgisi (eğer target varsa)
          if (targetCalories != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 2,
                  color: Colors.orange.shade300,
                ),
                const SizedBox(width: 8),
                Text(
                  'Günlük Hedef: $targetCalories kcal',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
                  Icons.local_fire_department,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Haftalık Kalori Tüketimi',
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

